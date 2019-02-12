<#
.SYNOPSIS
    Author: Nathan Chen
    Version: 2-11-19
    Installs firefox

.DESCRIPTION
    Installs choco and reinstalls firefox
    Kills firefox so save progress before running
#>

#----------[ Variables ]----------
$cud = $home + '\Desktop'

#----------[ Main Execution ]----------
# Check if choco is installed
gcm choco -ErrorAction SilentlyContinue > $null
if (-not ($?)){
    write-host "Installing Chocolatey" -f yellow -b black
    function global:Write-Host() {} #suppress write-host
    wget "https://chocolatey.org/install.ps1" | iex > $null
    rm function:\write-host #restore write-host
}
else{
    write-host "Choco is installed" -f green -b black
}

# Reinstall firefox
ps firefox 2> $null | kill
write-host "Reinstalling Firefox..." -f yellow -b black
choco install firefox -y -force > $null
write-host "Firefox reinstalled" -f green -b black
start firefox about:preferences

#----------[ firefox.ps1 end ]----------
write-debug 'Reached end of firefox.ps1'