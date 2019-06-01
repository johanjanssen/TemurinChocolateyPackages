# Due to a bug in AU. This package requires that all package Arguments be in this hashtable

$ProgramFiles = @{$true="${env:PROGRAMFILES}";$false="${env:PROGRAMFILES(X86)}"}[ ((Get-ProcessorBits) -eq '64') ]
$Dir = @{$true="${PROGRAMFILES}\AdoptOpenJDK";$false="${env:PROGRAMFILES}\AdoptOpenJDK"}[ ( Test-Path "$ProgramFiles" ) ]

$packageArgs = @{
  PackageName = 'AdoptOpenJDK-jre12'
  Url = 'https://github.com/AdoptOpenJDK/openjdk12-binaries/releases/download/jdk12u-2019-05-30-11-00/OpenJDK12U-jre_x86-32_windows_hotspot_2019-05-30-11-00.zip'
  UnzipLocation = $Dir
  Url64bit = 'https://github.com/AdoptOpenJDK/openjdk12-binaries/releases/download/jdk12u-2019-05-30-11-00/OpenJDK12U-jre_x64_windows_hotspot_2019-05-30-11-00.zip'
  Checksum = '655A986BAFCD6F8601F53547CFADD1DBD76F75E1D5C7A2B18CD4FA0E456FF7A2'
  ChecksumType = 'sha256'
  Checksum64 = '99CB3C3DD3EAFFA4405BCD5DA5058ED7905382C926B30D4C96EF874C0B52DFCE'
  ChecksumType64 = 'sha256'
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
