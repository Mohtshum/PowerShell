
# Currently this script is not resolving dependencies
# Prerequisites
# Run this script in admin mode
# IIS installed 
# Site must be created earlier
# SQL Express installed
# PowerShell PS IIS Administration Module 1.11 installed
# PS should be allowed for current user 
# Git should be installed and configured 


Param
(
	[Parameter(Mandatory = $true,Position=0)]
	[String] $WebsiteName,
	[Parameter(Mandatory = $true,Position=1)]
	[String] $ZipName
)
$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
. $scriptDir\cmd-library.PS1
. $scriptDir\DbCreate.ps1

$WEBSITE_NAME = $WebsiteName
$DOWNLOAD_PATH = "E:\websites\downloads"
$WEBSITE_DOMAIN = "$($WEBSITE_NAME).me"
$WEBSITE_URL = "http://$($WEBSITE_DOMAIN)"
$WEBSITE_PATH = "E:\websites\$($WEBSITE_NAME)"
$SQL_SERVICE_NAME = 'MSSQL$SQLEXPRESS'
$IIS_SERVICE_NAME = 'W3SVC'
$APP_POOL = '.NET v4.5'
$DB_NAME = $WEBSITE_NAME
$DB_PASSWORD = "admpws"

# Dynamic Variables
$TimeStamp = Get-Date -Format yyyyMMdd
$TimeStampDB = Get-Date -Format yyyyMMdd_Hm
$TimeStampUser = Get-Date -Format yyyyMMdd_H
$Download_File_Path = "$($DOWNLOAD_PATH)\$($ZipName).zip";
$DBNameToCreate = $DB_NAME
$UserNameToCreate = "$($DB_NAME)_adm"
 
$success = $false
    try 
	{	
		Write-Host "Starting deployment for [$($WEBSITE_NAME)]"        
		#download the install package		
		if(Assert-FileExists ($Download_File_Path))
		{
			Write-Host "Already downloaded extracting the zip [$($Download_File_Path)]"        
		}
		else
		{
			Write-Host "zip not found. Error ending installation"
			 Exit(1);
		}

        Write-Host "Stopping the site & sql server"        
		#Stop-IISSite $WEBSITE_NAME	
		Stop-Service -Name $IIS_SERVICE_NAME -force
		#Stop-WebSite -Name $WEBSITE_NAME 
		Stop-Service -Name $SQL_SERVICE_NAME -force
		Start-Sleep -Seconds 5

		Write-Host "Stopped the site & sql server"        
		#delete the website folder
		CreatePhysicalPath $WEBSITE_PATH
		Remove-Item –path "$($WEBSITE_PATH)\*" –recurse 
		Write-Host "Updating the website folder ..."        
		#Unzip the install package in website folder
		Unzip $Download_File_Path $WEBSITE_PATH
		Write-Host "Updated the website folder"        		
		Start-Service -Name $SQL_SERVICE_NAME 
		Start-Service -Name $IIS_SERVICE_NAME 
		
		Import-Module "WebAdministration"
		$IISPath = "iis:\Sites\$WEBSITE_NAME"

		if (Test-Path $IISPath) { 
			Write-Host "$WEBSITE already exists." 
		}
		else{
			New-Item iis:\Sites\$WEBSITE_NAME -bindings @{protocol="http";bindingInformation=":80:$($WEBSITE_DOMAIN)"} -physicalPath $WEBSITE_PATH
			Set-ItemProperty IIS:\Sites\$WEBSITE_NAME -name applicationPool -value $APP_POOL
		}
		
		
				
		Start-Sleep -Seconds 1		
		Start-WebSite -Name $WEBSITE_NAME         
		Start-Sleep -Seconds 2		
		Write-Host "Started the site & Sql server"        
				
		# Create db & its user		
		Create-Database $DBNameToCreate $UserNameToCreate $DB_PASSWORD 
		Write-Host "Database user created"
        
		$replaceString = "Initial Catalog=$($DBNameToCreate);User ID=$($UserNameToCreate);Password=$DB_PASSWORD"
		Set-WebConfig-ConnectionString "$($WEBSITE_PATH)/web.config" $replaceString
		
		#Update-WebConfig-ConnectionString "$($WEBSITE_PATH)/web.config" $DBNameToCreate $UserNameToCreate $DB_PASSWORD 
		Add-MailSettings "$($WEBSITE_PATH)/web.config"
		Write-Host "Website installed successfully"        		
		#browse the site
		Invoke-URLInDefaultBrowser -URL "$($WEBSITE_URL)/Install/Install.aspx?mode=install"
				
		Write-Host "Website installed successfully"        
		
		$success=$true
    }
    catch
    {
        $success=$false
        Write-Host "Unable to Setup the development environment this time, error was:$_"        
    }
	
	