$ErrorActionPreference  = 'Stop'
 if(!$PSScriptRoot){ $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }
. "$PSScriptRoot\helper.ps1"

# Get Package Parameters
$toolsDir = @{$true="${env:ProgramFiles}\AdoptOpenJDK";$false="${env:programfiles(x86)}\AdoptOpenJDK"}[ ((Get-OSArchitectureWidth 64) -or ($env:chocolateyForceX86 -eq $true)) ]
$parameters = (Get-PackageParameters); $pp = ( Test-PackageParamaters $parameters ).ToString() -replace('\=""\;','')

$packageArgs = @{
  PackageName = 'AdoptOpenJDK-jre8'
  fileType = 'msi'
  Url = 'https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u-2020-04-02-00-08/OpenJDK8U-jre_x86-32_windows_hotspot_2020-04-02-00-08.zip'
  Url64bit = 'https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u-2020-04-02-00-08/OpenJDK8U-jre_x64_windows_hotspot_2020-04-02-00-08.zip'
  Checksum = 'B276E0CDF8FF3003D8E94F6C65BA811F7FA84C5238FD2E6099360E439448F757'
  ChecksumType = 'sha256'
  Checksum64 = '8E1494FDC4CBD359231FA92BC4C6C71DACBCA4C2228279DF18AC4422DFD385AB'
  ChecksumType64 = 'sha256'
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
