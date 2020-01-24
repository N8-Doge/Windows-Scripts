<#
.SYNOPSIS
    Author: Nathan Chen
    Created: 1-24-20
    Configures users accordingly

.DESCRIPTION
    Configures local users according to
    users.txt and admins.txt
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
# Store usernames into vars
$allowedUsers = cat $Desktop\Users.txt
$allowedAdmins = cat $Desktop\Admins.txt
$allowedAdmins += @("Administrator")
$allowedUsers += @("Administrator","Guest","DefaultAccount")

# Add missing users
forEach($u in $allowedUsers){
    if(!(get-localuser).name.contains($u)){
        add-localuser $u
        write-hf("Added user $u")
    }
}

# Manage users
$plaintxt = ""
while(-not (check-password $plaintxt)){
    $plaintxt = read-host "Please enter a secure password"
}
forEach($u in (get-localuser).name){
    if(!$allowedUsers.contains($u)){
        remove-localuser $u
        write-hf("Removed user $u")
        }
    if($allowedAdmins.contains($u)){
        if(!(get-localgroup "Administrators").contains($u)){
			add-localgroupmember Administrators $u
			write-hf("Added $u to Administrators")
		}
	}
	else{
		remove-localgroupmember Administrators $u
		write-hf("Removed $u from Administrators")
	}
	if($u -ne $env:username){
        	$encrypt = convertto-securestring -asplain $plaintxt
        	set-localuser $u -password $encrypt
        	write-hf("Set $u's password to: $plaintxt")
    }
	if($u -eq $admin -or $guest -or $dUser){
        if($u.enabled){
            disable-localuser $u
            write-hf("Disabled $u")
        }
    }
    else{
        if(!$u.enabled){
            enable-localuser $u
            write-hf("Enabled $u")
        }
    }
}


#----------[ users.ps1 end ]-----------
write-debug 'Reached end of users'

<# old stuff


#Update Group Policy to allow user and password adding
if (test-path $env:windir\System32\GroupPolicyUsers) 
    {cmd /c rd /S /Q $env:windir\System32\GroupPolicyUsers}
gpupdate /force > $null
write-hf('Deleted and updated user group policies')
net accounts /minpwlen:0 /maxpwage:90 /minpwage:10 /uniquepw:5 > $null
secedit /export /cfg c:\secpol.cfg > $null
(gc C:\secpol.cfg).replace("PasswordComplexity = 1", "PasswordComplexity = 0") | Out-File C:\secpol.cfg
secedit /configure /db c:\windows\security\local.sdb /cfg c:\secpol.cfg /areas SECURITYPOLICY > $null
rm -force c:\secpol.cfg -confirm:$false > $null
write-hf('Set temporary password policy')
#Do Users
write-hf('Configuring users, admins, and groups')
$Users = glu | select -expand Name
Foreach ($i in $Users){
    if (!$allowedUsers.Contains($i)){
        rlu $i > $null
        write-hf('Deleted user ' + $i)
    }
}
Foreach ($i in $allowedUsers){
    if (!$Users.Contains($i)){
        nlu $i -noPassword > $null
        write-hf('Added user ' +$i)
    }
}
#Do Admins
$Admins = glgm Administrators | select -expand Name
Foreach ($i in $Admins){
    if (!$allowedAdmins.contains($i.substring($i.indexof("\")+1))){
        rlgm Administrators $i 2>&1 > $null
        write-hf('Removed ' + $i  + ' from Administrators')
    }
}
Foreach ($i in $allowAdmins){
    if (!$Admins.Contains($env:userdomain+'\'+$i)){
        algm Administrators $i 2>&1 > $null
        write-hf('Added ' + $i + ' to Administrators')
    }
}
#Do Other Groups
$Groups = glg | select -expand Name
Foreach ($i in $Groups){
    if (!$i.contains("Administrators") -and (!$i.contains("Users"))){
        $GroupMembers = glgm $i | select -expand Name
        Foreach ($j in $GroupMembers){
            rlgm $i $j 2>&1 > $null
            write-hf('Removed ' + $j + ' from ' + $i)
        }
    }
}
#Set user passwords, make them expire
$Users = glu |select -expand Name
Foreach ($i in $Users){
    if(!$i.equals($env:username)){
        net user $i /random /passwordchg:yes /times:all /expires:never >> $pwlog
        slu $i -PasswordNeverExpires $false 
        write-hf('Set password for ' + $i)
    }
}
slu $env:username -PasswordNeverExpires $true
#Replaces 'The command completed successfully' from logs
(cat $pwlog).replace('The command completed successfully.', '') | Where-Object {$_} | Out-File $pwlog
#Disables/Enables appropriate accounts
Foreach ($i in $Users){
    elu $i
}
dlu $admin
dlu $guest
if ($dUser){dlu $dUser}
write-hf('Disabled built-in accounts, enabled others')
#Reset password policy
net accounts /minpwlen:8 > $null
secedit /export /cfg c:\secpol.cfg > $null
(cat C:\secpol.cfg).replace("PasswordComplexity = 0", "PasswordComplexity = 1").replace("ClearTextPassword = 1", "ClearTextPassword = 0") | Out-File C:\secpol.cfg
secedit /configure /db c:\windows\security\local.sdb /cfg c:\secpol.cfg /areas SECURITYPOLICY > $null
rm -force c:\secpol.cfg -confirm:$false > $null
write-hf('Restored pw policy')
#>
