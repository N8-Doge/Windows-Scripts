<#
.SYNOPSIS

,DESCRIPTION
#>
[CmdletBinding()]
param()

#----------[ Preference Variables ]----------
$defaultConsole = "Continue"
$ConfirmPreference = "None"
$DebugPreference = $DefaultConsole
$ErrorActionPreference = $DefaultConsole
$ProgressPreference = $DefaultConsole
$VerbosePreference = $DefaultConsole
$WarningPreference = $DefaultConsole

#----------[ Aliases ]----------
$winVer = $(gwmi win32_operatingsystem)
if($winVer.name.Contains("server")){
    set-alias Add-GroupMember Add-ADGroupMember
    set-alias Disable-User Disable-ADUser
    set-alias Enable-User Enable-ADUser
    set-alias Get-Group Get-ADGroup
    set-alias Get-GroupMember Get-ADGroupMember
    set-alias Get-User Get-ADUser
    set-alias New-Group New-ADGroup
    set-alias New-User New-ADUser
    set-alias Remove-Group Remove-ADGroup
    set-alias Remove-GroupMember Remove-ADGroupMember
    set-alias Remove-User Remove-ADUser
    set-alias Rename-Group Rename-ADGroup
    set-alias Rename-User Rename-ADUser
    set-alias Set-Group Set-ADGroup
    set-alias Set-User Set-ADUser
}
else{
    set-alias Add-GroupMember Add-LocalGroupMember
    set-alias Disable-User Disable-LocalUser
    set-alias Enable-User Enable-LocalUser
    set-alias Get-Group Get-LocalGroup
    set-alias Get-GroupMember Get-LocalGroupMember
    set-alias Get-User Get-LocalUser
    set-alias New-Group New-LocalGroup
    set-alias New-User New-LocalUser
    set-alias Remove-Group Remove-LocalGroup
    set-alias Remove-GroupMember Remove-LocalGroupMember
    set-alias Remove-User Remove-LocalUser
    set-alias Rename-Group Rename-LocalGroup
    set-alias Rename-User Rename-LocalUser
    set-alias Set-Group Set-LocalGroup
    set-alias Set-User Set-LocalUser
}

#----------[ Functions ]----------
function get-account{
    param([int]$i)
    $str = get-localuser * | select Name,SID
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
function get-randompw($len){
    ForEach($i in 1..$len){
        $s+=[char]((33..126) | get-random)
    }
    if($s -cmatch "[a-z]"){$i++}
    if($s -cmatch "[A-Z]"){$i++}
    if($s -cmatch "[0-9]"){$i++}
    if($s -cmatch "[^a-zA-Z0-9]"){$i++}
    if ($i -ge 3){
        $s = [String] $s
        ConvertTo-SecureString -AsPlainText $s
    }
    else{
        Get-RandomPW $len
    }
}
function end{
    echo "Press any key to exit"
    cmd /c pause > $null
    throw "Early exit"
}

#----------[ Declarations ]----------
$Desktop = $Home + '\Desktop'
$log = $Desktop + '\logs\main.log'
$pwlog = $Desktop + '\logs\pwlog.log'
$readme = $env:systemdrive + '\CyberPatriot\Readme.url'
$admin = $(get-account(500))
$guest = $(get-account(501))
$dUser = $(get-account(503))

#----------[ Prereq Checks ]----------
# Arbitrary variables
$UID = [Security.Principal.WindowsIdentity]::GetCurrent()
$userObj = new-object Security.Principal.WindowsPrincipal($UID)
$userSID = get-user $env:username | select -exp SID
$adminSID = get-user $admin | select -exp SID
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
if(-not (test-path $Desktop\logs)){
    mkdir $Desktop\logs
}

#----------[ alias.ps1 end ]-----------
write-debug 'Reached end of alias'