
  $scriptDir = $(Split-Path -parent $MyInvocation.MyCommand.Definition)
  # Import function to test if JRE in the same version is already installed
  . (Join-Path $scriptDir 'packageArgs.ps1')

Install-ChocolateyZipPackage @packageArgs

Install-ChocolateyEnvironmentVariable "JAVA_HOME" "${targetDir}\${installed}" "Machine"

# The full path instead of the %JAVA_HOME% is needed so it can be removed with the Chocolatey Uninstall
Install-ChocolateyPath "${targetDir}\${installed}\bin" -PathType "Machine"
