# Copyright 2012 - 2015 Aaron Jensen
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function Assert-FileExists
{
    <# 
    .SYNOPSIS 
    Asserts that a file exists. 
 
    .DESCRIPTION 
    Uses PowerShell's `Test-Path` cmdlet to check if the file exists. 
 
    .EXAMPLE 
    Assert-FileExists 'C:\Windows\system32\drivers\etc\hosts' 
 
    Demonstrates how to assert that a file exists. 
 
    .EXAMPLE 
    Assert-FileExists 'C:\foobar.txt' 'Foobar.txt wasn''t created.' 
 
    Demonstrates how to describe why an assertion might fail. 
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string]
        # The path to the file to check.
        $Path,

        [Parameter(Position=1)]
        [string]
        # A description of why the assertion might fail.
        $Message
    )

    Set-StrictMode -Version 'Latest'

    Write-Debug -Message "Testing if file '$Path' exists."
    Test-Path $Path -PathType Leaf 
    
}


Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}


#https://gist.github.com/jkdba/54fd3a3222ee3bae1436028d54634e7a

function Invoke-URLInDefaultBrowser

{

    <#

        .SYNOPSIS

            Cmdlet to open a URL in the User's default browser.

        .DESCRIPTION

            Cmdlet to open a URL in the User's default browser.

        .PARAMETER URL

            Specify the URL to be Opened.

        .EXAMPLE

            PS> Invoke-URLInDefaultBrowser -URL 'http://jkdba.com'

            

            This will open the website "jkdba.com" in the user's default browser.

        .NOTES

            This cmdlet has only been test on Windows 10, using edge, chrome, and firefox as default browsers.

    #>

    [CmdletBinding()]

    param

    (

        [Parameter(

            Position = 0,

            Mandatory = $true

        )]

        [ValidateNotNullOrEmpty()]

        [String] $URL

    )

    #Verify Format. Do not want to assume http or https so throw warning.

    if( $URL -notmatch "http://*" -and $URL -notmatch "https://*")

    {

        Write-Warning -Message "The URL Specified is formatted incorrectly: ($URL)" 

        Write-Warning -Message "Please make sure to include the URL Protocol (http:// or https://)"

        break;

    }

    #Replace spaces with encoded space

    $URL = $URL -replace ' ','%20'

    

    #Get Default browser

    $DefaultSettingPath = 'HKCU:\SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice'

    $DefaultBrowserName = (Get-Item $DefaultSettingPath | Get-ItemProperty).ProgId

    

    #Handle for Edge

    ##edge will no open with the specified shell open command in the HKCR.

    if($DefaultBrowserName -eq 'AppXq0fevzme2pys62n3e0fbqa7peapykr8v')

    {

        #Open url in edge

        start Microsoft-edge:$URL 

    }

    else

    {

        try

        {

            #Create PSDrive to HKEY_CLASSES_ROOT

            $null = New-PSDrive -PSProvider registry -Root 'HKEY_CLASSES_ROOT' -Name 'HKCR'

            #Get the default browser executable command/path

            $DefaultBrowserOpenCommand = (Get-Item "HKCR:\$DefaultBrowserName\shell\open\command" | Get-ItemProperty).'(default)'

            $DefaultBrowserPath = [regex]::Match($DefaultBrowserOpenCommand,'\".+?\"')

            #Open URL in browser

            Start-Process -FilePath $DefaultBrowserPath -ArgumentList $URL   

        }

        catch

        {

            Throw $_.Exception

        }

        finally

        {

            #Clean up PSDrive for 'HKEY_CLASSES_ROOT

            Remove-PSDrive -Name 'HKCR'

        }

    }

}


function Update-WebConfig-ConnectionString
{
  [CmdletBinding()]
	 param(
        [Parameter(Position=0)]
        [string]
        # The path to the file to check.
        $filePath,

        [Parameter(Position=1)]
        [string]
        # A description of why the assertion might fail.
		$replaceWith
    )

  
  try
  {
	  $toReplace = "Integrated Security=True;User Instance=True;AttachDBFilename=|DataDirectory|Database.mdf;"
	  (Get-Content -Path $filePath).replace($toReplace, $replaceWith) | Set-Content -Path $filePath
  }
  catch
  {
	          Throw $_.Exception
  }	
}


function Add-MailSettings 
{
  [CmdletBinding()]
	 param(
        [Parameter(Position=0)]
        [string]
        # The path to the file to check.
         $webConfigPath
    )
 
  try
  {
		Write-Host "$($webConfigPath)" -ForegroundColor Yellow
		$doc = (Get-Content $webConfigPath) -as [Xml]
		if(!$doc.configuration.'system.net')
		{
			$text='<system.net>
    <mailSettings>
      <smtp deliveryMethod="SpecifiedPickupDirectory">
        <specifiedPickupDirectory pickupDirectoryLocation="C:\websites\maildrop\" />
      </smtp>
    </mailSettings>
  </system.net>'	
	$xmlElement = $doc.configuration
	$xml = $xmlElement.OwnerDocument.ImportNode(([xml]$text).DocumentElement, $true)
    [void]$xmlElement.AppendChild($xml)
	$doc.Save($webConfigPath)
			Write-Host "Web.config updated successfully !" -ForegroundColor Green
		}else{
			Write-Host "Setting found no action required !" -ForegroundColor Green
		}
		
  }
  catch
  {
	          Throw $_.Exception
  }	
}


function Set-WebConfig-ConnectionString
{
  [CmdletBinding()]
	 param(
        [Parameter(Position=0)]
        [string]
        # The path to the file to check.
        $filePath,

        [Parameter(Position=1)]
        [string]
        # A description of why the assertion might fail.
		$replaceWith
    )

  
  try
  {
	  $toReplace = "Integrated Security=True;User Instance=True;AttachDBFilename=|DataDirectory|Database.mdf;"
	  (Get-Content -Path $filePath).replace($toReplace, $replaceWith) | Set-Content -Path $filePath
  }
  catch
  {
	          Throw $_.Exception
  }	
}

function CreatePhysicalPath {
     Param([string] $fpath)
     
     if(Test-path $fpath) {
         Write-Host "The folder $fpath already exists" -ForegroundColor Yellow
         return
         }
     else{
         New-Item -ItemType directory -Path $fpath -Force
        }
 }