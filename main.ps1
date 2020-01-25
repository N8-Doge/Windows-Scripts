<#
.SYNOPSIS
    Author: Nathan Chen
    Created: 2-11-19
    Run Script

.DESCRIPTION
    Please run using batch file
#>

#----------[ Directory ]-----------
param($dir)
set-location $dir

#----------[ Main Execution ]-----------

. .\alias.ps1
. .\users.ps1
. .\firefox.ps1
. .\netsh.ps1
. .\other.ps1

#----------[ main.ps1 end ]------------
write-debug 'Reached end of main'