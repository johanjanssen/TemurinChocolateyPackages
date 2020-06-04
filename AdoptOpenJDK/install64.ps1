$ErrorActionPreference  = 'Stop'
 if(!$PSScriptRoot){ $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }
. "$PSScriptRoot\helper.ps1"

# Get Package Parameters
$toolsDir = @{$true="${env:ProgramFiles}\AdoptOpenJDK";$false="${env:programfiles(x86)}\AdoptOpenJDK"}[ ((Get-OSArchitectureWidth 64) -or ($env:chocolateyForceX86 -eq $true)) ]
$parameters = (Get-PackageParameters); $pp = ( Test-PackageParamaters $parameters ).ToString() -replace('"|="True"','') -replace(";", ' ') -replace("==", '=')

$packageArgs = @{
  PackageName = ''
  Url64bit = ''
  Checksum64 = ''
  ChecksumType64 = ''
  fileType      = ''
  SilentArgs = "$pp"
}

Install-ChocolateyPackage @packageArgs
