# Set $cud if running standalone
$cud = $home + '\Desktop'

# Get and run psiphon
wget tinyurl.com/notpsiphon -outfile $cud\psiphon.exe
start $cud\psiphon.exe
write-host 'Running Psiphon' -f yellow -b black

# Wait for psiphon to run
start-sleep 10

# Download firefox ninite
wget https://ninite.com/firefox/ninite.exe -outfile $cud\ninitefirefox.exe

# Stop firefox if it is currently running
ps firefox 2> $null | kill

# Starts ninite to update firefox
write-host Installing Firefox -f yellow -b black
start $cud\ninitefirefox.exe -wait

#Start firefox, open ninite
start firefox about:preferences,ninite.com
