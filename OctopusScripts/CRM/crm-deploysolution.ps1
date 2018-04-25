<<<<<<< HEAD
Function Format-OctopusArgument
{

    Param(
        [string]$Value
    )

    $Value = $Value.Trim()

    # There must be a better way to do this
    Switch -Wildcard ($Value)
    {

        "True"
        { Return $True
        }
        "False"
        { Return $False
        }
        "#{*}"
        { Return $null
        }
        Default
        { Return $Value
        }
    }
}

function Deploy-CRMSolution
{
    Param ($CrmConnectionString, $SolutionFile, $Override, $PublishWorkflows, $SkipProductUpdateDependencies, $OverwriteUnmanagedCustomizations, $AsyncWaitTimeout, $Timeout, $ConvertToManaged )

    $solutionInfo = Get-XrmSolutionInfoFromZip -SolutionFilePath $SolutionFile
    write-host "Getting solution info from zip: $SolutionFile"

    $solutionInfo = Get-XrmSolutionInfoFromZip -SolutionFilePath "$SolutionFile"
    Write-Host "Solution Name: " $solutionInfo.UniqueName
    Write-Host "Solution Version: " $solutionInfo.Version

    #Get Solution from New Organization and check if exists.
    $solution = Get-XrmSolution -ConnectionString "$CrmConnectionString" -UniqueSolutionName $solutionInfo.UniqueName

    if ($solution -eq $null)
    {
        Write-Host "Solution not currently installed"
    }
    else
    {
        Write-Host "Solution Installed Current version: " $solution.Version
    }

    #We always import solutions, right?

    if ($override -or ($solution -eq $null) -or ($solution.Version -ne $solutionInfo.Version))
    {
        write-host "Importing Solution: $solutionFile"
        write-host "Getting solution info from zip"

        $ImportJobId = [guid]::NewGuid()

        $HoldingSolution = $false
        $SkipProductUpdateDependencies = $false

        #TODO: Check if possible to send a report with the ouput after import
        #$logsDirectory = "C:\T\testdeploy"
        #$logFilename = "logimport"

        $propsCommand = @{'ConnectionString' = $CrmConnectionString;
            'SolutionFilePath' = $SolutionFile;
            'PublishWorkflows' = $PublishWorkflows;
            'OverwriteUnmanagedCustomizations' = $overwriteUnmanagedCustomizations;
            'SkipProductUpdateDependencies' = $SkipProductUpdateDependencies;
            'ConvertToManaged' = $ConvertToManaged;
            'HoldingSolution' = $HoldingSolution;
            'ImportJobId' = $ImportJobId;
            'AsyncWaitTimeout' = $AsyncWaitTimeout;
            'ImportAsync' = $true;
            'WaitForCompletion' = $true;
            'Timeout' = $Timeout
        }


        Write-Host "Deploying  Solution with Async Timeout $AsyncWaitTimeout seconds"
        $asyncOperationId = Import-XrmSolution @propsCommand -Verbose

        Write-Host "Solution Import Completed. Import Job Id: $importJobId"

        if ($logsDirectory)
        {
            if ($logFilename)
            {
                $importLogFile = $logsDirectory + "\" + $logFilename
            }
            else
            {
                $importLogFile = $logsDirectory + "\" + $solutionInfo.UniqueName + '_' + ($solutionInfo.Version).replace('.', '_') + '_' + [System.DateTime]::Now.ToString("yyyy_MM_dd__HH_mm") + ".xml"
            }
        }

        $importJob = Get-XrmSolutionImportLog -ImportJobId $importJobId -ConnectionString "$CrmConnectionString"

        $importProgress = $importJob.Progress
        $importResult = (Select-Xml -Content $importJob.Data -XPath "//solutionManifest/result/@result").Node.Value
        $importErrorText = (Select-Xml -Content $importJob.Data -XPath "//solutionManifest/result/@errortext").Node.Value

        write-host "Import Progress: $importProgress"
        write-host "Import Result: $importResult"
        write-host "Import Error Text: $importErrorText"
        write-host $importJob.Data

        if ($importResult -ne "success")
        {
            throw "Import Failed"
        }

        #parse the importexportxml and look for result notes with result="failure"
        $importFailed = $false
        $importjobXml = [xml]$importJob.Data
        $failureNodes = $importjobXml.SelectNodes("//*[@result='failure']")

        foreach ($failureNode in $failureNodes)
        {
            $componentName = $failureNode.ParentNode.Attributes['name'].Value
            $errorText = $failureNode.Attributes['errortext'].Value
            Write-Host "Component Import Failure: '$componentName' failed with error: '$errorText'"
            $importFailed = $true
        }

        if ($importFailed -eq $true)
        {
            throw "The Solution Import failed because one or more components with a result of 'failure' were found. For detals, check the Diagnostics for this build or the solution import log file in the logs subfolder of the Drop folder."
        }
        else
        {
            Write-Host "The import result of all components is 'success'."
        }
        #end parse the importexportxml and look for result notes with result="failure"

        $solution = Get-XrmSolution -ConnectionString "$CrmConnectionString" -UniqueSolutionName $solutionInfo.UniqueName

        if ($solution.Version -ne $solutionInfo.Version)
        {
            write-error "Import Failed. Check the solution import log file in the logs subfolder of the Drop folder."
        }
        else
        {
            Write-Host "Solution Imported Successfully"
        }
    }
    else
    {
        Write-Host "Skipped Import of Solution..."
    }

}

