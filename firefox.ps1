<#
.SYNOPSIS
    Author: Nathan Chen
    Created: 2-11-19
    Installs firefox

.DESCRIPTION
    Installs choco and reinstalls firefox
    Kills firefox so save progress before running
#>

#----------[ Main Execution ]----------
# Check if choco is installed
gcm choco -ErrorAction SilentlyContinue > $null

# Install Chocolatey
if (-not ($?)){
    #Temporarily suppress write-host
    write-host "Installing Chocolatey" -f yellow -b black
    function global:write-host() {}

    # Run script from online
    wget "https://chocolatey.org/install.ps1" | iex > $null
    rm function:\write-host
}
else{
    # Skip Chocolatey install
    write-host "Choco is installed" -f green -b black
}

# Kill Firefox
ps firefox 2> $null | kill
write-host "Reinstalling Firefox..." -f yellow -b black

# Reinstall Firefox
choco install firefox -y -force > $null
write-host "Firefox reinstalled" -f green -b black

# Open Firefox, wait for loading
start firefox about:preferences
cmd /c timeout 10

#----------[ firefox.ps1 end ]----------
write-debug 'Reached end of firefox.ps1'