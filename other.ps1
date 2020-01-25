<#
    Set audit policy, exports into \logs
#>
auditpol /set /Category:* /success:enable /failure:enable > $null
if (test-path $Desktop\logs\auditpolicy.txt){rm $Desktop\logs\auditpolicy.txt}
auditpol /backup /file:$cud\logs\auditpolicy.txt
write-hf("Set audit policies, remember to import to file to update")

<#
    Shares from shares.txt on desktop, case sensitive
#>
$preserve = @("SYSVOL","NETLOGON")
if (test-path $Desktop\shares.txt){
    $preserve += cat $Desktop\shares.txt
}
else{
    write-hf('Didn''t find shares.txt, deleting all shares')
}
$shares = gwmi -class win32_share | select -expand Name
forEach($i in $shares){
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
$x = $VerbosePreference
$VerbosePreference = "SilentlyContinue"
disable-psremoting -force -debug:$false -verbose:$false > $null
$VerbosePreference = $x
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
}

$confirmation = Read-Host "Do you want to export scheduled tasks? y/n"
if ($confirmation -eq 'y'){
    write-host Exporting... -f yellow -b black
    ./task.ps1
    write-host "Check your desktop for scheduled tasks"
}

#Fin
write-hf("Script finished")

#----------[ other.ps1 end ]------------
write-debug 'Reached end of other'
