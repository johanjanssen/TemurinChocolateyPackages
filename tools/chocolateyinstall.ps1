
  $scriptDir = $(Split-Path -parent $MyInvocation.MyCommand.Definition)
  # Import function to test if JRE is the same version as already installed
  . (Join-Path $scriptDir 'packageArgs.ps1')

Install-ChocolateyZipPackage @packageArgs

$installed = ( Get-InstalledArgs )
write-host "C The installed dir is -$installed-"

# JAVA_HOME enviromental should only be set for JDK installs per https://docs.oracle.com/javase/8/docs/technotes/guides/troubleshoot/envvars001.html#CIHEEHEI
if (($installed -notmatch 'jre')){
# return from function as hash then assign variables
Install-ChocolateyEnvironmentVariable "JAVA_HOME" "${targetDir}\${installed}" "Machine"
}

# The full path instead of the %JAVA_HOME% is needed so it can be removed with the Chocolatey Uninstall
Install-ChocolateyPath "${targetDir}\${installed}\bin" -PathType "Machine"