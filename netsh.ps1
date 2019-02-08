<#
    Configures firewall
#>

# Reset current config
netsh advfirewall reset | out-null

# Turns on all profile
netsh advfirewall set allprofile state on | out-null


netsh advfirewall firewall set rule name=all new enable=no | out-null

# Disable teredo
netsh interface teredo set state disable | out-null

#
netsh interface ipv4 set global mldlevel=none | out-null

# Disable LAC
netsh interface set interface name="Local Area Connection" admin=disabled | out-null

# Disable IPv6
netsh interface ipv6 6to4 set state state=disabled undoonstop=disabled | out-null
netsh interface ipv6 isatap set state state=disabled | out-null
netsh interface ipv6 set privacy state=disabled store=active | out-null
netsh interface ipv6 set privacy state=disabled store=persistent | out-null

write-hf('Configured advanced firewall and interfaces')