#Get XRM Toolkit from Package
$DeployedPath = $OctopusParameters["Octopus.Action[$NugetPackageStepName].Output.Package.InstallationDirectoryPath"]
$xrmCIToolkit = Get-ChildItem -Recurse -Path $DeployedPath | Where {$_.Name -eq "Xrm.Framework.CI.PowerShell.Cmdlets.dll"}
write-host "Toolkit is here $xrmCIToolkit"
import-module $xrmCIToolkit.Fullname -Verbose

#Get Solution File
write-host "File deployed to $DeployedPath"



#Get OctopusVariables
$CrmConnectionString = Format-OctopusArgument -Value $OctopusParameters["CRM_ConnectionString"]
$CrmSolutionName = Format-OctopusArgument -Value $OctopusParameters["CRM_SolutionName"]
$Override = Format-OctopusArgument -Value $OctopusParameters["CRM_OverrideSolution"]
$PublishWorkflows = Format-OctopusArgument -Value $OctopusParameters["CRM_PublishWorkflows"]
$OverwriteUnmanagedCustomizations = Format-OctopusArgument -Value $OctopusParameters["CRM_OverwriteUnmanagedCustomizations"]
$AsyncWaitTimeout = Format-OctopusArgument -Value $OctopusParameters["CRM_AsyncWaitTimeout"]
$Timeout = Format-OctopusArgument -Value $OctopusParameters["CRM_Timeout"]
$SolutionPackage = Format-OctopusArgument -Value $OctopusParameters["CRM_NugetPackageName"]
$SkipProductUpdateDependencies = Format-OctopusArgument -Value $OctopusParameters["CRM_SkipProductUpdateDependencies"]
$ConvertToManaged = Format-OctopusArgument -Value $OctopusParameters["CRM_ConvertToManaged"]

try {
    $SolutionFile = Get-ChildItem -Recurse -Path $DeployedPath | Where {$_.Name -Match $CrmSolutionName -and $_.Extension -match "zip"}
    write-host "Find $SolutionFile with name $SolutionFile.FullName"
} catch {
    write-error "Error Finding Solution File $SolutionPackage"
}
#TODO: try, ctach, logs, etc

write-host "solutionFile = $SolutionFile"
write-host "crmConnectionString = $CrmConnectionString"
write-host "override = $Override"
write-host "publishWorkflows = $PublishWorkflows"
write-host "overwriteUnmanagedCustomizations = $OverwriteUnmanagedCustomizations"
write-host "skipProductUpdateDependencies = $SkipProductUpdateDependencies"
write-host "AsyncWaitTimeout = $AsyncWaitTimeout"
write-host "Timeout = $Timeout"

#get info of teh solution

$deployCommand = @{'CrmConnectionString' = $CrmConnectionString;
    'SolutionFile' = $SolutionFile.FullName;
    'Override' = $Override
    'PublishWorkflows' = $PublishWorkflows;
    'SkipProductUpdateDependencies' = $SkipProductUpdateDependencies;
    'AsyncWaitTimeout' = $AsyncWaitTimeout;
    'OverwriteUnmanagedCustomizations' = $OverwriteUnmanagedCustomizations;
    'Timeout' = $Timeout;
    'ConvertToManaged' = $ConvertToManaged
}

Deploy-CRMSolution @deployCommand


