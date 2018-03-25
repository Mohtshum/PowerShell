These scripts are to install DNN application on machine which must have following : 

Installed Applications
* IIS 
* SQL Express 
* PowerShell PS IIS Administration Module 1.11 
* PS should be allowed for current user 

## Configurations

### LoadEnvironment.PS1 using following configurations

1. Download folder i.e. C:\downloads
   1. This must be containing the zip(downloaded from build server) of dnn application to install i.e.
   1. Website path i.e. C:\websites\
		- This folder with inherited subfolders must be given full rights for iis related accounts 
			- NETWORK SERVICE account
			- IIS AppPool\AppPoolName
   1. Pool Name in which DNN application will be binded, tough for IIS 10 this pool is already installed
		- '.NET v4.5'
   1. Optional Folder with rights same as [Website path] to get emails generated from application for testing purposeses i.e 
		- C:\websites\maildrop
		
	* You can modify these changes in LoadEnvironment.PS1 file
	
### BuildEnvironment.ps1 this script trigger installation, which is taking two argurmets for C:\PSScripts\LoadEnvironment.ps1. 

If open you will found first line

```
C:\PSScripts\LoadEnvironment.ps1 'pf_328.dnndev' 'DNN_Platform_9.2.0.328-679_Install'
```

In above
* webapplication name for DNN application 'pf_328.dnndev' it is for platform with version 328 but one put any name
* name of zip should be present inside 1.1 i.e. C:\downloads

## To start installation

1. First run Powershell with administrator rights. To enable Powershell for current user run following commands
    
    `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy UnRestricted`
    
1. Then when option to change Execution policy press "Y"
2. Now run `C:\PSScripts\BuildEnvironment.ps1`
    
    Note you must have change arguments in BuildEnvironment.ps1 for your installation.
	
That All! have fun and easy development	
		
## What this script do behind the scene.

* It first check the zip in download folder if not found it quits
* If present it stop IIS and SQL 
* Then create the folder inside folder mentioned in 1.2 ((if existing) then delete all its content)
* And unzip the zip into it. 
* Then starts IIS & SQL. 
* Then create a site with name 2.2 and bind that with earlier created folder. And bind it with app pool mentioned in LoadEnvironment
* Then create db, db user with password 'admpws' and assign it dbowner role
* Modify web.config file for connection string
* Modify web.config file for SMTP settings
* Start installation of DNN application by browsing url http://{web-application}.me/Install/Install.aspx?mode=install
	  

