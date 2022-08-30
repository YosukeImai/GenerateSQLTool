function GenerateSQLFile {
    param (
        $input_file
    )

    # Started to generate SQL
    Write-Output "Started generating SQL:$input_file"
    # Get output file path
    $directory_name = (Get-item $input_file).DirectoryName
    $file_name = (Get-item $input_file).Name
    $extesion = [System.IO.Path]::GetExtension("$input_file")
    $o_file_name = $file_name -replace $extesion,".sql"
    $output_file = $directory_name + "\" + $o_file_name

    $table_name = $file_name -replace $extesion,""

    [char]$delimiter = "`t"
    [string]$line_feed_code = "`n"

    $header_interval = 10000
    $write_interval = 10000


    $sb = New-Object System.Text.StringBuilder

    # Clear file content
    $null | Out-File $output_file -Encoding utf8

    $line_count = 0
    Get-Content $input_file -Encoding UTF8 | ForEach-Object{
        $data = $_
        $joined_value = $data -replace ",","\," -replace "'","{@tab}" -replace $delimiter,"','"
        $sql_value = "('" + $joined_value + "')" 
        $sql_value = $sql_value -replace "''","null" -replace "{@tab}","\'"

        if($line_count -eq 0){
            $joined_header = $data -replace $delimiter,","
            $sql_header = "INSERT INTO @table_name (@header) VALUES"
            $sql_header = $sql_header -replace "@table_name",$table_name -replace "@header", $joined_header
            [void]$sb.Append($sql_header)
        }
        ElseIf($line_count -eq 1){
            [void]$sb.Append($line_feed_code + $sql_value)
        }ElseIf($header_interval -ne 0 -and ($line_count % $header_interval) -eq 0){
            [void]$sb.Append(";" + $line_feed_code + $sql_header + $line_feed_code + $sql_value)
        }Else{
            [void]$sb.Append("," +  $line_feed_code + $sql_value)
        }

        $line_count++

        if(($line_count % $write_interval) -eq 0){

            $sb.ToString() | Out-File $output_file -Encoding utf8 -Append -NoClobber
            $sb.Length = 0
        }
    }

    $sb.Append($line_feed_code + ";").ToString() | Out-File $output_file -Encoding utf8 -Append -NoClobber   

    Write-Output "Finished generating SQL:$input_file"
}

foreach ($arg in $args){
    GenerateSQLFile -input_file $arg
}