write-host 'Leaving ImportSolution'
=======
Function Format-OctopusArgument
{

    Param(
        [string]$Value
    )

    $Value = $Value.Trim()

    # There must be a better way to do this
    Switch -Wildcard ($Value)
    {

        "True"
        { Return $True
        }
        "False"
        { Return $False
        }
        "#{*}"
        { Return $null
        }
        Default
        { Return $Value
        }
    }
}

function Deploy-CRMSolution
{
    Param ($CrmConnectionString, $SolutionFile, $Override, $PublishWorkflows, $SkipProductUpdateDependencies, $OverwriteUnmanagedCustomizations, $AsyncWaitTimeout, $Timeout, $ConvertToManaged )

    $solutionInfo = Get-XrmSolutionInfoFromZip -SolutionFilePath $SolutionFile
    write-host "Getting solution info from zip: $SolutionFile"

    $solutionInfo = Get-XrmSolutionInfoFromZip -SolutionFilePath "$SolutionFile"
    Write-Host "Solution Name: " $solutionInfo.UniqueName
    Write-Host "Solution Version: " $solutionInfo.Version

    #Get Solution from New Organization and check if exists.
    $solution = Get-XrmSolution -ConnectionString "$CrmConnectionString" -UniqueSolutionName $solutionInfo.UniqueName

    if ($solution -eq $null)
    {
        Write-Host "Solution not currently installed"
    }
    else
    {
        Write-Host "Solution Installed Current version: " $solution.Version
    }

    #We always import solutions, right?

    if ($override -or ($solution -eq $null) -or ($solution.Version -ne $solutionInfo.Version))
    {
        write-host "Importing Solution: $solutionFile"
        write-host "Getting solution info from zip"

        $ImportJobId = [guid]::NewGuid()

        $HoldingSolution = $false
        $SkipProductUpdateDependencies = $false

        $logsDirectory = "C:\T\testdeploy"
        $logFilename = "logimport"

        $propsCommand = @{'ConnectionString' = $CrmConnectionString;
            'SolutionFilePath' = $SolutionFile;
            'PublishWorkflows' = $PublishWorkflows;
            'OverwriteUnmanagedCustomizations' = $overwriteUnmanagedCustomizations;
            'SkipProductUpdateDependencies' = $SkipProductUpdateDependencies;
            'ConvertToManaged' = $ConvertToManaged;
            'HoldingSolution' = $HoldingSolution;
            'ImportJobId' = $ImportJobId;
            'AsyncWaitTimeout' = $AsyncWaitTimeout;
            'ImportAsync' = $true;
            'WaitForCompletion' = $true;
            'Timeout' = $Timeout
        }


        Write-Host "Deploying  Solution with Async Timeout $AsyncWaitTimeout seconds"
        $asyncOperationId = Import-XrmSolution @propsCommand -Verbose

        Write-Host "Solution Import Completed. Import Job Id: $importJobId"

        if ($logsDirectory)
        {
            if ($logFilename)
            {
                $importLogFile = $logsDirectory + "\" + $logFilename
            }
            else
            {
                $importLogFile = $logsDirectory + "\" + $solutionInfo.UniqueName + '_' + ($solutionInfo.Version).replace('.', '_') + '_' + [System.DateTime]::Now.ToString("yyyy_MM_dd__HH_mm") + ".xml"
            }
        }

        $importJob = Get-XrmSolutionImportLog -ImportJobId $importJobId -ConnectionString "$CrmConnectionString" -OutputFile "$importLogFile"

        $importProgress = $importJob.Progress
        $importResult = (Select-Xml -Content $importJob.Data -XPath "//solutionManifest/result/@result").Node.Value
        $importErrorText = (Select-Xml -Content $importJob.Data -XPath "//solutionManifest/result/@errortext").Node.Value

        write-host "Import Progress: $importProgress"
        write-host "Import Result: $importResult"
        write-host "Import Error Text: $importErrorText"
        write-host $importJob.Data

        if ($importResult -ne "success")
        {
            throw "Import Failed"
        }

        #parse the importexportxml and look for result notes with result="failure"
        $importFailed = $false
        $importjobXml = [xml]$importJob.Data
        $failureNodes = $importjobXml.SelectNodes("//*[@result='failure']")

        foreach ($failureNode in $failureNodes)
        {
            $componentName = $failureNode.ParentNode.Attributes['name'].Value
            $errorText = $failureNode.Attributes['errortext'].Value
            Write-Host "Component Import Failure: '$componentName' failed with error: '$errorText'"
            $importFailed = $true
        }

        if ($importFailed -eq $true)
        {
            throw "The Solution Import failed because one or more components with a result of 'failure' were found. For detals, check the Diagnostics for this build or the solution import log file in the logs subfolder of the Drop folder."
        }
        else
        {
            Write-Host "The import result of all components is 'success'."
        }
        #end parse the importexportxml and look for result notes with result="failure"

        $solution = Get-XrmSolution -ConnectionString "$CrmConnectionString" -UniqueSolutionName $solutionInfo.UniqueName

        if ($solution.Version -ne $solutionInfo.Version)
        {
            write-error "Import Failed. Check the solution import log file in the logs subfolder of the Drop folder."
        }
        else
        {
            Write-Host "Solution Imported Successfully"
        }
    }
    else
    {
        Write-Host "Skipped Import of Solution..."
    }

}

