import-module au
. "$PSScriptRoot\update_helper.ps1"

function global:au_BeforeUpdate {
  Get-RemoteFiles -Purge -FileNameBase "$($Latest.PackageName)"
	# Removal of downloaded files
  Remove-Item ".\tools\*.$($Latest.fileType)" -Force
	# Change the install file based on $Latest.URL32 and $Latest.fileType
  if (([string]::IsNullOrEmpty($Latest.URL32)) -and ($Latest.fileType -match "msi")) {
    cp "$PSScriptRoot\install64.ps1" "$PSScriptRoot\tools\chocolateyinstall.ps1" -Force
  }
  else {
    cp "$PSScriptRoot\install32.ps1" "$PSScriptRoot\tools\chocolateyinstall.ps1" -Force
  }
	$jvm = @{$true="Eclipse_OpenJ9";$false="OpenJDK_HotSpot"}[ ( $Latest.PackageName -match "openj9" )]
	Set-ReadMeFile -keys "fileType,Vendor,JVM_Type,PackageName" -new_info "$($Latest.fileType),Temurin,$jvm,$($Latest.PackageName)"
	# Adding summary to the Latest Hashtable
	$Latest.summary	= "Adoptium provides prebuilt OpenJDK build binaries. This one uses $jvm."
}

function global:au_SearchReplace {
  if ( [string]::IsNullOrEmpty($Latest.URL32) ) {
		@{
			".\tools\chocolateyinstall.ps1" = @{
				"(?i)(^\s*PackageName\s*=\s*)('.*')"           = "`$1'$($Latest.PackageName)'"
				"(?i)(^\s*fileType\s*=\s*)('.*')"              = "`$1'$($Latest.fileType)'"
				"(?i)(^\s*url64bit\s*=\s*)('.*')"              = "`$1'$($Latest.URL64)'"
				"(?i)(^\s*Checksum64\s*=\s*)('.*')"            = "`$1'$($Latest.Checksum64)'"
				"(?i)(^\s*ChecksumType64\s*=\s*)('.*')"        = "`$1'$($Latest.ChecksumType64)'"
			}
			".\temurin.nuspec" = @{
				"(?i)(^\s*\<title\>).*(\<\/title\>)"           = "`${1}$($Latest.Title)`${2}"
				"(?i)(^\s*\<summary\>).*(\<\/summary\>)"       = "`${1}$($Latest.summary)`${2}"
				"(?i)(^\s*\<licenseUrl\>).*(\<\/licenseUrl\>)" = "`${1}$($Latest.LicenseUrl)`${2}"
			}
		}
	} else {
		@{
			".\tools\chocolateyinstall.ps1" = @{
				"(?i)(^\s*PackageName\s*=\s*)('.*')"           = "`$1'$($Latest.PackageName)'"
				"(?i)(^\s*fileType\s*=\s*)('.*')"              = "`$1'$($Latest.fileType)'"
				"(?i)(^\s*url\s*=\s*)('.*')"                   = "`$1'$($Latest.URL32)'"
				"(?i)(^\s*url64bit\s*=\s*)('.*')"              = "`$1'$($Latest.URL64)'"
				"(?i)(^\s*Checksum\s*=\s*)('.*')"              = "`$1'$($Latest.Checksum32)'"
				"(?i)(^\s*ChecksumType\s*=\s*)('.*')"          = "`$1'$($Latest.ChecksumType32)'"
				"(?i)(^\s*Checksum64\s*=\s*)('.*')"            = "`$1'$($Latest.Checksum64)'"
				"(?i)(^\s*ChecksumType64\s*=\s*)('.*')"        = "`$1'$($Latest.ChecksumType64)'"
			}
			".\temurin.nuspec" = @{
				"(?i)(^\s*\<title\>).*(\<\/title\>)"           = "`${1}$($Latest.Title)`${2}"
				"(?i)(^\s*\<summary\>).*(\<\/summary\>)"       = "`${1}$($Latest.summary)`${2}"
				"(?i)(^\s*\<licenseUrl\>).*(\<\/licenseUrl\>)" = "`${1}$($Latest.LicenseUrl)`${2}"
			}
		}
	}
}

