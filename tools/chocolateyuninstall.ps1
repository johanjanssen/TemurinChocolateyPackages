
  $scriptDir = $(Split-Path -parent $MyInvocation.MyCommand.Definition)
  # Import function to test if JRE in the same version is already installed
  . (Join-Path $scriptDir 'packageArgs.ps1')


Uninstall-ChocolateyEnvironmentVariable 'JAVA_HOME' 'Machine'
rm -r "$targetDir\$installed"

$pathToUnInstall = "$targetDir\$installed\bin"
$pathType = "Machine"

if ($env:PATH.ToLower().Contains($pathToUnInstall.ToLower()))
{
	$statementTerminator = ";"
	Write-Host "PATH environment variable contains $pathToUnInstall. Removing..."
	$actualPath = [System.Collections.ArrayList](Get-EnvironmentVariable -Name 'Path' -Scope $pathType).split($statementTerminator)

	$actualPath.Remove($pathToUnInstall)	
	$newPath =  $actualPath -Join $statementTerminator

	if ($pathType -eq [System.EnvironmentVariableTarget]::Machine) {
		if (Test-ProcessAdminRights) {
			Set-EnvironmentVariable -Name 'Path' -Value $newPath -Scope $pathType
		} else {
			$psArgs = "UnInstall-ChocolateyPath -pathToUnInstall `'$originalPathToUnInstall`' -pathType `'$pathType`'"
			Start-ChocolateyProcessAsAdmin "$psArgs"
		}
	} else {
		Set-EnvironmentVariable -Name 'Path' -Value $newPath -Scope $pathType
	}
}

$AdoptOpenJDKDirectory = "$targetDir"
If ((Get-ChildItem -Force $AdoptOpenJDKDirectory) -eq $Null) {
    rmdir $AdoptOpenJDKDirectory 
}