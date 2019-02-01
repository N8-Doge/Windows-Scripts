<#
    @author    Nathan Chen
    @version   1-29-19

    Currently does users
    1-24 https is what has been breaking wget
    1-25 implement because it is epic https://github.com/mortenya/Windows10-Cleanup/blob/master/Windows10-Initial-Hardening.ps1 haven't done yet
    1-29 Optimized default account stuff
    1-30 fixed wget for readme, use -usebasicparsing for text based wget's and remove https://
    1-31 now using multiple files because cleaner and also execution policy
#>

# Alias Variables and Functions
$cud = $env:Userprofile + '\Desktop'
md $cud\logs -force | out-null
$log = $cud + '\logs\main.txt'
$pwlog = $cud + '\logs\pwlog.txt'
echo 'Current Passwords:' > $pwlog
$readme = $cud + '\CyberPatriot README.url'
$admin = [Security.Principal.WindowsBuiltinRole]::Administrator
$guest = [Security.Principal.WindowsBuiltinRole]::Guest
$progressPreference = "silentlyContinue"
$confirmPreference = "none"