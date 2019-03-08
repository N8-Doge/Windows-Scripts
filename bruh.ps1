$code = @'
[System.Runtime.InteropServices.DllImport("Shell32.dll")]
private static extern int SHChangeNotify(int eventId, int flags, IntPtr item1, IntPtr item2);
public static void Refresh()  {
SHChangeNotify(0x8000000, 0x1000, IntPtr.Zero, IntPtr.Zero);
}
'@
Add-Type -MemberDefinition $code -Namespace WinAPI -Name Explorer
cd $home\Desktop
$string="bruh moment `#"
$a=0
new-item ($string+$a)
$filename=($string+$a)
while($true){
$a++
rename-item $filename ($string+$a)
$filename = $string+$a
[WinAPI.Explorer]::Refresh()
start-sleep 1
}