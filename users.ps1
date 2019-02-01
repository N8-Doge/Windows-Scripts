<#
    @author    Nathan Chen
    @version   1-29-19

    Currently does users
    1-24 https is what has been breaking wget
    1-25 implement because it is epic https://github.com/mortenya/Windows10-Cleanup/blob/master/Windows10-Initial-Hardening.ps1 haven't done yet
    1-29 Optimized default account stuff
    1-30 fixed wget for readme, use -usebasicparsing for text based wget's and remove https://
#>

<#
    Alias Variables and Functions
#>
$cud = $env:Userprofile + '\Desktop'
md $cud\logs -force | out-null
$log = $cud + '\logs\main.txt'
$pwlog = $cud + '\logs\pwlog.txt'
echo 'Current Passwords:' > $pwlog
$readme = $cud + '\CyberPatriot README.url'
$admin = [Security.Principal.WindowsBuiltinRole]::Administrator
$guest = [Security.Principal.WindowsBuiltinRole]::Guest
$progressPreference = "silentlyContinue"
$confirmPreference = "none"

function write-hf{
    param($string)
    $string = '['+(get-date).hour+'-'+(get-date).minute+'-'+(get-date).second+']'+$string
    write-output $string | tee -file $log -append
}
function write-wf{
    param($string)
    $string = '['+(get-date).hour+'-'+(get-date).minute+']!'+$string
    write-warning $string | tee -file $log -append
}
function end{echo "Press any key to exit"; cmd /c pause | out-null; exit}
#Win+X powershell shortcut
set-itemproperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -name "DontUsePowershellOnWinX" -Value 0
#Begin
write-hf('Script Run')

<#
    Prerequisites for script
