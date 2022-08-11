$input_file = $args[0]

# Get output file path
$directory_name = (Get-item $input_file).DirectoryName
$file_name = (Get-item $input_file).Name
$extesion = [System.IO.Path]::GetExtension("$input_file")
$o_file_name = $file_name -replace $extesion,".sql"
$output_file = $directory_name + "\" + $o_file_name

$table_name = $file_name -replace $extesion,""

[char]$delimiter = "`t"
[string]$line_feed_code = "`r`n"

$header_interval = 10000
$write_interval = 10000


$sql_text = ""

$line_count = 0
Get-Content $input_file -Encoding UTF8 | ForEach-Object{
    $data = $_
    $joined_value = $data -replace ",","\," -replace "'","\'" -replace $delimiter,"','"
    $sql_value = "('" + $joined_value + "')" 
    $sql_value = $sql_value -replace "''","null"

    if($line_count -eq 0){
        $sql_text | Out-File $output_file -Encoding utf8

        $joined_header = $data -replace $delimiter,","
        $sql_header = "INSERT INTO @table_name (@header) VALUES"
        $sql_header = $sql_header -replace "@table_name",$table_name -replace "@header", $joined_header
        $sql_text = $sql_header
    }
    ElseIf($line_count -eq 1){
        $sql_text = $sql_text + $line_feed_code + $sql_value
    }ElseIf($header_interval -ne 0 -and ($line_count % $header_interval) -eq 0){
        $sql_text = $sql_text + ";" + $line_feed_code + $sql_header + $line_feed_code + $sql_value
    }Else{
        $sql_text = $sql_text + "," +  $line_feed_code + $sql_value
    }

    $line_count++

    if(($line_count % $write_interval) -eq 0){

        $sql_text | Out-File $output_file -Encoding utf8 -Append -NoClobber
        $sql_text = ""
    }
}

$sql_text = $sql_text + "`n;" | Out-File $output_file -Encoding utf8 -Append -NoClobber
