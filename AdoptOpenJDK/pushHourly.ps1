for(;;) {
 try {
	.\pushpackages.ps1
 }
 catch {
  $_
 }

 # wait for a minute
 Start-Sleep 3600
}