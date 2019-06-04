# Due to a bug in AU. This package requires that all package Arguments be in this hashtable

$Dir = @{$true="${env:PROGRAMFILES}";$false="${env:PROGRAMFILES(X86)}"}[ ((Get-OSArchitectureWidth 64) -and $env:chocolateyForceX86 -ne $true)]
# $Dir = @{$true="C:\Program Files";$false="${env:PROGRAMFILES}"}[ ( Test-Path "$ProgramFiles" ) ]

$packageArgs = @{
  PackageName = 'AdoptOpenJDK-jre8'
  Url = 'https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u212-b03/OpenJDK8U-jre_x86-32_windows_hotspot_8u212b03.zip'
  UnzipLocation = "$Dir\AdoptOpenJDK"
  Url64bit = 'https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u212-b03/OpenJDK8U-jre_x64_windows_hotspot_8u212b03.zip'
  Checksum = '359ABD23A559ADDF535F82E92525E6086EDF0596A105DFB803B2D8CD83E39284'
  ChecksumType = 'sha256'
  Checksum64 = 'C09BAB89CD82483C371597C5C364094A145C1FBBA43A1D3D7C3E350B89DEDC89'
  ChecksumType64 = 'sha256'
}

write-host "Dir -$Dir-"
$targetDir = ( $packageArgs['UnzipLocation'] )

function Get-InstalledArgs {
write-host "F Dir -$Dir-"
$regex_hotspot = "(?:[jdkre]+)\-\d+\.\d\.\d+(.)\d+\-(?:[jdkrehotp]+)"
$regex = @{$true="(?:[jdkre]+)\d[u]\d+\-[b]\d+\-(?:[jdkre]+)";$false="(?:[jdkre]+)\-\d+\.\d\.\d+(.)\d+\-(?:[jdkre]+)"}[ (($packageArgs['PackageName'] -replace('[a-zA-Z]+\-[a-zA-Z]+','')) -eq "8")]
write-host "F regex -$regex-"
write-host "F regex_hotspot -$regex_hotspot-"
$build = @{$true="$regex_hotspot";$false="$regex"}[ ($packageArgs['PackageName'] -match "hotspot")]
write-host "F build -$build-"
write-host "F targetDir -$targetDir-"
$arr = Get-ChildItem $targetDir | Where-Object {$_.PSIsContainer} | Foreach-Object {$_.Name -match $build}
write-host "F arr -$arr-"
$installed = @{$true=$Matches[0];$false="WeAreBad"}[ ($Matches[0] -ne "") ]
write-host "F The installed dir is -$installed-"
return ( $installed )
}