#Get XRM Toolkit from Package
$DeployedPath = $OctopusParameters["Octopus.Action[$NugetPackageStepName].Output.Package.InstallationDirectoryPath"]
$xrmCIToolkit = Get-ChildItem -Recurse -Path $DeployedPath | Where {$_.Name -eq "Xrm.Framework.CI.PowerShell.Cmdlets.dll"}
write-host "Toolkit is here $xrmCIToolkit"
import-module $xrmCIToolkit.Fullname -Verbose

#Get Solution File
write-host "File deployed to $DeployedPath"



#Get OctopusVariables
$CrmConnectionString = Format-OctopusArgument -Value $OctopusParameters["CRM_ConnectionString"]
$CrmSolutionName = Format-OctopusArgument -Value $OctopusParameters["CRM_SolutionName"]
$Override = Format-OctopusArgument -Value $OctopusParameters["CRM_OverrideSolution"]
$PublishWorkflows = Format-OctopusArgument -Value $OctopusParameters["CRM_PublishWorkflows"]
$OverwriteUnmanagedCustomizations = Format-OctopusArgument -Value $OctopusParameters["CRM_OverwriteUnmanagedCustomizations"]
$AsyncWaitTimeout = Format-OctopusArgument -Value $OctopusParameters["CRM_AsyncWaitTimeout"]
$Timeout = Format-OctopusArgument -Value $OctopusParameters["CRM_Timeout"]
$SolutionPackage = Format-OctopusArgument -Value $OctopusParameters["CRM_NugetPackageName"]
$SkipProductUpdateDependencies = Format-OctopusArgument -Value $OctopusParameters["CRM_SkipProductUpdateDependencies"]
$ConvertToManaged = Format-OctopusArgument -Value $OctopusParameters["CRM_ConvertToManaged"]

try {
    $SolutionFile = Get-ChildItem -Recurse -Path $DeployedPath | Where {$_.Name -Match $CrmSolutionName -and $_.Extension -match "zip"}
    write-host "Find $SolutionFile with name $SolutionFile.FullName"
} catch {
    write-error "Error Finding Solution File $SolutionPackage"
}
#TODO: try, ctach, logs, etc

write-host "solutionFile = $SolutionFile"
write-host "crmConnectionString = $CrmConnectionString"
write-host "override = $Override"
write-host "publishWorkflows = $PublishWorkflows"
write-host "overwriteUnmanagedCustomizations = $OverwriteUnmanagedCustomizations"
write-host "skipProductUpdateDependencies = $SkipProductUpdateDependencies"
write-host "AsyncWaitTimeout = $AsyncWaitTimeout"
write-host "Timeout = $Timeout"

#get info of teh solution

$deployCommand = @{'CrmConnectionString' = $CrmConnectionString;
    'SolutionFile' = $SolutionFile.FullName;
    'Override' = $Override
    'PublishWorkflows' = $PublishWorkflows;
    'SkipProductUpdateDependencies' = $SkipProductUpdateDependencies;
    'AsyncWaitTimeout' = $AsyncWaitTimeout;
    'OverwriteUnmanagedCustomizations' = $OverwriteUnmanagedCustomizations;
    'Timeout' = $Timeout;
    'ConvertToManaged' = $ConvertToManaged
}

Deploy-CRMSolution @deployCommand


write-host 'Leaving ImportSolution'
>>>>>>> 2463245ef90ff9dd95e80280d5e7fced782affb9
