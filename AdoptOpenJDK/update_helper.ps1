
function Optimize-DataSet {
[CmdletBinding()]
param(
	[Parameter(ValueFromPipeline)]
	[pscustomobject]$data,
	[switch]$warn
)
$me = ( $MyInvocation.MyCommand )
Write-Verbose "$me data -$data-"
switch -Regex ($data) {
	'\.' {
	Write-Verbose "$me we have period"
	$delimiter = '\.'
	}
	'\d{12}' {
	Write-Verbose "$me we have 12 digits"
	$delimiter = '\d{12}'
	}
	'\-' {
	Write-Verbose "$me we have dash"
	$delimiter = '\-'
	}
	'\+' {
	Write-Verbose "$me we have plus"
	$delimiter = '\+'
	}
	'\s' {
	Write-Verbose "$me we have space(s)"
	$delimiter = '\s'
	}
	default {
	Write-Verbose "$me we match nothing"
	$delimiter = ''
	}
 }
 Write-Verbose "$me delimiter -$delimiter-"
 if ($delimiter -match "\d{12}") {
 $test = ( $data -split( $delimiter) )
 $dataSet = ( $data -split( $test ) )[-1]
 } else {
 $dataSet = ( $data -split( $delimiter ) )[-1]
 }
 Write-Verbose "$me dataSet -$dataSet-"
 if ($dataSet -notmatch ".\d{2}$") {
 if ($warn) { Write-Warning "dataSet is already optimized. returning orginal data" }
 $dataSet = $data
 }
 if (($delimiter -ne "\s") -and ($dataSet -notmatch "\d{21}")) {
 Write-Verbose "$me trimming dataSet"
 $dataSet = $dataSet -replace ".{4}$"
 }
 Write-Verbose "$me Z dataSet -$dataSet-"
 return $dataSet
}

function Get-VersionYear {
[CmdletBinding()]
param(
	[string]$data
)
$me = ( $MyInvocation.MyCommand )
$years =  @()
2000..2030 | ForEach-Object { $years += $_.ToString() }
foreach ( $_ in $years ) {
	if ($data -match $_ ) {
	 Write-Verbose "$me $data matched $_"
	 $eridge = "$_"
	}
}
return $eridge
}

function Get-VersionMonth {
<#
    Delimiter removed as a param in this function on purpose
    since most data coming in is going to be using a \- or \.
    Using a trinary to switch between the two choices
#>
[CmdletBinding()]
param(
	[string]$data,
    [switch]$lucid
)
$me = ( $MyInvocation.MyCommand )
$tidy = @{$true="Month: ";$false=""}[ ([string]::IsNullOrEmpty($lucid)) ]
$length = $data.Length; $i=0
Write-Verbose "$me data -$data- length -$length-"
if ($data -match "\.") { $data = ($data -split "\.")[-1] }
Write-Verbose "$me after \. chk data -$data- length -$length-"
$data = ($data -replace "^.{4}") -replace ".{2}$"
Write-Verbose "$me after ^.{4} and .{2}$ adjustment data -$data- length -$length-"
$months =  @()
1..12 | ForEach-Object { $months += $_.ToString("00") }
foreach ( $_ in $months ) {
  if ($data -match $_ ) {
   Write-Verbose "$me $data matched $_"
   $eridge = "$tidy$_"
  }
}
return $eridge
}

#Get-VersionMonth "12.20180812" -Verbose

function Get-VersionDay {
<#
    Delimiter removed as a param in this function on purpose
    since most data coming in is going to be using a \- or \.
    Using a trinary to switch between the two choices
#>
[CmdletBinding()]
param(
	[string]$data,
    [switch]$lucid
)
$me = ( $MyInvocation.MyCommand );
$tidy = @{$true="Day: ";$false=""}[ ([string]::IsNullOrEmpty($lucid)) ]
$length = $data.Length
Write-Verbose "$me data -$data- length -$length-"; $i=0
do {
$t = @{$true="6";$false="2"}[ ($i -eq "0") ]
$length = $data.Length; $data = $data -replace "^.{$t}"; $i++
Write-Verbose "$me $i using ^.{$t} data -$data- length -$length-"
}
while (![string]::IsNullOrEmpty($data) -and (($data.Length -ge "4") -and ($data -notmatch "\-|\.")))
$days =  @()
1..31 | ForEach-Object { $days += $_.ToString("00") }
Write-Verbose "$me days -$days- data -$data-"
 foreach ( $_ in $days ) {
  if ($data -match $_ ) {
   Write-Verbose "$me $data matched $_"
   $eridge = "$tidy$_"
  }
 }
return $eridge
}

