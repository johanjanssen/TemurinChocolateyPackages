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
	Set-ReadMeFile -keys "fileType,Vendor,JVM_Type,PackageName" -new_info "$($Latest.fileType),AdoptOpenJDK,$jvm,$($Latest.PackageName)"
	# Adding summary to the Latest Hashtable
	$Latest.summary	= "AdoptOpenJDK provides prebuilt OpenJDK build binaries. This one uses $jvm."
}

function global:au_SearchReplace {
  if ( [string]::IsNullOrEmpty($Latest.URL32) ) {
		@{
			".\tools\chocolateyinstall.ps1" = @{
				"(?i)(^\s*PackageName\s*=\s*)('.*')" = "`$1'$($Latest.PackageName)'"
				"(?i)(^\s*url64bit\s*=\s*)('.*')"	= "`$1'$($Latest.URL64)'"
				"(?i)(^\s*Checksum64\s*=\s*)('.*')" = "`$1'$($Latest.Checksum64)'"
				"(?i)(^\s*ChecksumType64\s*=\s*)('.*')" = "`$1'$($Latest.ChecksumType64)'"
			}
			".\adoptopenjdk.nuspec" = @{
				"(?i)(^\s*\<title\>).*(\<\/title\>)" = "`${1}$($Latest.Title)`${2}"
				"(?i)(^\s*\<summary\>).*(\<\/summary\>)" = "`${1}$($Latest.summary)`${2}"
				"(?i)(^\s*\<licenseUrl\>).*(\<\/licenseUrl\>)" = "`${1}$($Latest.LicenseUrl)`${2}"
			}
		}
	} else {
		@{
			".\tools\chocolateyinstall.ps1" = @{
				"(?i)(^\s*PackageName\s*=\s*)('.*')" = "`$1'$($Latest.PackageName)'"
				"(?i)(^\s*url\s*=\s*)('.*')" = "`$1'$($Latest.URL32)'"
				"(?i)(^\s*url64bit\s*=\s*)('.*')"	= "`$1'$($Latest.URL64)'"
				"(?i)(^\s*Checksum\s*=\s*)('.*')" = "`$1'$($Latest.Checksum32)'"
				"(?i)(^\s*ChecksumType\s*=\s*)('.*')" = "`$1'$($Latest.ChecksumType32)'"
				"(?i)(^\s*Checksum64\s*=\s*)('.*')" = "`$1'$($Latest.Checksum64)'"
				"(?i)(^\s*ChecksumType64\s*=\s*)('.*')" = "`$1'$($Latest.ChecksumType64)'"
			}
			".\adoptopenjdk.nuspec" = @{
				"(?i)(^\s*\<title\>).*(\<\/title\>)" = "`${1}$($Latest.Title)`${2}"
				"(?i)(^\s*\<summary\>).*(\<\/summary\>)" = "`${1}$($Latest.summary)`${2}"
				"(?i)(^\s*\<licenseUrl\>).*(\<\/licenseUrl\>)" = "`${1}$($Latest.LicenseUrl)`${2}"
			}
		}
	}
}