function Get-OpenSourceJDK {
[CmdletBinding()]
param(
[parameter(Mandatory=$true)]
[ValidateSet("8","11","17","18")]
[string]$number = "8",
[parameter(Mandatory=$true)]
[ValidateSet("ea", "ga")]
[string]$release = "ga",
[ValidateSet("aarch64", "arm", "ppc64", "ppc64le", "s390x", "sparcv9", "x32", "x64")]
[string]$arch,
[ValidateSet("aix", "linux", "mac", "solaris", "windows")]
[string]$OS = "windows",
[ValidateSet("jdk", "jre", "testimage")]
[string]$type = "jdk",
[ValidateSet("hotspot", "openj9")]
[string]$jvm = "hotspot", 
[ValidateSet("adoptium", "openjdk")]
[string]$vendor = "adoptium",
[ValidateSet("jdk", "valhalla", "metropolis", "jfr")]
[string]$project = "jdk",
[ValidateSet("large", "normal")]
[string]$heap_size = "normal",
[string]$dev_name,     # orginal package name
[switch]$ext,          # optional switch for extensions
[switch]$fixedversion  # optional switch for fixedversion
)
$me = ( $MyInvocation.MyCommand );
# Depending on the $arch used above determines which string is used in the call to the server
if ($arch) {
$openJDKapi = "https://api.adoptium.net/v3/assets/feature_releases/${number}/${release}?architecture=${arch}&heap_size=${heap_size}&image_type=${type}&jvm_impl=${jvm}&os=${OS}&page=0&page_size=1&project=${project}&sort_order=DESC&vendor=${vendor}"
} else {
$openJDKapi = "https://api.adoptium.net/v3/assets/feature_releases/${number}/${release}?heap_size=${heap_size}&image_type=${type}&jvm_impl=${jvm}&os=${OS}&page=0&page_size=1&project=${project}&vendor=${vendor}"
}
Write-Verbose "$me openJDKapi -$openJDKapi-"
$t = try { (Invoke-WebRequest -Uri $openJDKapi -ErrorAction Stop -UseBasicParsing).BaseResponse }
	catch [System.Net.WebException] { Write-Warning "$me An exception was caught: $($_.Exception.Message)"; $_.Exception.Response }
	if ( $t.StatusCode -eq "OK" ) {
		$rest = Invoke-WebRequest -Uri $openJDKapi -UseBasicParsing | ConvertFrom-Json
	} else { Write-Verbose "$me this is a bad request"; return; }

# Links are available depending the number supplied
$links = @{$true=($rest.binaries.installer.link);$false=($rest.binaries.package.link)}[ (($number -notmatch "9") -or ($number -notmatch "10")) ]
Write-Verbose "$me links -$links-"
# Most Feature release version have a 32 & 64 bit version
if ($links -is [array]) {
  if ($links[0] -match "x64") {
    $url32 = $links[-1]; $url64 = $links[0]; Write-Verbose "A $me url32 -$url32-"
	} else {
    $url32 = $links[0]; $url64 = $links[-1]; Write-Verbose "B $me url32 -$url32-"
	}
} else { $url64 = $links }; Write-Verbose "$me url64 -$url64-"
# Getting the File Extension if prompted
if ($ext) { $fileType = (( $url64 -split("\\") )[-1] -split("\.") )[-1] }
# API provides version numbers as a separate line as a semver version
$vest = $rest.version_data.semver; Write-Verbose "$me vest -$vest-"
# This will keep some uniformity with the packages of Early Access(ea) or nightly builds by using the Get-ChocoSemVer to make a Chocolatey usable Version
$version = ( Get-ChocoSemVer $vest -release $release )
# This will output a version number if BuildMetadata is present
if ($version.BuildMetadata) { $version = -join( $version.Version, ".", $version.BuildMetadata) }  
$build = @{$true = "nightly"; $false = "" }[ ( $release -eq "ea" ) ]
$beta = @{$true = "${version}"; $false = "${version}-${build}" }[ ( $release -eq "ga" ) ]
$JavaVM = @{$true = "${type}${number}"; $false = "${type}${number}-${jvm}" }[ ( $jvm -match "hotspot" ) ]
$PackageName = @{$true = "Temurin-${JavaVM}"; $false = "${dev_name}" }[ ( $dev_name -eq "" ) ]
if ($url32 -match "${number}" -or $url32 -match "${number}U") { $url32 = $url32 } else { $url32 = $null } # From Java 16 the U in the version was removed
Write-Verbose "$me url32 -$url32- url64 -$url64-"
if ($fixedVersion) {
  $packageVersion =  $beta
} else {
  $packageVersion = Get-FixVersion $beta
}

# Starting with Java 16, the u after the version was removed update 26-10-2021 with Adoptium the 'u' seems to be added again
#$versionPostFix = ""
#if ([int]"${number}" -lt 16) { $versionPostFix = "u" }

	@{
        Title           = "Temurin ${type}${number} ${jvm} ${version}"
        PackageName     = $PackageName
        URL32           = $url32
        URL64           = $url64
        Version         = $packageVersion
        LicenseUrl      = "https://github.com/adoptium/jdk${number}u/blob/master/LICENSE"
        SemVer          = $vest
        fileType        = $fileType
	}
}

function global:au_GetLatest {
# Skip 9 and 10 as they don't have MSI's
$numbers = @("8", "11", "17","18"); $types = @("jdk") #$types = @("jdk","jre")
# Optionally add "nightly" to $builds
$jvms = @("hotspot"); $builds = @("ga"); $os = "windows"

$streams = [ordered] @{ }
foreach ( $number in $numbers ) {
	foreach ( $type in $types) {
		foreach ( $jvm in $jvms ) {
			foreach ( $build in $builds ) {        
				# Create a package without the version for the latest release
				if ( $number -eq $numbers[-1] ) { 
					$name = "Temurin"
					if ($jvm -eq "openj9") {
						$name = $name + $jvm
					}
					if ($type -eq "jre") {
						$name = $name + $type
					} 
					$streams.Add( "$($type)$($number)_$($jvm)_$($build)_Latest" , ( Get-OpenSourceJDK -number $number -type $type -jvm $jvm -OS $os -release $build -dev_name $name -ext ) )
				} 

				$name = "Temurin$number"
				if ($jvm -eq "openj9") {
					$name = $name + $jvm
				}
				if ($type -eq "jre") {
					$name = $name + $type
				}
				$streams.Add( "$($type)$($number)_$($jvm)_$($build)" , ( Get-OpenSourceJDK -number $number -type $type -jvm $jvm -OS $os -release $build -dev_name $name -ext ) )        
			}
		}
	}
}
return @{ Streams = $streams } 
}
# Optionally add '-NoCheckChocoVersion' below to create packages for versions that already exist on the Chocolatey server.
update -ChecksumFor none -NoCheckUrl -NoCheckChocoVersion
