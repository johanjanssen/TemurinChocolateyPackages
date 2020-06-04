$ErrorActionPreference  = 'Stop'
 if(!$PSScriptRoot){ $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }
. "$PSScriptRoot\helper.ps1"

# Get Package Parameters
$toolsDir = @{$true="${env:ProgramFiles}\AdoptOpenJDK";$false="${env:programfiles(x86)}\AdoptOpenJDK"}[ ((Get-OSArchitectureWidth 64) -or ($env:chocolateyForceX86 -eq $true)) ]
$parameters = (Get-PackageParameters); $pp = ( Test-PackageParamaters $parameters ).ToString() -replace('"|="True"','') -replace(";", ' ') -replace("==", '=')

$packageArgs = @{
  PackageName = ''
  fileType = ''
  Url = ''
  Url64bit = ''
  Checksum = ''
  ChecksumType = ''
  Checksum64 = ''
  ChecksumType64 = ''
  SilentArgs = "$pp"
}

if ($parameters.both){
write-warning "Installing 32bit version"
Install-ChocolateyPackage $packageArgs.packageName $packageArgs.fileType $packageArgs.SilentArgs $packageArgs.url -checksum $packageArgs.checksum -checksumtype $packageArgs.ChecksumType
write-warning "Installing 64bit version"
Install-ChocolateyPackage $packageArgs.packageName $packageArgs.fileType $packageArgs.SilentArgs $packageArgs.Url64bit $packageArgs.Url64bit -checksum $packageArgs.Checksum64 -checksumtype $packageArgs.ChecksumType64
} else {
write-warning "Installing only Get-OSArchitectureWidth"
Install-ChocolateyPackage @packageArgs
}
