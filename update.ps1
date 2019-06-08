import-module au

$PreUrl = 'https://github.com'

function global:au_BeforeUpdate {
    cp "$PSScriptRoot\README.$($Latest.PackageName).md" "$PSScriptRoot\README.md" -Force
    Get-RemoteFiles -Purge -FileNameBase "$($Latest.PackageName)"
	Remove-Item ".\tools\*.zip" -Force # Removal of downloaded files
}

function global:au_SearchReplace {
	@{
    ".\tools\packageArgs.ps1" = @{
			"(?i)(^\s*PackageName\s*=\s*)('.*')" = "`$1'$($Latest.PackageName)'"
			"(?i)(^\s*url\s*=\s*)('.*')" = "`$1'$($Latest.URL32)'"
			"(?i)(^\s*url64bit\s*=\s*)('.*')"	= "`$1'$($Latest.URL64)'"
			"(?i)(^\s*Checksum\s*=\s*)('.*')" = "`$1'$($Latest.Checksum32)'"
			"(?i)(^\s*ChecksumType\s*=\s*)('.*')" = "`$1'$($Latest.ChecksumType32)'"
			"(?i)(^\s*Checksum64\s*=\s*)('.*')" = "`$1'$($Latest.Checksum64)'"
			"(?i)(^\s*ChecksumType64\s*=\s*)('.*')" = "`$1'$($Latest.ChecksumType64)'"
		}
    ".\adoptopenjdk.nuspec" = @{
			"(?i)(^\s*\<id\>).*(\<\/id\>)" = "`${1}$($Latest.PackageName)`${2}"
			"(?i)(^\s*\<title\>).*(\<\/title\>)" = "`${1}$($Latest.Title)`${2}"
		}
	}
}

function Get-AdoptOpenJDK {
param (
    [string]$number,
    [string]$type = 'jre',       # jdk or jre
    [string]$build = 'releases', # nightly for pre-releases
    [string]$jvm = 'hotspot'
)

    $regex_1 = "(\d{4}\-\d{2}\-\d{2}\-\d{2}\-\d{2})"
    $regex_2 = "(OpenJDK(\d{1,2}U|\d{1,2}\.\d\.)\-(jdk|jre)_x(64|86\-32)_([wndois]+)_([htosp]+|[openj9]+))_|(_[openj9]+\-.*)|(\.zip)"
    $releases = "https://api.adoptopenjdk.net/v2/info/${build}/openjdk${number}?openjdk_impl=${jvm}&os=windows&arch=x32&arch=x64&release=latest&type=${type}"
    $t =  try { 
    (Invoke-WebRequest -Uri $releases -ErrorAction Stop -UseBasicParsing).BaseResponse
    } catch [System.Net.WebException] { Write-Verbose "An exception was caught: $($_.Exception.Message)"; $_.Exception.Response }
    if ( $t.StatusCode -eq "OK" ) {    
    $download_page = Invoke-WebRequest -Uri $releases -UseBasicParsing | ConvertFrom-Json
    $urls = $download_page.binaries.binary_link | where { $_ -match "x64|x86"} | select -Last 6

    $url32 = $urls | where { $_ -match "x86"} | select -Last 1

    $url64 =  $urls | where { $_ -match "x64"} | select -Last 1
    
    } else { Write-Verbose "this is a bad request"; }

        if ($build -eq "nightly") {
        $fN = ($download_page.binaries.binary_name | Select -First 1 )
        $version = ( $fN -split "$regex_1" | select -Last 2 | Select -First 1 )
        } else {
        if ($number -eq 8) {
        $name = ( $download_page.binaries.binary_name ) | Select -First 1
        $name = ( $name ) -replace(".zip",'')
        $fN = ( $name )
            if ( $jvm -eq 'openj9' ) {
              $version = (( $fN -split "$regex_2" ) )
              $version = ( $version | Select -Last 3 )
              $version = $version -replace("(_[openj9]+(_|\-.*))",'')
              $version = ( $version ) -replace("(`r`n\s)",'G') | Select -First 1
            } else {
              $version = (( $fN -split "$regex_2" ) | Select -Last 1 )
            }
        $version = $version -replace('[u]','.0.') -replace('(b)','.')
        }
		    if (( $number -eq 9 ) -or ( $number -eq 10 ) -or ( $number -eq 11 )-or ( $number -eq 12 )) {
		    $version = if ($url64 -ne $null) { ( Get-Version (($url64) -replace('%2B','.')) ) }
		    }
        }

		$JavaVM = @{$true="${type}${number}";$false="${type}${number}-${jvm}"}[ ( $jvm -match "hotspot" ) ]
        $beta = @{$true="${version}";$false="${version}-${build}"}[ ($build -eq "releases") ]

    #build stream hashtable return
    $hotspot = @{}
        if ($url32 -ne $null) { $hotspot.Add( 'URL32', $url32 ) }
        if ($url64 -ne $null) { $hotspot.Add( 'URL64', $url64 ) }
        if ($version -ne $null) { $hotspot.Add( 'Version', "$beta" )
        $hotspot.Add( 'Title', "AdoptOpenJDK ${type}${number} ${jvm} ${version}" )
        $hotspot.Add( 'PackageName', "AdoptOpenJDK-${JavaVM}" ) }

    return ( $hotspot )
}


function global:au_GetLatest {
  $streams = [ordered] @{
    jre8_hotspot = Get-AdoptOpenJDK -number "8" -type "jre"
    jdk8_hotspot = Get-AdoptOpenJDK -number "8" -type "jdk"
    jre8_openj9 = Get-AdoptOpenJDK -number "8" -type "jre" -jvm "openj9"
    jdk8_openj9 = Get-AdoptOpenJDK -number "8" -type "jdk" -jvm "openj9"
    jre9_hotspot = Get-AdoptOpenJDK -number "9" -type "jre"
    jdk9_hotspot = Get-AdoptOpenJDK -number "9" -type "jdk"
    # jre9_openj9 = Get-AdoptOpenJDK -number "9" -type "jre" -jvm "openj9"       # Package not yet available
    jdk9_openj9 = Get-AdoptOpenJDK -number "9" -type "jdk" -jvm "openj9"
    # jre10_hotspot = Get-AdoptOpenJDK -number "10" -type "jre"                  # Package not yet available
    jdk10_hotspot = Get-AdoptOpenJDK -number "10" -type "jdk"
    # jre10_openj9 = Get-AdoptOpenJDK -number "10" -type "jre" -jvm "openj9"     # Package not yet available
    jdk10_openj9 = Get-AdoptOpenJDK -number "10" -type "jdk" -jvm "openj9"
    jre11_hotspot = Get-AdoptOpenJDK -number "11" -type "jre"
    jdk11_hotspot = Get-AdoptOpenJDK -number "11" -type "jdk"
    jre11openj9 = Get-AdoptOpenJDK -number "11" -type "jre" -jvm "openj9"
    jdk11openj9 = Get-AdoptOpenJDK -number "11" -type "jdk" -jvm "openj9"
    jre12_hotspot = Get-AdoptOpenJDK -number "12" -type "jre"
    jdk12_hotspot = Get-AdoptOpenJDK -number "12" -type "jdk"
    jre12_openj9 = Get-AdoptOpenJDK -number "12" -type "jre" -jvm "openj9"
    jdk12_openj9 = Get-AdoptOpenJDK -number "12" -type "jdk" -jvm "openj9"
  }

  return @{ Streams = $streams }
 
}

update -ChecksumFor none
