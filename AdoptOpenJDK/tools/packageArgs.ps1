# Due to a bug in AU. This package requires that all package Arguments be in this hashtable

$Dir = @{$true="${env:PROGRAMFILES}";$false="${env:PROGRAMFILES(X86)}"}[ ((Get-OSArchitectureWidth 64) -and $env:chocolateyForceX86 -ne $true)]
# $Dir = @{$true="C:\Program Files";$false="${env:PROGRAMFILES}"}[ ( Test-Path "$ProgramFiles" ) ]

$packageArgs = @{
  PackageName = ''
  Url = ''
  UnzipLocation = "$Dir\AdoptOpenJDK"
  Url64bit = ''
  Checksum = ''
  ChecksumType = ''
  Checksum64 = ''
  ChecksumType64 = ''
}

$targetDir = ( $packageArgs['UnzipLocation'] )

function Get-InstalledArgs {
$regex_hotspot = "(?:[jdkre]+)\-\d+\.\d\.\d+(.)\d+\-(?:[jdkrehotp]+)"
$regex = @{$true="(?:[jdkre]+)\d[u]\d+\-[b]\d+\-(?:[jdkre]+)";$false="(?:[jdkre]+)\-\d+\.\d\.\d+(.)\d+\-(?:[jdkre]+)"}[ (($packageArgs['PackageName'] -replace('[a-zA-Z]+\-[a-zA-Z]+','')) -eq "8")]
$build = @{$true="$regex_hotspot";$false="$regex"}[ ($packageArgs['PackageName'] -match "hotspot")]
$arr = Get-ChildItem $targetDir | Where-Object {$_.PSIsContainer} | Foreach-Object {$_.Name -match $build}
$installed = @{$true=$Matches[0];$false="WeAreBad"}[ ($Matches[0] -ne "") ]
return ( $installed )
}
