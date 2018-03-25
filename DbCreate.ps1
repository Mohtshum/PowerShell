# https://cmatskas.com/create-sql-login-with-powershell-and-t-sql/
# Configurable Variables


function Create-Database
{
	 [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string]
        # Name of database
        $Database_name,

        [Parameter(Position=1)]
        [string]
        # user name
        $Database_user_name,

        [Parameter(Position=2)]
        [string]
        # password
        $Database_user_password
    )
	Trap {	
		$error = $_.Exception		
		while ( $error.InnerException )		
			{		
			$error = $error.InnerException		
			write-output $error.Message		
			};	
			continue	
	}

	$SERVER_NAME = ".\SQLExpress"	
	Import-Module SQLPS
	$DBName = $Database_name;

	try
	{

			$Srvr = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $SERVER_NAME	 
			
			#by assuming that this database does not yet exist in current instance
			
			
			$DBObject = $Srvr.Databases[$DBName]
 
				#check database exists on server
			if ($DBObject)
				{
					#instead of drop we will use KillDatabase
					#KillDatabase drops all active connections before dropping the database.
					$Srvr.KillDatabase($DBName)
				}
			$db = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database($Srvr, $DBName)
			$db.Create()
		   
	   
		Write-Host  "Database created! $($DBName)" -ForegroundColor Green

	}
	catch
	{
		 Write-Host "Exception Message: $($_.Exception.Message). Please set the configuration variables on top" -ForegroundColor Red
		 Exit(1);
	}    


	$instanceName = $SERVER_NAME
	$loginName = $Database_user_name
	$dbUserName = $Database_user_name
	$password = $Database_user_password
	$databasenames = $DBName
	$roleName = "db_owner"


	try
	{
		$server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $instanceName	
		
		# drop login if it exists
		if ($server.Logins.Contains($loginName))  
		{   
			Write-Host("Deleting the existing login $loginName.")
			   $server.Logins[$loginName].Drop() 
		}		
		
		$login = New-Object `
		-TypeName Microsoft.SqlServer.Management.Smo.Login `
		-ArgumentList $server, $loginName
		$login.LoginType = [Microsoft.SqlServer.Management.Smo.LoginType]::SqlLogin
		$login.PasswordExpirationEnabled = $false
		$login.Create($password)
		Write-Host("Login $loginName created successfully.")
		
			foreach($databaseToMap in $databasenames)  
			{
				$database = $server.Databases[$databaseToMap]   
		
				$dbUser = New-Object `
				-TypeName Microsoft.SqlServer.Management.Smo.User `
				-ArgumentList $database, $dbUserName
				$dbUser.Login = $loginName
				$dbUser.Create()
				Write-Host("User $dbUser created successfully.")
		
				#assign database role for a new user
				$dbrole = $database.Roles[$roleName]
				$dbrole.AddMember($dbUserName)
				$dbrole.Alter()
				Write-Host("User $dbUser successfully added to $roleName role.")
			}	
	}
	catch
	{
		Throw $_.Exception
	}


}