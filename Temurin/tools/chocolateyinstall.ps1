$ErrorActionPreference  = 'Stop'
 if(!$PSScriptRoot){ $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }
. "$PSScriptRoot\helper.ps1"

# Get Package Parameters
$parameters = (Get-PackageParameters); $pp = ( Test-PackageParamaters $parameters ).ToString() -replace('""|="True"','') -replace(";", ' ') -replace("==", '=')

$packageArgs = @{
  PackageName    = 'Temurin8'
  Url64bit       = 'https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u302-b08/OpenJDK8U-jdk_x64_windows_hotspot_8u302b08.msi'
  Checksum64     = '55B36B177962155BFB0285810DE25394A8CA8DBD436C06AB9D1D3D7D9F668347'
  ChecksumType64 = 'sha256'
  fileType       = 'msi'
  SilentArgs     = $pp
}

Install-ChocolateyPackage @packageArgs
