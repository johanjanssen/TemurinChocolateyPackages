# Due to a bug in AU. This package requires that all package Arguments be in this hashtable

$ProgramFiles = @{$true="%PROGRAMFILES%";$false="%PROGRAMFILES(X86)%"}[ ((Get-ProcessorBits) -eq '64') ]
$Dir = @{$true="${PROGRAMFILES}\AdoptOpenJDK";$false="%PROGRAMFILES%\AdoptOpenJDK"}[ ( Test-Path "$ProgramFiles" ) ]

$packageArgs = @{
  PackageName = ''
  Url = ''
  UnzipLocation = $Dir
  Url64bit = ''
  Checksum = ''
  ChecksumType = ''
  Checksum64 = ''
  ChecksumType64 = ''
  SoftwareName = ''
}

$targetDir = ($packageArgs['UnzipLocation'])
$build = ($packageArgs['PackageName']) -replace('AdoptOpenJDK-','') -replace('-openj9','') -replace("\d",'')
$jvm = @{$true="hotspot";$false="openj9"}[($packageArgs['Softwarename'] -match 'hotspot')]
$name = ($packageArgs['Softwarename']) -split(' ')
$version = $name[-1]
$installed = "${build}-${version}-${jvm}"
