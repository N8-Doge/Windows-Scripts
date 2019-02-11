<#
.SYNOPSIS
    Author: Nathan Chen
    Version: 2-11-19
    Initialize functions

.DESCRIPTION
    Sets up functions and variables for the master script
    Also checks prerequisites for script to run
#>
[CmdletBinding()]
param()

#-----[Preference Variables]-----
# Debug: Inquire, Continue, SilentlyContinue
$Debug = "Continue"
$ConfirmPreference = "None"
$DebugPreference = $Debug
$ErrorActionPreference = $Debug
$ProgressPreference = $Debug
$VerbosePreference = $Debug
$WarningPreference = $Debug

#-----[Functions]-----
function get-account{
    param([int]$i)
    $str = glu * | select Name,SID
    $str -match '-'+$i | select -exp Name
}
function write-log{
    param([string]$s)
    $d = $(get-date)
    '['+$d.hour+'-'+$d.minute+'-'+$d.second+']' + $s
}
function write-hf{
    param([string]$s)
    write-output $s | tee -file $log -append
}
function write-wf{
    param([string]$s)
    write-warning $s | tee -file $log -append
}
function end{
    echo "Press any key to exit"
    cmd /c pause > $null
    exit
}

#-----[Declarations]-----
$cud = $Home + '\Desktop'
$log = $cud + '\logs\main.log'
$pwlog = $cud + '\logs\pwlog.log'
$readme = $env:systemdrive + '\CyberPatriot\Readme.url'
$admin = $(get-account(500))
$guest = $(get-account(501))

#-----[Prereq Checks (in progress]-----
net sessions 2>&1 > $null
if (!$?) {write-wf 'Run in admin'; end}

#Check admin
net sessions 2>&1 > $null
if (!$?) {write-wf 'Run in admin'; end}
write-host Admin check passed -f Green

#Check that user isn't logged into Administrator
if(($env:username -eq  $admin)){write-wf('You are logged in as Administrator, please switch accounts'); end}

#Change default account names
rnlu $admin 'notAdmin'; rnlu $guest 'notGuest'
$admin = 'notAdmin'; $guest = 'notGuest'

#Default account check?
$defaultUser=(get-wmiobject -classname win32_useraccount -Filter "LocalAccount='True'" | select Name,SID) -match '-503' | select -Expand Name 2>&1 > $null

#Boot up webclient for wget
start-service webclient 2>&1 > $null
if(!$?){write-wf('Webclient is disabled')}
else{write-hf('Booted up webclient')}
