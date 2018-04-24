# OctopusDeploy
Some Step templates for Octopus Deploy

# CRM_Deploy
This script uses the XRM.CI.Framework to deploy a CRM Solution

Steps:
1. Install XRm.CI.Framework Templates in your TFS Servers: https://archive.codeplex.com/?p=xrmciframework
2. Create a Project in Visual Studio with the nuspec definition of the solution to package.

Build Process:
1. Use your Project as a source of the build.
2. Add CRM Export Package Step. This will create a Solution file (zip).
3. Package in nuget the Solution File and upload to Octopus Artifactory. (nuspec definition of the project)
4. Extra Step: If your TFS admin doesnt want to add xrm powershell module or add the powershell module, pack the xrm powershell cmdlets in the same nuget file than the solution file (that was my case).

Deploy Process:
1. Add the Step to your Octopus Server and configure the variables.
2. TODO: use import-module

# SSIS_Deploy
coming soon
