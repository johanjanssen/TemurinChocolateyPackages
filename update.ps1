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
			"(?i)(^\s*SoftwareName\s*=\s*)('.*')" = "`$1'$($Latest.Title)'"
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
    [string]$build,
	[string]$jvm = 'hotspot'
)

	# write-host "P number -$number- build -$build- jvm -$jvm-"

    $releases = "${PreUrl}/AdoptOpenJDK/openjdk${number}-binaries/releases"
    $download_page = Invoke-WebRequest -Uri $releases -UseBasicParsing
    $url32  = $download_page.links | ? { $_.href -match "(.+)${build}_x86(.+)${jvm}(.+)\.zip$" } | select -First 1 -expand href
    $url64  = $download_page.links | ? { $_.href -match "(.+)${build}_x64(.+)${jvm}(.+)\.zip$" } | select -First 1 -expand href 

    if ($url32 -match '(\du)(\d+){3}(b)(\d+){2,3}') {
    $version = ( $Matches[0] ) -replace('[u]','.0.') -replace('(b)','.')
    }
    # write-host "A number -$number-"
    if (( $number -eq 9 )) {
    # write-host "B number -$number-"
    $url64 -match '(\d+_\d+)' | Out-Null
    $version = ( $Matches[0] ) -replace('_','.0.')
    } 
    if (( $number -eq 10 )) {
    # write-host "C number -$number-"
    $version = ( Get-Version (($url64) -replace('%2B','.')) )
    }
    if (( $number -eq 11 )-or ( $number -eq 12 )) {
    # write-host "D number -$number-"
    $version = ( Get-Version (($url64) -replace('-','.')) )
    }
    # write-host "E jvm -$jvm-"
    $JavaVM = @{$true="${build}${number}";$false="${build}${number}-${jvm}"}[ ( $jvm -match "hotspot" ) ]
    # write-host "F JavaVM -$JavaVM-"
    # write-host "Z version -$version-"

    #build stream hashtable return
    if (( $url32 -ne $null) -or ($url64 -ne $null )){
    $hotspot = @{}
        if ($url32 -ne $null) { $hotspot.Add( 'URL32', $PreUrl + $url32 ) }
        if ($url64 -ne $null) { $hotspot.Add( 'URL64', $PreUrl + $url64 ) }
        $hotspot.Add( 'Version', $version )
        $hotspot.Add( 'Title', "AdoptOpenJDK ${jvm} ${build}${number} ${version}" )
		write-host "H PackageName -AdoptOpenJDK-${JavaVM}${number}-"
        $hotspot.Add( 'PackageName', "AdoptOpenJDK-${JavaVM}" )
    }

    return ( $hotspot )
}


function global:au_GetLatest {
  $streams = [ordered] @{
    jre8_hotspot = Get-AdoptOpenJDK -number "8" -build "jre"
    jdk8_hotspot = Get-AdoptOpenJDK -number "8" -build "jdk"
    jre8_openj9 = Get-AdoptOpenJDK -number "8" -build "jre" -jvm "openj9"
    jdk8_openj9 = Get-AdoptOpenJDK -number "8" -build "jdk" -jvm "openj9"
    jre9_hotspot = Get-AdoptOpenJDK -number "9" -build "jre"
    jdk9_hotspot = Get-AdoptOpenJDK -number "9" -build "jdk"
    # jre9_openj9 = Get-AdoptOpenJDK -number "9" -build "jre" -jvm "openj9"
    # jdk9_openj9 = Get-AdoptOpenJDK -number "9" -build "jdk" -jvm "openj9"
    jre10_hotspot = Get-AdoptOpenJDK -number "10" -build "jre"
    jdk10_hotspot = Get-AdoptOpenJDK -number "10" -build "jdk"
    # jre10_openj9 = Get-AdoptOpenJDK -number "9" -build "jre" -jvm "openj9"
    # jdk10_openj9 = Get-AdoptOpenJDK -number "9" -build "jdk" -jvm "openj9"
    jre11_hotspot = Get-AdoptOpenJDK -number "11" -build "jre"
    jdk11_hotspot = Get-AdoptOpenJDK -number "11" -build "jdk"
    jre11openj9 = Get-AdoptOpenJDK -number "11" -build "jre" -jvm "openj9"
    jdk11openj9 = Get-AdoptOpenJDK -number "11" -build "jdk" -jvm "openj9"
    jre12_hotspot = Get-AdoptOpenJDK -number "12" -build "jre"
    jdk12_hotspot = Get-AdoptOpenJDK -number "12" -build "jdk"
    jre12_openj9 = Get-AdoptOpenJDK -number "12" -build "jre" -jvm "openj9"
    jdk12_openj9 = Get-AdoptOpenJDK -number "12" -build "jdk" -jvm "openj9"
  }

  return @{ Streams = $streams }
 
}

update -ChecksumFor none