function Get-OpenSourceJDK {
[CmdletBinding()]
param(
[parameter(Mandatory=$true)]
[ValidateSet("8","9","10","11","12","13","14")]
[string]$number = "8",
[parameter(Mandatory=$true)]
[ValidateSet("ea", "ga")]
[string]$release = "ga",
[ValidateSet("aarch64", "arm", "ppc64", "ppc64le", "s390x", "sparcv9", "x32", "x64")]
[string]$arch,
[ValidateSet("aix", "linux", "mac", "solaris", "windows")]
[string]$OS = "windows",
[ValidateSet("jdk", "jre", "testimage")]
[string]$type = "jre",
[ValidateSet("hotspot", "openj9")]
[string]$jvm = "hotspot", 
[ValidateSet("adoptopenjdk", "openjdk")]
[string]$vendor = "adoptopenjdk",
[ValidateSet("jdk", "valhalla", "metropolis", "jfr")]
[string]$project = "jdk",
[ValidateSet("large", "normal")]
[string]$heap_size = "normal",
[string]$dev_name, # orginal package name
[switch]$ext # optional switch
)
$me = ( $MyInvocation.MyCommand );
# Depending on the $arch used above determines which string is used in the call to the server
if ($arch) {
$openJDKapi = "https://api.adoptopenjdk.net/v3/assets/feature_releases/${number}/${release}?architecture=${arch}&heap_size=${heap_size}&image_type=${type}&jvm_impl=${jvm}&os=${OS}&page=0&page_size=1&project=${project}&sort_order=DESC&vendor=${vendor}"
} else {
$openJDKapi = "https://api.adoptopenjdk.net/v3/assets/feature_releases/${number}/${release}?heap_size=${heap_size}&image_type=${type}&jvm_impl=${jvm}&os=${OS}&page=0&page_size=1&project=${project}&vendor=${vendor}"
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
$url32 = $links[-1]; $url64 = $links[0]; Write-Verbose "$me url32 -$url32-"
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
$PackageName = @{$true = "AdoptOpenJDK-${JavaVM}"; $false = "${dev_name}" }[ ( $dev_name -eq "" ) ]
if ($url32 -match "${number}U") { $url32 = $url32 } else { $url32 = $null }
Write-Verbose "$me url32 -$url32- url64 -$url64-"

	@{
        Title           = "AdoptOpenJDK ${type}${number} ${jvm} ${version}"
        PackageName     = $PackageName
        URL32           = $url32
        URL64           = $url64
        Version         = $beta
        LicenseUrl      = "https://github.com/AdoptOpenJDK/openjdk-jdk${number}u/blob/master/LICENSE"
        SemVer          = $vest
        fileType        = $fileType
	}
}

function global:au_GetLatest {

  $streams = [ordered] @{
	<# Version 8 Stable #>
	AdoptOpenJDK8jdk = Get-OpenSourceJDK -number 8 -release ga -OS windows -type jdk -jvm hotspot -ext
	AdoptOpenJDK8jre = Get-OpenSourceJDK -number 8 -release ga -OS windows -type jre -jvm hotspot -ext
	AdoptOpenJDK8openj9jdk = Get-OpenSourceJDK -number 8 -release ga -OS windows -type jdk -jvm openj9 -ext
	AdoptOpenJDK8openj9jre = Get-OpenSourceJDK -number 8 -release ga -OS windows -type jre -jvm openj9 -ext
	# <# Version 9 Stable #>
	# AdoptOpenJDK9jdk = Get-OpenSourceJDK -number 9 -release ga -OS windows -type jdk -jvm hotspot -ext
	# AdoptOpenJDK9jre = Get-OpenSourceJDK -number 9 -release ga -OS windows -type jre -jvm hotspot -ext
	# AdoptOpenJDK9openj9jdk = Get-OpenSourceJDK -number 9 -release ga -OS windows -type jdk -jvm openj9 -ext
#	AdoptOpenJDK9openj9jre = Get-OpenSourceJDK -number 9 -release ga -OS windows -type jre -jvm openj9 -ext
	# <# Version 10 Stable #>
	# AdoptOpenJDK10jdk = Get-OpenSourceJDK -number 10 -release ga -OS windows -type jdk -jvm hotspot -ext
	# AdoptOpenJDK10jre = Get-OpenSourceJDK -number 10 -release ga -OS windows -type jre -jvm hotspot -ext
	# AdoptOpenJDK10openj9jdk = Get-OpenSourceJDK -number 10 -release ga -OS windows -type jdk -jvm openj9 -ext
#	AdoptOpenJDK8openj9jre = Get-OpenSourceJDK -number 10 -release ga -OS windows -type jre -jvm openj9 -ext
	<# Version 11 Stable #>
	AdoptOpenJDK11jdk = Get-OpenSourceJDK -number 11 -release ga -OS windows -type jdk -jvm hotspot -ext
	AdoptOpenJDK11jre = Get-OpenSourceJDK -number 11 -release ga -OS windows -type jre -jvm hotspot -ext
	AdoptOpenJDK11openj9jdk = Get-OpenSourceJDK -number 11 -release ga -OS windows -type jdk -jvm openj9 -ext
	AdoptOpenJDK11openj9jre = Get-OpenSourceJDK -number 11 -release ga -OS windows -type jre -jvm openj9 -ext
	<# Version 12 Stable #>
	AdoptOpenJDK12jdk = Get-OpenSourceJDK -number 12 -release ga -OS windows -type jdk -jvm hotspot -ext
	AdoptOpenJDK12jre = Get-OpenSourceJDK -number 12 -release ga -OS windows -type jre -jvm hotspot -ext
	AdoptOpenJDK12openj9jdk = Get-OpenSourceJDK -number 12 -release ga -OS windows -type jdk -jvm openj9 -ext
	AdoptOpenJDK12openj9jre = Get-OpenSourceJDK -number 12 -release ga -OS windows -type jre -jvm openj9 -ext
	<# Version 13 Stable #>
	AdoptOpenJDK13jdk = Get-OpenSourceJDK -number 13 -release ga -OS windows -type jdk -jvm hotspot -ext
	AdoptOpenJDK13jre = Get-OpenSourceJDK -number 13 -release ga -OS windows -type jre -jvm hotspot -ext
	AdoptOpenJDK13openj9jdk = Get-OpenSourceJDK -number 13 -release ga -OS windows -type jdk -jvm openj9 -ext
	AdoptOpenJDK13openj9jre = Get-OpenSourceJDK -number 13 -release ga -OS windows -type jre -jvm openj9 -ext
	<# Version 14 Stable #>
	AdoptOpenJDK14jdk = Get-OpenSourceJDK -number 14 -release ga -OS windows -type jdk -jvm hotspot -ext
	AdoptOpenJDK14jre = Get-OpenSourceJDK -number 14 -release ga -OS windows -type jre -jvm hotspot -ext
	AdoptOpenJDK14openj9jdk = Get-OpenSourceJDK -number 14 -release ga -OS windows -type jdk -jvm openj9 -ext
	AdoptOpenJDK14openj9jre = Get-OpenSourceJDK -number 14 -release ga -OS windows -type jre -jvm openj9 -ext
	<# Version 8 Early Release #>
	# AdoptOpenJDK8jdk_nightly = Get-OpenSourceJDK -number 8 -release ea -OS windows -type jdk -jvm hotspot -ext
	# AdoptOpenJDK8jre_nightly = Get-OpenSourceJDK -number 8 -release ea -OS windows -type jre -jvm hotspot -ext
	# AdoptOpenJDK8openj9jdk_nightly = Get-OpenSourceJDK -number 8 -release ea -OS windows -type jdk -jvm openj9 -ext
	# AdoptOpenJDK8openj9jre_nightly = Get-OpenSourceJDK -number 8 -release ea -OS windows -type jre -jvm openj9 -ext
	<# Version 9 Early Release #>
	# AdoptOpenJDK9jdk_nightly = Get-OpenSourceJDK -number 9 -release ea -OS windows -type jdk -jvm hotspot -ext
	# AdoptOpenJDK9jre_nightly = Get-OpenSourceJDK -number 9 -release ea -OS windows -type jre -jvm hotspot -ext
	# AdoptOpenJDK9openj9jdk_nightly_nightly = Get-OpenSourceJDK -number 9 -release ea -OS windows -type jdk -jvm openj9 -ext
	# AdoptOpenJDK9openj9jre_nightly = Get-OpenSourceJDK -number 9 -release ea -OS windows -type jre -jvm openj9 -ext
	<# Version 10 Early Release #>
	# AdoptOpenJDK10jdk_nightly = Get-OpenSourceJDK -number 10 -release ea -OS windows -type jdk -jvm hotspot -ext
	# AdoptOpenJDK10jre_nightly = Get-OpenSourceJDK -number 10 -release ea -OS windows -type jre -jvm hotspot -ext
	# AdoptOpenJDK10openj9jdk_nightly = Get-OpenSourceJDK -number 10 -release ea -OS windows -type jdk -jvm openj9 -ext
	# AdoptOpenJDK10openj9jre_nightly = Get-OpenSourceJDK -number 10 -release ea -OS windows -type jre -jvm openj9 -ext
	<# Version 11 Early Release #>
	# AdoptOpenJDK11jdk_nightly = Get-OpenSourceJDK -number 11 -release ea -OS windows -type jdk -jvm hotspot -ext
	# AdoptOpenJDK11jre_nightly = Get-OpenSourceJDK -number 11 -release ea -OS windows -type jre -jvm hotspot -ext
	# AdoptOpenJDK11openj9jdk_nightly = Get-OpenSourceJDK -number 11 -release ea -OS windows -type jdk -jvm openj9 -ext
	# AdoptOpenJDK11openj9jre_nightly = Get-OpenSourceJDK -number 11 -release ea -OS windows -type jre -jvm openj9 -ext
	<# Version 12 Early Release #>
	# AdoptOpenJDK12jdk_nightly = Get-OpenSourceJDK -number 12 -release ea -OS windows -type jdk -jvm hotspot -ext
	# AdoptOpenJDK12jre_nightly = Get-OpenSourceJDK -number 12 -release ea -OS windows -type jre -jvm hotspot -ext
	# AdoptOpenJDK12openj9jdk_nightly = Get-OpenSourceJDK -number 12 -release ea -OS windows -type jdk -jvm openj9 -ext
	# AdoptOpenJDK12openj9jre_nightly = Get-OpenSourceJDK -number 12 -release ea -OS windows -type jre -jvm openj9 -ext
	<# Version 13 Early Release #>
	# AdoptOpenJDK13jdk_nightly = Get-OpenSourceJDK -number 13 -release ea -OS windows -type jdk -jvm hotspot -ext
	# AdoptOpenJDK13jre_nightly = Get-OpenSourceJDK -number 13 -release ea -OS windows -type jre -jvm hotspot -ext
	# AdoptOpenJDK13openj9jdk_nightly = Get-OpenSourceJDK -number 13 -release ea -OS windows -type jdk -jvm openj9 -ext
	# AdoptOpenJDK13openj9jre_nightly = Get-OpenSourceJDK -number 13 -release ea -OS windows -type jre -jvm openj9 -ext
	<# Version 14 Early Release #>
	# AdoptOpenJDK14jdk_nightly = Get-OpenSourceJDK -number 14 -release ea -OS windows -type jdk -jvm hotspot -ext
	# AdoptOpenJDK14jre_nightly = Get-OpenSourceJDK -number 14 -release ea -OS windows -type jre -jvm hotspot -ext
	# AdoptOpenJDK14openj9jdk_nightly = Get-OpenSourceJDK -number 14 -release ea -OS windows -type jdk -jvm openj9 -ext
	# AdoptOpenJDK14openj9jre_nightly = Get-OpenSourceJDK -number 14 -release ea -OS windows -type jre -jvm openj9 -ext
  }
	
  return @{ Streams = $streams }
 
}

update -ChecksumFor none -NoCheckUrl
