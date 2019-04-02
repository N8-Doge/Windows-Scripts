<#
.SYNOPSIS
    Author: Nathan Chen
    Created: 2-11-19
    Initialize functions

.DESCRIPTION
    Sets up functions and variables for the master script
    Also checks prerequisites for script to run
#>
[CmdletBinding()]
param()

#----------[ Preference Variables ]----------
# Debug: Inquire, Continue, SilentlyContinue
$Console = "Continue"
$ConfirmPreference = "None"
$DebugPreference = $Console
$ErrorActionPreference = $Console
$ProgressPreference = $Console
$VerbosePreference = $Console
$WarningPreference = $Console

#----------[ Functions ]----------
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
    $s = write-log($s)
    write-output $s | tee -file $log -append
}
function write-wf{
    param([string]$s)
    $s = write-log($s)
    write-warning $s | tee -file $log -append
}
function end{
    echo "Press any key to exit"
    cmd /c pause > $null
    throw "Early exit"
}

#----------[ Declarations ]----------
$cud = $Home + '\Desktop'
$log = $cud + '\logs\main.log'
$pwlog = $cud + '\logs\pwlog.log'
$readme = $env:systemdrive + '\CyberPatriot\Readme.url'
$admin = $(get-account(500))
$guest = $(get-account(501))
$dUser = $(get-account(503))

#----------[ Prereq Checks ]----------
# Arbitrary variables
$UID = [Security.Principal.WindowsIdentity]::GetCurrent()
$userObj = new-object Security.Principal.WindowsPrincipal($UID)
$userSID = get-localuser $env:username | select -exp SID
$adminSID = get-localuser $admin | select -exp SID
$adminPos = [Security.Principal.WindowsBuiltinRole]::Administrator

# Script is running with admin
if(-not $userObj.isInRole($adminPos)){
    write-wf('Admin check failed')
    end
}

# User isn't logged into default Admin
if(($userSID -eq  $adminSID)){
    write-wf('Unique admin check failed')
    end
}

# Logs folder/files exist
if(-not (test-path $cud\logs)){
    mkdir $cud\logs
}

#----------[ alias.ps1 end ]-----------
write-debug 'Reached end of alias'