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
#----------[ Functions ]----------
# Check password security
function check-password($pw){
    if($pw -cmatch "[a-z]"){$i++}
    if($pw -cmatch "[A-Z]"){$i++}
    if($pw -cmatch "[0-9]"){$i++}
    if($pw -cmatch "[^a-zA-Z0-9]"){$i++}
    return ($i -ge 3)
}

#----------[ Main Execution ]----------
# Create a password string for all users
$plaintxt = ""
while(-not (check-password $plaintxt)){
    $plaintxt = read-host "Please enter a secure password"
}
$encrypt = convertto-securestring -asplain $plaintxt -force

# Executes the appropriate user script
gcm get-aduser 2>&1> $null
if($?){
	./adusr.ps1
}
else{
	./lusr.ps1
}
