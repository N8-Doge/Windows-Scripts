<#
.SYNOPSIS
    Author: Nathan Chen
    Created: 10-9-19
    Gets users from internet based readme

.DESCRIPTION
    Stores the users and admins in variables
    titled $allowedUsers and $allowedAdmins
#>
[CmdletBinding()]
param()

#----------[ Declarations ]----------
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$readme = $env:systemdrive + '\CyberPatriot\Readme.url'
$allowedAdmins = @()
$allowedUsers = @()

#----------[ Checks ]----------
if(-not test-path $readme)
	{write-wf('Did not find Readme.url'); cmd /c pause; exit}

#----------[ Main Execution ]----------
$url = cat $readme | select-string "URL" | out-string
$url = $url.substring($url.indexOf("//")+2)
$html = wget $url -usebasicparsing | select -exp rawcontent
$int1 =  $html.indexOf("<pre>")
$int2 = $html.indexOf("</pre>") - $int1
$html = $html.substring($int1,$int2).split("`n")
$index = 0
forEach($i in $html){
	$j=$i.trim()
	if($j.contains("(you)"))
		{$j = $j.substring(0,$j.indexOf(" "))}
	if($j.contains("Administrators") -or $j.contains("Users"))
		{$index++}
	elseif (-not ($j -eq "" -or $j.contains("<") -or $j.contains("password"))){
		if($index -eq 1)
			{$allowedAdmins+=$j}
		$allowedUsers+=$j
	}
}

write-host -object "ADMINS" -b red
write-host -object $allowedAdmins -b black
write-host -object "USERS" -b red
write-host -object $allowedUsers -b black

#----------[ parse.ps1 end ]-----------
write-debug 'Reached end of parse'
