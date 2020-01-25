<#
.SYNOPSIS

,DESCRIPTION
#>
[CmdletBinding()]
param()

#----------[ Preference Variables ]----------
$defaultConsole = "Continue"
$ConfirmPreference = "None"
$DebugPreference = $defaultConsole
$ErrorActionPreference = $defaultConsole
$ProgressPreference = $defaultConsole
$VerbosePreference = $defaultConsole
$WarningPreference = $defaultConsole

#----------[ Functions ]----------
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
$Desktop = $Home + '\Desktop'
$log = $Desktop + '\logs\main.log'
$pwlog = $Desktop + '\logs\pwlog.log'
$readme = $env:systemdrive + '\CyberPatriot\Readme.url'
set-itemproperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -name "DontUsePowershellOnWinX" -Value 0

#----------[ Prereq Checks ]----------
# Logs folder/files exist
if(-not (test-path $Desktop\logs)){
    mkdir $Desktop\logs
}

#----------[ alias.ps1 end ]-----------
write-debug 'Reached end of alias'
