import-module au

$PreUrl = 'https://github.com'

function global:au_BeforeUpdate {
    Get-RemoteFiles -Purge -FileNameBase "$($Latest.PackageName)"
    Remove-Item ".\tools\*.*" -Force # Removal of all files
	Copy-Item chocolateyinstall.ps1 -Destination tools
}

function global:au_SearchReplace {
    @{
        ".\tools\chocolateyinstall.ps1" = @{
            "(?i)(^\s*PackageName\s*=\s*)('.*')"    = "`$1'$($Latest.PackageName)'"
            "(?i)(^\s*url\s*=\s*)('.*')"            = "`$1'$($Latest.URL32)'"
            "(?i)(^\s*url64bit\s*=\s*)('.*')"       = "`$1'$($Latest.URL64)'"
            "(?i)(^\s*Checksum\s*=\s*)('.*')"       = "`$1'$($Latest.Checksum32)'"
            "(?i)(^\s*ChecksumType\s*=\s*)('.*')"   = "`$1'$($Latest.ChecksumType32)'"
            "(?i)(^\s*Checksum64\s*=\s*)('.*')"     = "`$1'$($Latest.Checksum64)'"
            "(?i)(^\s*ChecksumType64\s*=\s*)('.*')" = "`$1'$($Latest.ChecksumType64)'"
        }
        ".\adoptopenjdk.nuspec"   = @{
            "(?i)(^\s*\<id\>).*(\<\/id\>)"                 = "`${1}$($($Latest.PackageName).ToLower())`${2}"
            "(?i)(^\s*\<title\>).*(\<\/title\>)"           = "`${1}$($Latest.Title)`${2}"
            "(?i)(^\s*\<licenseUrl\>).*(\<\/licenseUrl\>)" = "`${1}$($Latest.LicenseUrl)`${2}"
        }
    }
}

function Get-AdoptOpenJDK {
    param (
        [string]$number, # java version
        [string]$type = 'jre', # jdk or jre
        [string]$build = 'releases', # nightly for pre-releases
        [string]$jvm = 'hotspot', # hotspot or openj9
        [string]$dev_name            # orginal package name
    )

    $regex_1 = "(\d{4}\-\d{2}\-\d{2}\-\d{2}\-\d{2})"
    $regex_2 = "(OpenJDK(\d{1,2}U|\d{1,2}\.\d\.)\-(jdk|jre)_x(64|86\-32)_([wndois]+)_([htosp]+|[openj9]+))_|(_[openj9]+\-.*)|(\.msi)"
    $releases = "https://api.adoptopenjdk.net/v2/info/${build}/openjdk${number}?openjdk_impl=${jvm}&os=windows&arch=x32&arch=x64&release=latest&type=${type}"
    $t = try { 
        (Invoke-WebRequest -Uri $releases -ErrorAction Stop -UseBasicParsing).BaseResponse
    }
    catch [System.Net.WebException] { Write-Verbose "An exception was caught: $($_.Exception.Message)"; $_.Exception.Response }
    if ( $t.StatusCode -eq "OK" ) {    
        $download_page = Invoke-WebRequest -Uri $releases -UseBasicParsing | ConvertFrom-Json
        $urls = $download_page.binaries.installer_link | where { $_ -match "x64|x86" } | select -Last 6

        $url32 = $urls | where { $_ -match "x86" } | select -Last 1

        $url64 = $urls | where { $_ -match "x64" } | select -Last 1
    
    }
    else { Write-Verbose "this is a bad request"; break; }

    if ($build -eq "nightly") {
        $fN = ($download_page.binaries.installer_name | Select -First 1 )
        $version = ( $fN -split "$regex_1" | select -Last 2 | Select -First 1 )
    }
    else {
        if ($number -eq 8) {
            $name = ( $download_page.binaries.installer_name ) | Select -First 1
            $name = ( $name ) -replace (".msi", '')
            $fN = ( $name )
            if ( $jvm -eq 'openj9' ) {
                $version = (( $fN -split "$regex_2" ) )
                $version = ( $version | Select -Last 3 )
                $version = $version -replace ("(_[openj9]+(_|\-.*))", '')
                $version = ( $version ) -replace ("(`r`n\s)", 'G') | Select -First 1
            }
            else {
                $version = (( $fN -split "$regex_2" ) | Select -Last 1 )
            }
            $version = $version -replace ('[u]', '.0.') -replace ('(b)', '.')
        }
        else {
            $version = if ($url64 -ne $null) { ( Get-Version (($url64) -replace ('%2B', '.')) ) }
        }
    }

    $version = $version -replace ("\-", "."); if ($version -ne $null) { $version = ( Get-Version "${version}" ) }

    $JavaVM = @{$true = "${type}${number}"; $false = "${type}${number}-${jvm}" }[ ( $jvm -match "hotspot" ) ]
    $beta = @{$true = "${version}"; $false = "${version}-${build}" }[ ( $build -eq "releases" ) ]
    $PackageName = @{$true = "AdoptOpenJDK-${JavaVM}"; $false = "${dev_name}" }[ ( $dev_name -eq "" ) ]

    #build stream hashtable return
    $hotspot = @{ }
    if ($url32 -ne $null) { $hotspot.Add( 'URL32', $url32 ) }
    if ($url64 -ne $null) { $hotspot.Add( 'URL64', $url64 ) }
    if ($version -ne $null) {
        $hotspot.Add( 'Version', "$beta" )
        $hotspot.Add( 'Title', "AdoptOpenJDK ${type}${number} ${jvm} ${version}" )
        $hotspot.Add( 'PackageName', "${PackageName}" )
        $hotspot.Add( 'LicenseUrl', "https://github.com/AdoptOpenJDK/openjdk-jdk${number}u/blob/master/LICENSE" )
    }

    return ( $hotspot )
}


function global:au_GetLatest {
	# Skip 9 and 10 as they don't have MSI's
    $numbers = @("8", "11", "12", "13"); $types = @("jre", "jdk")
    # Optionally add "nightly" to $builds
    $jvms = @("hotspot", "openj9"); $builds = @("releases")
	
    $streams = [ordered] @{ }
    foreach ( $number in $numbers ) {
        foreach ( $type in $types) {
            foreach ( $jvm in $jvms ) {
                foreach ( $build in $builds ) {        
                    # Create a package without the version for the latest release
                    if ( $number -eq $numbers[-1] ) { 
                        $name = "AdoptOpenJDK"
                        if ($jvm -eq "openj9") {
                            $name = $name + $jvm
                        }
                        if ($type -eq "jre") {
                            $name = $name + $type
                        } 
                        $streams.Add( "$($type)$($number)_$($jvm)_$($build)_Latest" , ( Get-AdoptOpenJDK -number $number -type $type -jvm $jvm -build $build -dev_name $name ) )
                    } 

                    $name = "AdoptOpenJDK$number"
                    if ($jvm -eq "openj9") {
                        $name = $name + $jvm
                    }
                    if ($type -eq "jre") {
                        $name = $name + $type
                    }

                    $streams.Add( "$($type)$($number)_$($jvm)_$($build)" , ( Get-AdoptOpenJDK -number $number -type $type -jvm $jvm -build $build -dev_name $name ) )        
                }
            }
        }
    }
    return @{ Streams = $streams } 
}

update -ChecksumFor none