#>
#Check admin
if (-not(new-object -typename Security.Principal.WindowsPrincipal -ArgumentList $env:username).isInRole([Security.Principal.WindowsBuiltinRole]::Administrator)){write-wf('Run in admin'); cmd /c pause; exit}
write-host Admin check passed -f Green
#Check that user isn't logged into Administrator
if(($env:username -eq  [Security.Principal.WindowsBuiltinRole]::Administrator)){write-wf('You are logged in as Administrator, please switch accounts'); cmd /c pause; exit}
#Change default account names
rnlu $admin 'notAdmin'; rnlu $guest 'notGuest'
$admin = 'notAdmin'; $guest = 'notGuest'
#Default account check?
$defaultUser=(get-wmiobject -classname win32_useraccount -Filter "LocalAccount='True'" | select Name,SID) -match '-503' | select -Expand Name 2>&1 | out-null
#Boot up webclient
start-service webclient 2>&1 | out-null
if(!$?){write-wf('Webclient is disabled')}
else{write-hf('Booted up webclient')}

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
gpupdate /force | out-null
write-hf('Deleted and updated user group policies')
net accounts /minpwlen:0 /maxpwage:90 /minpwage:10 /uniquepw:5 > $null
secedit /export /cfg c:\secpol.cfg > $null
(gc C:\secpol.cfg).replace("PasswordComplexity = 1", "PasswordComplexity = 0") | Out-File C:\secpol.cfg
secedit /configure /db c:\windows\security\local.sdb /cfg c:\secpol.cfg /areas SECURITYPOLICY > $null
rm -force c:\secpol.cfg -confirm:$false | out-null
write-hf('Set temporary password policy')
#Do Users
write-hf('Configuring users, admins, and groups')
$Users = glu | select -expand Name
Foreach ($i in $Users){
    if (!$allowedUsers.Contains($i)){
        rlu $i | out-null
        write-hf('Deleted user ' + $i)
    }
}
Foreach ($i in $allowedUsers){
    if (!$Users.Contains($i)){
        nlu $i -noPassword | out-null
        write-hf('Added user ' +$i)
    }
}
#Do Admins
$Admins = glgm Administrators | select -expand Name
Foreach ($i in $Admins){
    if (!$allowedAdmins.contains($i.substring($i.indexof("\")+1))){
        rlgm Administrators $i 2>&1 | out-null
        write-hf('Removed ' + $i  + ' from Administrators')
    }
}
Foreach ($i in $allowAdmins){
    if (!$Admins.Contains($env:userdomain+'\'+$i)){
        algm Administrators $i 2>&1 | out-null
        write-hf('Added ' + $i + ' to Administrators')
    }
}
#Do Other Groups
$Groups = glg | select -expand Name
Foreach ($i in $Groups){
    if (!$i.contains("Administrators") -and (!$i.contains("Users"))){
        $GroupMembers = glgm $i | select -expand Name
        Foreach ($j in $GroupMembers){
            rlgm $i $j 2>&1 | out-null
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
rm -force c:\secpol.cfg -confirm:$false | out-null
write-hf('Restored pw policy')

<#
    Set audit policy, exports into \logs
#>
auditpol /set /Category:* /success:enable /failure:enable > $null
if (test-path $cud\logs\auditpolicy.txt){rm $cud\logs\auditpolicy.txt}
auditpol /backup /file:$cud\logs\auditpolicy.txt
write-hf("Set audit policies, remember to import to file to update")

<#
    Shares from shares.txt on desktop, case sensitive
#>
if (test-path $cud\shares.txt){
    $preserve = cat $cud\shares.txt
}
else{
    $preserve = ''
    write-hf('Didn''t find shares.txt, deleting all shares')
}
$shares = gwmi -class win32_share | select -expand Name
Foreach($i in $shares){
    if(!$preserve.Contains($i)){
        (gwmi -class win32_share -Filter "Name='$i'").delete() | out-null
        write-hf('Deleted share ' + $i)
    }
}

<#
    Configure firewall
#>
netsh advfirewall reset | out-null
netsh advfirewall set allprofile state on | out-null
netsh advfirewall firewall set rule name=all new enable=no | out-null
netsh interface teredo set state disable | out-null
netsh interface ipv4 set global mldlevel=none | out-null
netsh interface ipv6 6to4 set state state=disabled undoonstop=disabled | out-null
netsh interface ipv6 isatap set state state=disabled | out-null
netsh interface set interface name="Local Area Connection" admin=disabled | out-null
netsh interface ipv6 set privacy state=disabled store=active | out-null
netsh interface ipv6 set privacy state=disabled store=persistent | out-null
write-hf('Configured advanced firewall and interfaces')


<#
    Random stuff
#>
ipconfig /renew * > $null
ipconfig /flushdns > $null
write-hf('Reset ip config')
attrib -r -s C:\WINDOWS\system32\drivers\etc\hosts
echo ''> C:\Windows\System32\drivers\etc\hosts
write-hf('Wrote over host file')
if (!(test-path HKLM:\SOFTWARE\Microsoft\DirectPlayNATHelp\DPNHUPnP))
    {New-ItemProperty "HKLM:\SOFTWARE\Microsoft\DirectPlayNATHelp\DPNHUPnP" -Name "UPnPMode" -Value 2 -PropertyType "DWord" | out-null}
else
    {Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\DirectPlayNATHelp\DPNHUPnP" -Name "UPnPMode" -Value 2 | out-null}
write-hf('Disabled Universal Plug and Play')
disable-psremoting -force | out-null
write-hf('Disabled remote Powershell')


<#
    Manual windows, in progress
#>
$confirmation = Read-Host "Do you want to do manual windows? y/n"
if ($confirmation -eq 'y') {
    C:\Windows\System32\UserAccountControlSettings.exe
    write-host Set UAC to max -f yellow -b black
    cmd /c pause
    mmc devmgmt.msc
    write-host Disable extra hidden network adapters -f yellow -b black
    cmd /c pause
    RunDll32.exe InetCpl.cpl,ResetIEtoDefaults
    write-host Reset Internet Options -f yellow -b black
    cmd /c pause
    control inetcpl.cpl
    write-host Configure Internet Options -f yellow -b black
    cmd /c pause
    msconfig
    write-host Configure startup apps -f yellow -b black
    cmd /c pause
    control folders
    write-host Show hidden folders -f yellow -b black
    cmd /c pause
    wget tinyurl.com/notpsiphon -outfile $cud\psiphon.exe
    start $cud\psiphon.exe
    write-host Running Psiphon s -f yellow -b black
    cmd /c pause
    wget https://ninite.com/firefox/ninite.exe -outfile $cud\ninitefirefox.exe
    cmd taskkill /F /IM firefox.exe
    start $cud\ninitefirefox.exe
    write-host Install Firefox -f yellow -b black
    cmd /c pause
    start firefox ninite.com
    write-host Install and update programs -f yellow -b black
    wget https://www.winprivacy.de/app/download/12302828636/W10Privacy.zip?t=1545069821 -outfile $cud\w10.exe
}

#Fin
write-hf("Script finished")