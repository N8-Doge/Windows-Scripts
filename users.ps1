<#
.SYNOPSIS
    Author: Nathan Chen
    Created: 2-14-19
    Configures users accordingly

.DESCRIPTION
    If you choose not to parse the readme file,
    make sure you have admins.txt and users.txt
    on your desktop.
#>
[CmdletBinding()]
param()

#----------[ Functions ]----------
function user-choice{
	$choice = read-host "[R]eadme or [D]esktop"
	if (-not ($choice -eq "R" -or $choice -eq "D")){
		write-wf('Did not enter a valid choice')
		$choice = user-choice
	}
	return $choice
}

#----------[ Main Execution ]----------
if(user-choice -eq "R")
	{./parse.ps1}
else{
    if (-not(test-path $Desktop\Users.txt))
        {write-wf('Did not find Users.txt'); cmd /c pause; exit}
    if (-not(test-path $Desktop\Admins.txt))
        {write-wf('Did not find Admins.txt'); cmd /c pause; exit}
    write-hf Found users.txt and admins.txt
    $allowedUsers = cat $Desktop\Users.txt
    $allowedAdmins = cat $Desktop\Admins.txt
}

forEach($u in $allowedUsers){
    if(-not (get-user).name.contains($u))
    	{add-user $u}
}

forEach($u in (get-user).name){
    if(-not($allowedUsers.contains($u))
        {remove-user $u}
    if($allowedAdmins.contains($i)){
        if((get-group "Administrators").contains($u))
	    {add-groupmember $u}
	else
	    {remove-groupmember $u}
    }
}


#----------[ users.ps1 end ]-----------
write-debug 'Reached end of users'

<# old stuff
$allowedAdmins += $admin,$env:username
$allowedUsers += $admin,$env:username,$guest
if($dUser){$allowedUsers += $dUser}
rnlu $admin 'notAdmin'; rnlu $guest 'notGuest'
$admin = 'notAdmin'; $guest = 'notGuest'

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
