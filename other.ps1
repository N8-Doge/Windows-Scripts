<#
    Set audit policy, exports into \logs
#>
auditpol /set /Category:* /success:enable /failure:enable > $null
if (test-path $cud\logs\auditpolicy.txt){rm $cud\logs\auditpolicy.txt}
auditpol /backup /file:$cud\logs\auditpolicy.txt
write-hf("Set audit policies, remember to import to file to update")

<#
    Shares from shares.txt on desktop, case sensitive
#>
if (test-path $cud\shares.txt){
    $preserve = cat $cud\shares.txt
}
else{
    $preserve = ''
    write-hf('Didn''t find shares.txt, deleting all shares')
}
$shares = gwmi -class win32_share | select -expand Name
Foreach($i in $shares){
    if(!$preserve.Contains($i)){
        (gwmi -class win32_share -Filter "Name='$i'").delete() | out-null
        write-hf('Deleted share ' + $i)
    }
}

<#
    Configure firewall
#>
netsh advfirewall reset | out-null
netsh advfirewall set allprofile state on | out-null
netsh advfirewall firewall set rule name=all new enable=no | out-null
netsh interface teredo set state disable | out-null
netsh interface ipv4 set global mldlevel=none | out-null
netsh interface ipv6 6to4 set state state=disabled undoonstop=disabled | out-null
netsh interface ipv6 isatap set state state=disabled | out-null
netsh interface set interface name="Local Area Connection" admin=disabled | out-null
netsh interface ipv6 set privacy state=disabled store=active | out-null
netsh interface ipv6 set privacy state=disabled store=persistent | out-null
write-hf('Configured advanced firewall and interfaces')


<#
    Random stuff
#>
ipconfig /renew * > $null
ipconfig /flushdns > $null
write-hf('Reset ip config')
attrib -r -s C:\WINDOWS\system32\drivers\etc\hosts
echo ''> C:\Windows\System32\drivers\etc\hosts
write-hf('Wrote over host file')
if (!(test-path HKLM:\SOFTWARE\Microsoft\DirectPlayNATHelp\DPNHUPnP))
    {New-ItemProperty "HKLM:\SOFTWARE\Microsoft\DirectPlayNATHelp\DPNHUPnP" -Name "UPnPMode" -Value 2 -PropertyType "DWord" | out-null}
else
    {Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\DirectPlayNATHelp\DPNHUPnP" -Name "UPnPMode" -Value 2 | out-null}
write-hf('Disabled Universal Plug and Play')
disable-psremoting -force | out-null
write-hf('Disabled remote Powershell')


<#
    Manual windows, in progress
#>
$confirmation = Read-Host "Do you want to do manual windows? y/n"
if ($confirmation -eq 'y') {
    C:\Windows\System32\UserAccountControlSettings.exe
    write-host Set UAC to max -f yellow -b black
    cmd /c pause
    mmc devmgmt.msc
    write-host Disable extra hidden network adapters -f yellow -b black
    cmd /c pause
    RunDll32.exe InetCpl.cpl,ResetIEtoDefaults
    write-host Reset Internet Options -f yellow -b black
    cmd /c pause
    control inetcpl.cpl
    write-host Configure Internet Options -f yellow -b black
    cmd /c pause
    msconfig
    write-host Configure startup apps -f yellow -b black
    cmd /c pause
    control folders
    write-host Show hidden folders -f yellow -b black
    cmd /c pause
    wget https://www.winprivacy.de/app/download/12302828636/W10Privacy.zip?t=1545069821 -outfile $cud\w10.exe
}