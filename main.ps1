<#
    @author    Nathan Chen
    @version   1-29-19

    Currently dies i guess lol
    1-31 now using multiple files because cleaner and also execution policy
#>

# Alias Variables
$cud = $env:Userprofile + '\Desktop'
md $cud\logs -force | out-null
$log = $cud + '\logs\main.txt'
$pwlog = $cud + '\logs\pwlog.txt'
echo 'Current Passwords:' > $pwlog
$readme = $cud + '\CyberPatriot README.url'
$admin = (get-wmiobject -classname win32_useraccount -Filter "LocalAccount='True'" | select Name,SID) -match '-500' | select -Expand Name
$guest = (get-wmiobject -classname win32_useraccount -Filter "LocalAccount='True'" | select Name,SID) -match '-501' | select -Expand Name
$progressPreference = "silentlyContinue"
$confirmPreference = "none"

# Create Functions
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
function end{
    echo "Press any key to exit"; 
    cmd /c pause | out-null; 
    exit
}

#Check admin
net sessions 2>&1 $null
if (!$?) {write-wf 'Run in admin'; end}
write-host Admin check passed -f Green

#Check that user isn't logged into Administrator
if(($env:username -eq  $admin)){write-wf('You are logged in as Administrator, please switch accounts'); end}

#Change default account names
rnlu $admin 'notAdmin'; rnlu $guest 'notGuest'
$admin = 'notAdmin'; $guest = 'notGuest'

#Default account check?
$defaultUser=(get-wmiobject -classname win32_useraccount -Filter "LocalAccount='True'" | select Name,SID) -match '-503' | select -Expand Name 2>&1 | out-null

#Boot up webclient for wget
start-service webclient 2>&1 | out-null
if(!$?){write-wf('Webclient is disabled')}
else{write-hf('Booted up webclient')}

#Run files
.\users.ps1
.\firefox.ps1
.\other.ps1

#Fin
write-hf("Script finished")