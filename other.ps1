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
        (gwmi -class win32_share -Filter "Name='$i'").delete() > $null
        write-hf('Deleted share ' + $i)
    }
}

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
    {New-ItemProperty "HKLM:\SOFTWARE\Microsoft\DirectPlayNATHelp\DPNHUPnP" -Name "UPnPMode" -Value 2 -PropertyType "DWord" > $null}
else
    {Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\DirectPlayNATHelp\DPNHUPnP" -Name "UPnPMode" -Value 2 > $null}
write-hf('Disabled Universal Plug and Play')
disable-psremoting -force > $null
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
    wget tinyurl.com/notpsiphon -outfile $home\psiphon3.exe
    start psiphon3.exe
}

#Fin
write-hf("Script finished")