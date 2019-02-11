<#
    @author    Nathan Chen
    @version   1-29-19

    Currently does users
    1-24 https is what has been breaking wget
    1-25 implement because it is epic https://github.com/mortenya/Windows10-Cleanup/blob/master/Windows10-Initial-Hardening.ps1 haven't done yet
    1-29 Optimized default account stuff
    1-30 fixed wget for readme, use -usebasicparsing for text based wget's and remove https://
    2-01 making the whole thing into different files, haven't tested yet so hope it works
#>

<#
    Find allowed users and admins through Readme parsing or desktop files
#>
$confirmation = Read-Host "Do you want to parse link? y/n"
if ($confirmation -eq 'y') {
    if (-not(test-path $readme)){write-wf('Did not find Readme to parse'); cmd /c pause; exit}
    write-host Found README at $readme -f Green
    $target = (New-Object -ComObject WScript.Shell).CreateShortcut($readme).TargetPath
    if($target.indexOf('//') -gt 0){$target = $target.substring(2+$target.indexOf('//'))}
	write-host Found README url at $target -f Green
    $file = (wget $target -Method Get -UseBasicParsing | select -expand Content).toString()
    $section = ($file.substring($file.IndexOf('<pre>')+5, $file.IndexOf('</pre>') - $file.IndexOf('<pre>')-5)) -split "`r`n" -split "<br>" -split "<b>"
    $allowedUsers = @()
    foreach ($i in $section){
        if (($i -notmatch ";") -and ($i -notmatch "`r`n")){
            $index = $i
            if ($i -match "(you)"){$index = $i.substring(0,$i.IndexOf("(you)"))}
            else{$index = $i}
            if (($index.indexof(" ") -ne -1)-and($index.indexof(" ") -eq $index.length-1)){$index=$index.substring(0,$index.length-1)}
            if($index -ne ""){$allowedUsers+=$index}
        }
    }
    $section = ($file.substring($file.IndexOf('<pre>')+5, $file.IndexOf('Authorized Users') - $file.IndexOf('<pre>')-5)) -split "`r`n" -split "<br>" -split "<b>"
    $allowedAdmins = @()
    foreach ($i in $section){
        if (($i -notmatch ";") -and ($i -notmatch "`r`n")){
            $index = $i
            if ($i -match "(you)"){$index = $i.substring(0,$i.IndexOf("(you)"))}
            else{$index = $i}
            if (($index.indexof(" ") -ne -1)-and($index.indexof(" ") -eq $index.length-1)){$index=$index.substring(0,$index.length-1)}
            if($index -ne ""){$allowedAdmins+=$index}
        }
    }
    echo "Users:"
    $allowedUsers
    echo "`nAdmins:"
    $allowedAdmins
    $confirmation = Read-Host "Are the admins and users correct? y/n"
    if ($confirmation -eq 'n') {write-wf("Something went wrong with the parser, try again");end}
}
else{
    #Check user/admin files
    if (-not(test-path $cud\Users.txt))
        {write-wf('Did not find Users.txt'); cmd /c pause; exit}
    if (-not(test-path $cud\Admins.txt))
        {write-wf('Did not find Admins.txt'); cmd /c pause; exit}
    write-hf Found users.txt and admins.txt
    $allowedUsers = cat $cud\Users.txt
    $allowedAdmins = cat $cud\Admins.txt
}
$allowedAdmins += $admin,$env:username
$allowedUsers += $admin,$env:username,$guest
if($defaultUser){$allowedUsers += $defaultUser}

<#
    Audit users and groups
#>
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
if ($defaultuser){dlu $defaultuser}
write-hf('Disabled built-in accounts, enabled others')
#Reset password policy
net accounts /minpwlen:8 > $null
secedit /export /cfg c:\secpol.cfg > $null
(cat C:\secpol.cfg).replace("PasswordComplexity = 0", "PasswordComplexity = 1").replace("ClearTextPassword = 1", "ClearTextPassword = 0") | Out-File C:\secpol.cfg
secedit /configure /db c:\windows\security\local.sdb /cfg c:\secpol.cfg /areas SECURITYPOLICY > $null
rm -force c:\secpol.cfg -confirm:$false > $null
write-hf('Restored pw policy')