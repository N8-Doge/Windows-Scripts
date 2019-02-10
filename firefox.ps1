# Set $cud if running standalone
$cud = $home + '\Desktop'

# Check if choco is installed
gcm choco -ErrorAction SilentlyContinue | out-null

# If choco not installed, install it
if (-not ($?)){
    write-host "Installing Chocolatey" -f yellow -b black
    function global:Write-Host() {} #suppress write-host
    wget "https://chocolatey.org/install.ps1" | iex > $null
    rm function:\write-host #restore write-host
}
else{
    write-host "Choco is installed" -f green -b black
}

# Kill firefox if it exists
ps firefox 2> $null | kill

# Install firefox through chocolatey
write-host "Reinstalling Firefox..." -f yellow -b black
choco install firefox -y -force > $null

# Start firefox
write-host "Firefox reinstalled" -f green -b black
start firefox about:preferences