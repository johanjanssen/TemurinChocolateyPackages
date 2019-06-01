# Due to a bug in AU. This package requires that all package Arguments be in this hashtable

$ProgramFiles = @{$true="${env:PROGRAMFILES}";$false="${env:PROGRAMFILES(X86)}"}[ ((Get-ProcessorBits) -eq '64') ]
$Dir = @{$true="${PROGRAMFILES}\AdoptOpenJDK";$false="${env:PROGRAMFILES}\AdoptOpenJDK"}[ ( Test-Path "$ProgramFiles" ) ]

$packageArgs = @{
  PackageName = ''
  Url = ''
  UnzipLocation = $Dir
  Url64bit = ''
  Checksum = ''
  ChecksumType = ''
  Checksum64 = ''
  ChecksumType64 = ''
  # SoftwareName = 'AdoptOpenJDK hotspot jre12 2019.5.30.11'
}

$targetDir = ($packageArgs['UnzipLocation'])
$build = ($packageArgs['PackageName']) -replace('AdoptOpenJDK-','') -replace('-openj9','') -replace("\d",'')
$arr = Get-ChildItem $Dir | Where-Object {$_.PSIsContainer} | Foreach-Object {$_.Name -match $build}
# $jvm = @{$true="hotspot";$false="openj9"}[($packageArgs['Softwarename'] -match 'hotspot')]
# $name = ($packageArgs['Softwarename']) -split(' ')
# $version = $name[-1]
write-host "The installed dir is -$arr-"
$installed = $arr
