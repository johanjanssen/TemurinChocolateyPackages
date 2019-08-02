Get-ChildItem -Filter *.nupkg | 
Foreach-Object {
	choco push $_ --source https://push.chocolatey.org/
}