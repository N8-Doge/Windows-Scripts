# Set $cud if running standalone
$cud = $home + '\Desktop'

# Check if choco is installed
choco -?

# If choco not installed, install it
if (-not ($?)){
    wget "https://chocolatey.org/install.ps1" | iex
}

# Get and run psiphon
wget tinyurl.com/notpsiphon -outfile $cud\psiphon.exe
start $cud\psiphon.exe

# Wait for psiphon to run
start-sleep 10

#  Install firefox through chocolatey
choco install firefox -y

# Start firefox, open ninite
start firefox about:preferences,ninite.com
