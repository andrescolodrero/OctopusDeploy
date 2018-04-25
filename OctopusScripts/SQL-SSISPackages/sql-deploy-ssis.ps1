<<<<<<< HEAD
<#
 .SYNOPSIS
 Converts boolean values to boolean types

 .DESCRIPTION
 Converts boolean values to boolean types

 .PARAMETER Value
 The value to convert

 .EXAMPLE
 Format-OctopusArgument "true"
#>
Function Format-OctopusArgument {

    Param(
        [string]$Value
    )

    $Value = $Value.Trim()

    # There must be a better way to do this
    Switch -Wildcard ($Value){

        "True" { Return $True }
        "False" { Return $False }
        "`#{*}" { Return $null }
        Default { Return $Value }
    }
}


$Ssis_ServerName = Format-OctopusArgument -Value $OctopusParameters["SSIS_ServerName"]
$Ssis_ParentFolder = Format-OctopusArgument -Value $OctopusParameters["SSIS_ParentFolder"]
$Ssis_FolderName = Format-OctopusArgument -Value $OctopusParameters["SSIS_FolderName"]
$Ssis_ProjectName = Format-OctopusArgument -Value $OctopusParameters["SSIS_ProjectName"]
$Ssis_InstallPath = Format-OctopusArgument -Value $OctopusParameters["Octopus.Action.Package.CustomInstallationDirectory"]


$sqlFiles = dir -Path $Ssis_InstallPath -Filter *.sql
$sqlFiles | ForEach-Object {
    $fileName = $_.Name
    $path = $_.FullName
    $location = $_.DirectoryName
    $serverName = "$Ssis_ServerName"
    $logFile = [System.IO.Path]::GetTempFileName()
    try {
        Invoke-Sqlcmd -ServerInstance $serverName -InputFile $path -OutputSqlErrors $true -ErrorLevel "+10" -AbortOnError -Verbose | Out-File -filePath $logFile
        New-OctopusArtifact -Path $logFile -Name "$filename.output.log"
    }
    finally {
        Remove-Item $logFile -Force -ErrorAction SilentlyContinue
    }
}

$batFiles = dir -Path $Ssis_InstallPath -Filter *.bat
$batFiles | ForEach-Object {
    $filename = $_.Name
    $path = $_.DirectoryName
    
    # . $path
    $logFile = [System.IO.Path]::GetTempFileName()
    try {
        $args = "/c", "$filename"
        $proc = Start-Process "cmd.exe" -ArgumentList  $args  -WorkingDirectory $path -Wait -PassThru -RedirectStandardOutput $logFile
        New-OctopusArtifact -Path $logFile -Name "$filename.output.log"
        $LASTEXITCODE
        $proc.WaitForExit()
    }
    finally {
        Remove-Item $logFile -Force -ErrorAction SilentlyContinue
    }
}
=======
<#
 .SYNOPSIS
 Converts boolean values to boolean types

 .DESCRIPTION
 Converts boolean values to boolean types

 .PARAMETER Value
 The value to convert

 .EXAMPLE
 Format-OctopusArgument "true"
#>
Function Format-OctopusArgument {

    Param(
        [string]$Value
    )

    $Value = $Value.Trim()

    # There must be a better way to do this
    Switch -Wildcard ($Value){

        "True" { Return $True }
        "False" { Return $False }
        "`#{*}" { Return $null }
        Default { Return $Value }
    }
}


$Ssis_ServerName = Format-OctopusArgument -Value $OctopusParameters["SSIS_ServerName"]
$Ssis_ParentFolder = Format-OctopusArgument -Value $OctopusParameters["SSIS_ParentFolder"]
$Ssis_FolderName = Format-OctopusArgument -Value $OctopusParameters["SSIS_FolderName"]
$Ssis_ProjectName = Format-OctopusArgument -Value $OctopusParameters["SSIS_ProjectName"]
$Ssis_InstallPath = Format-OctopusArgument -Value $OctopusParameters["Octopus.Action.Package.CustomInstallationDirectory"]


$sqlFiles = dir -Path $Ssis_InstallPath -Filter *.sql
$sqlFiles | ForEach-Object {
    $fileName = $_.Name
    $path = $_.FullName
    $location = $_.DirectoryName
    $serverName = "$Ssis_ServerName"
    $logFile = [System.IO.Path]::GetTempFileName()
    try {
        Invoke-Sqlcmd -ServerInstance $serverName -InputFile $path -OutputSqlErrors $true -ErrorLevel "+10" -AbortOnError -Verbose | Out-File -filePath $logFile
        New-OctopusArtifact -Path $logFile -Name "$filename.output.log"
    }
    finally {
        Remove-Item $logFile -Force -ErrorAction SilentlyContinue
    }
}

$batFiles = dir -Path $Ssis_InstallPath -Filter *.bat
$batFiles | ForEach-Object {
    $filename = $_.Name
    $path = $_.DirectoryName
    
    # . $path
    $logFile = [System.IO.Path]::GetTempFileName()
    try {
        $args = "/c", "$filename"
        $proc = Start-Process "cmd.exe" -ArgumentList  $args  -WorkingDirectory $path -Wait -PassThru -RedirectStandardOutput $logFile
        New-OctopusArtifact -Path $logFile -Name "$filename.output.log"
        $LASTEXITCODE
        $proc.WaitForExit()
    }
    finally {
        Remove-Item $logFile -Force -ErrorAction SilentlyContinue
    }
}
>>>>>>> 2463245ef90ff9dd95e80280d5e7fced782affb9
