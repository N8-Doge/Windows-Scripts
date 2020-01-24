#Password policy
Get-ADDefaultDomainPasswordPolicy -Current LoggedOnUser | 
    Set-ADDefaultDomainPasswordPolicy `
    -AuthType Basic `
    -ComplexityEnabled $True `
    -LockoutDuration (new-timespan -m 30) `
    -LockoutObservationWindow (new-timespan -m 30) `
    -LockoutThreshold 5 `
    -MaxPasswordAge 60 `
    -MinPasswordAge 10 `
    -MinPasswordLength 10 `
    -PasswordHistoryCount 10 `
    -ReversibleEncryptionEnabled $False

#variable stuff
$allowedUsers = cat $home/Desktop/users.txt
$allowedUsers += @("Guest","Administrator","DefaultAccount","krbtgt",$env:username)
$allowedAdmins = cat $home/Desktop/admins.txt
$allowedAdmins += @("Administrator")
$users = get-aduser -filter *
$admins = get-adgroupmember "Administrators"
$dadmins = get-adgroupmember "Domain Admins"
$groups = get-adgroup -filter *
$allowedGroups = @("Administrators","Domain Admins","Users")

#loops
foreach($u in $allowedUsers){
    if(!$users.contains($u.name)){
        new-aduser -name $u
    }
}
foreach($u in $users){
    if(!$allowedUsers.contains($u.name)){
        remove-aduser $u -confirm:$false
        echo "Removed $u"
    }
    if(!$allowedAdmins.contains($u.name)){
        if($admins.name.contains($u.name)){
            remove-adgroupmember "Administrators" -mem $u -confirm:$false
        }
        if($dadmins.name.contains($u.name)){
            remove-adgroupmember "Domain Admins" -mem $u -confirm:$false
        }
    }
    else{
        if($u.name -eq "Administrator" -or $u.name -eq "Guest"){
            Set-ADUser $u `
                -replace @{accountExpires=0} `
                -allowReversiblePasswordEncryption $false `
                -authType 1 `
                -cannotChangePassword $true `
                -changePasswordAtLogon $false `
                -enabled $false `
                -kerberosEncryptionType AES128 `
                -passwordNeverExpires $false `
                -passwordNotRequired $false `
                -trustedForDelegation $false > $null
        }
        elseif($u.name -ne $env:username -and $u.name -ne "krbtgt"){
            Set-ADUser $u `
                -replace @{accountExpires=0} `
                -allowReversiblePasswordEncryption $false `
                -authType 1 `
                -cannotChangePassword $false `
                -changePasswordAtLogon $true `
                -enabled $true `
                -kerberosEncryptionType AES128 `
                -passwordNeverExpires $false `
                -passwordNotRequired $false `
                -trustedForDelegation $false > $null
        }
        
    }
}
foreach($a in $allowedAdmins){
    if(!$admins.name.contains($a)){
        add-adgroupmember "Administrators" -mem $a
    }
    if(!$dadmins.name.contains($a)){
        add-adgroupmember "Domain Admins" -mem $a
    }
}
foreach($g in $groups){
    if(!$allowedGroups.contains($g.name)){
        remove-adgroupmember $g -mem (get-adgroupmember $g)
    }
}
