<#
.SYNOPSIS
    Author: Nathan Chen
    Created: 2-14-19
    Executes appropriate user script

.DESCRIPTION
    First checks if it should parse the readme
    Then runs ADUser if commands installed
    Otherwise goes with local users
#>
[CmdletBinding()]
param()

#----------[ Checks ]----------
# Check if user files exist
$Desktop = "$home\Desktop"
if(!(test-path $Desktop\Users.txt)){
	if(!(test-path $Desktop\Admins.txt)){
		./parse.ps1
	}
}

#----------[ Main Execution ]----------
# Executes the appropriate user script
gcm get-aduser 2>&1> $null
if($?){
	./adusr.ps1
}
else{
	./lusr.ps1
}
