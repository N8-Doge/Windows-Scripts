$searchPath = "C:\"
$fileTypes = (ls $searchPath -Recurse).Extension
$fileTypes = $fileTypes | Select-Object -Unique | Where-Object {$_}
$log = "$home\Desktop\files.txt"
$null > $log


forEach($ext in $fileTypes){
    "Searching for: $ext's"
    "*****" >> $log
    "$ext " >> $log
    "*****" >> $log
    ls $searchPath -Recurse -Filter *$ext | Select-Object -ExpandProperty FullName >> $log
}