if(-not (test-path $home\Desktop\tasks)){
    mkdir $home\Desktop\Tasks > $null
}
$file = "$home\Desktop\Tasks\tasks"+(get-date).hour+"-"+(get-date).minute+".txt"
$null > $file
foreach($t in (get-scheduledtask)){
    $last = (get-scheduledtaskinfo $t).lastRunTime.dayOfYear
    if($last -eq (get-date).dayOfYear){
        $t.taskName >> $file
        if($t.actions.execute -ne $null){
            "    $($t.actions.execute)" >> $file
        }
        else{
            $x = [xml] (cat "$env:windir\System32\Tasks\$($t.URI)")
            if($x.Task.RegistrationInfo.Source -ne $null){
                $x = $x.Task.RegistrationInfo.Source.toString()
                if($x -contains "dll"){
                    $x = $x.remove($x.indexOf(",")).remove(0,3)
                    if(!$?){echo $t}
                    "    $x" >> $file
                }
                else{
                    "    COM Object" >> $file
                }
            }
            else{
                "    COM Object" >> $file
            }
        }
    }
}