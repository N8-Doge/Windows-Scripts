<#
    @author    Nathan Chen
    @version   1-29-19

    Currently does users and firewall
    1-31 now using multiple files because cleaner and also execution policy
    2-04 cleaning up stuff, this looks hideous
#>

#Run files
.\alias.ps1
.\users.ps1
.\firefox.ps1
.\netsh.ps1
.\other.ps1

#Fin
write-hf("Script finished")