function  Get-RandomVars {
param(
    [string]$num
)
$me = ( $MyInvocation.MyCommand )
# Creation of a dynamically sized array which is more memory efficient and a better practice anyway.
$newVars = new-object collections.generic.list[object]
$NATO_Array = ("Alfa", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot", "Golf", "Hotel", "India", 'Juliett', "Kilo", "Lima", "Mike", "November", "Oscar", 'Papa', 'Quebec', 'Romeo', "Sierra", "Tango", "Uniform", "Victor", "Whiskey", "X-ray", "Yankee", "Zulu")
for ($i=0; $i -le $num; $i++) {
	$newVars.Add( $NATO_Array[$i] )
}

return $newVars
}

function Get-ChocoSemVer {
[CmdletBinding()]
param(
	[string]$number,
	[ValidateSet("ea","ga")]
	[string]$release = "ga"
)
$me = ( $MyInvocation.MyCommand )
Write-Verbose "$me A number -$number-"
$major,$minor,$patch = ($number -split "\.")
Write-Verbose "$me A major -$major- minor -$minor- patch -$patch-"

if ($patch -is [array]) { $patch = $patch[0] }

$number = $number | Optimize-DataSet
$year = Get-VersionYear $number
$month = Get-VersionMonth $number
$day = Get-VersionDay $number
Write-Verbose "$me A year -$year- month -$month- day -$day-"

Write-Verbose "$me B start -$start- end -$end-"
Write-Verbose "$me B number -$number-"

if ((![string]::IsNullOrEmpty($year) ) -and (![string]::IsNullOrEmpty($month) ) -and (![string]::IsNullOrEmpty($day) )) {
Write-Verbose "$me A year -$year- month -$month- day -$day-"
$number = ($major, $year, $month, $day) -join "."
Write-Verbose "$me Using ea versioning number -$number-"
} elseif ((![string]::IsNullOrEmpty($major) ) -and (![string]::IsNullOrEmpty($minor) ) -and (![string]::IsNullOrEmpty($patch) )) {
Write-Verbose "$me B major -$major- minor -$minor- patch -$patch-"
if (( $major -eq "8" ) -and ( $minor -eq "0" )) { $minor = $patch; $patch = $null
    Write-Verbose "$me Detected major as 8 correcting to bad version";
    Write-Verbose "$me B1 Major -$major- Minor -$minor- patch -$patch-" }
$number = ($major, $minor, $patch) -join "."
Write-Verbose "$me Using semver versioning number -$number-"
} else {
Write-Verbose "$me Using basic versioning number -$number-"
Write-Host "$me number is now -$number-"
}

Write-Verbose "$me C start -$start- end -$end-"
Write-Verbose "$me C number -$number-"

$number = Get-Version $number
$float01 = @{$true=".";$false=""}[ !([string]::IsNullOrEmpty( $number.PreRelease )) ]
$float02 = @{$true=".";$false=""}[ !([string]::IsNullOrEmpty( $number.BuildMetadata )) ]
Write-Verbose "$me D start -$start- end -$end-"
Write-Verbose "$me D number -$number- float01 -$float01- float02 -$float02-"
if (!([string]::IsNullOrEmpty($float01)) -or (![string]::IsNullOrEmpty($float02))) {
$number = -join( $number.Version, $float01, $number.PreRelease, $float02, $number.BuildMetadata )
} else {
Write-Verbose "Versioning numbers should not contain \- or \+"
$number = $number -replace("\-|\+",".")
}

Write-Verbose "$me E start -$start- end -$end-"
Write-Verbose "$me E number -$number-"

return $number
}

function Set-ReadMeFile {
[CmdletBinding()]
param(
    [string]$file = "$pwd\README.tmp",
    [string[]]$keys,
    [string[]]$new_info
)
$me = ( $MyInvocation.MyCommand );

$keys = $keys.split(" |,")
$new_info = $new_info.split(" |,")
$data = Get-Content -Path $file
$i=0
foreach( $item in $keys ) {

$data = $data  -replace( "<$item>" , $($new_info[$i]) )
$i++
}

Write-Verbose "data -$data-"
$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
[System.IO.File]::WriteAllLines("$pwd/README.md", $data, $Utf8NoBomEncoding)

}
