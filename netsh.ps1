<#
    Configures firewall
#>

# Reset current config
netsh advfirewall reset > $null

# Turns on all profile
netsh advfirewall set allprofile state on > $null


netsh advfirewall firewall set rule name=all new enable=no > $null

# Disable teredo
netsh interface teredo set state disable > $null

#
netsh interface ipv4 set global mldlevel=none > $null

# Disable LAC
netsh interface set interface name="Local Area Connection" admin=disabled > $null

# Disable IPv6
netsh interface ipv6 6to4 set state state=disabled undoonstop=disabled > $null
netsh interface ipv6 isatap set state state=disabled > $null
netsh interface ipv6 set privacy state=disabled store=active > $null
netsh interface ipv6 set privacy state=disabled store=persistent > $null

write-hf('Configured advanced firewall and interfaces')