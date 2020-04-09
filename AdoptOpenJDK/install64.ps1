$ErrorActionPreference  = 'Stop'
 if(!$PSScriptRoot){ $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }
. "$PSScriptRoot\helper.ps1"

# Get Package Parameters
$toolsDir = @{$true="${env:ProgramFiles}\AdoptOpenJDK";$false="${env:programfiles(x86)}\AdoptOpenJDK"}[ ((Get-OSArchitectureWidth 64) -or ($env:chocolateyForceX86 -eq $true)) ]
$pp = ( Test-PackageParamaters (Get-PackageParameters) ).ToString() -replace('\=""\;','')

$packageArgs = @{
  PackageName = 'AdoptOpenJDK-jre8'
  Url64bit = 'https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u-2020-04-02-00-08/OpenJDK8U-jre_x64_windows_hotspot_2020-04-02-00-08.zip'
  Checksum64 = '8E1494FDC4CBD359231FA92BC4C6C71DACBCA4C2228279DF18AC4422DFD385AB'
  ChecksumType64 = 'sha256'
  fileType      = 'msi'
  SilentArgs = "$pp"
}

Install-ChocolateyPackage @packageArgs
