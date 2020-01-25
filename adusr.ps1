<#
.SYNOPSIS
    Author: Nathan Chen
    Created: 1-24-20
    Configures adusers
.DESCRIPTION
    Configures adusers according to 
    users.txt and admins.txt
#>
[CmdletBinding()]
param()

#----------[ Functions ]----------
Function Get-ADGroupMemberFix {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0
        )]
        [string[]]
        $Identity
    )
    process {
        foreach ($GroupIdentity in $Identity) {
            $Group = $null
            $Group = Get-ADGroup -Identity $GroupIdentity -Properties Member
            if (-not $Group) {
                continue
            }
            Foreach ($Member in $Group.Member) {
                Get-ADObject $Member 
            }
        }
    }
}

#----------[ Prelim ]----------
# Password policy
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

#----------[ Main execution ]----------
# Store values into variables
$allowedUsers = cat $home/Desktop/users.txt
$allowedUsers += @("Guest","Administrator","DefaultAccount","krbtgt",$env:username)
$allowedAdmins = cat $home/Desktop/admins.txt
$allowedAdmins += @("Administrator")
$users = get-aduser -filter *
$admins = get-adgroupmemberfix "Administrators"
$dadmins = get-adgroupmemberfix "Domain Admins"
$groups = get-adgroup -filter *
$allowedGroups = @("Administrators","Domain Admins","Users")

# Add missing users
foreach($u in $allowedUsers){
    if(!$users.name.contains($u)){
        new-aduser -name $u
    }
}

# Manage users
foreach($u in $users){
    if(!$allowedUsers.contains($u.name)){
        remove-aduser $u -confirm:$false
        echo "Removed $u"
    }
    elseif(!$allowedAdmins.contains($u.name)){
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
        if($u.name -ne $env:username){
                set-adaccountpassword $u -newpassword $encrypt
                write-hf("Set $u's password to: $plaintxt")
        }
    }
}
foreach($a in $allowedAdmins){
    if(!$admins.name.contains($a)){
        add-adgroupmember "Administrators" -members $a
    }
    if(!$dadmins.name.contains($a)){
        add-adgroupmember "Domain Admins" -members $a
    }
}
foreach($g in $groups){
    if(!$allowedGroups.contains($g.name)){
        $members = get-adgroupmemberfix $g
        if($members){
            remove-adgroupmember $g -members $members
        }
    }
}
