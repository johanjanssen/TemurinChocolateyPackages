
<# Bol Updating of hashtable to string for ToString method #>
Update-TypeData -TypeName System.Collections.HashTable `
    -MemberType ScriptMethod `
    -MemberName ToString `
    -Value { $keys = $this.keys; foreach ($key in $keys) { $v = $this[$key]; 
             if ($key -match "\s") { $hashstr += "`"$key`"" + "=" + "`"$v`"" + ";" }
             else { $hashstr += $key + "=" + "`"$v`"" + ";" } };
             return $hashstr }
<# Eol Updating of hashtable to string for ToString method #>

function Test-PackageParamaters {
[CmdletBinding()]
param(
    [hashtable]$pp
)
$New_pp = @{}; $toolsDir = "${env:ProgramFiles}\AdoptOpenJDK"
	if ([string]::IsNullOrEmpty($pp.quiet)) {
		$New_pp.add( "/quiet", $true )
	}
	if (![string]::IsNullOrEmpty($pp.transforms)) {
		$New_pp.add( "/transforms", $pp.transforms )
	}
    if (![string]::IsNullOrEmpty($pp.INSTALLDIR) -and (($New_pp.ADDLOCAL -match "FeatureMain") -or ($pp.ADDLOCAL -match "FeatureMain")) -and ([string]::IsNullOrEmpty($pp.INSTALLLEVEL)) ) {
	    Write-Warning "You must use INSTALLDIR with FeatureMain."
        Write-Warning "Using provided $($pp.INSTALLDIR)"
        $New_pp.add( "/InstallDir", $pp.INSTALLDIR )
    } elseif ([string]::IsNullOrEmpty($pp.INSTALLDIR) -and (($New_pp.ADDLOCAL -match "FeatureMain") -or ($pp.ADDLOCAL -match "FeatureMain")) -and ([string]::IsNullOrEmpty($pp.INSTALLLEVEL)) ) { 
	    Write-Warning "Using Default of $toolsDir"
	    $New_pp.add( "/InstallDir", "$toolsDir" )
    }
	if ((![string]::IsNullOrEmpty($pp.ADDLOCAL)) -and ([string]::IsNullOrEmpty($pp.INSTALLLEVEL)) ) {
        Write-Warning "Using Addlocal"
        $addlocalArray = ($pp.ADDLOCAL -split "\,")
        foreach ( $_ in $addlocalArray)  {
	        switch -Wildcard ($_) {
                "FeatureMain" {
                    $pp_addlocal_array += -join ("FeatureMain", ",")
                }
                "FeatureEnvironment" {
                    $pp_addlocal_array += -join ("FeatureEnvironment", ",")
                }
                "FeatureJarFileRunWith" {
                    $pp_addlocal_array += -join ("FeatureJarFileRunWith", ",")
                }
                "FeatureJavaHome" {
                    $pp_addlocal_array += -join ("FeatureJavaHome", ",")
                }
                "FeatureIcedTeaWeb" {
                    $pp_addlocal_array += -join ("FeatureIcedTeaWeb", ",")
                }
                "FeatureJNLPFileRunWith" {
                    $pp_addlocal_array += -join ("FeatureJNLPFileRunWith", ",")
                }
            }
        }
        Write-Warning "No InstallLevel detected. Defaulting to AddLocal"
	    $New_pp.add( "/ADDLOCAL", ($pp_addlocal_array -replace ".{1}$") )

	}
	if (![string]::IsNullOrEmpty($pp.INSTALLLEVEL) ) {
		$New_pp.add( "INSTALLLEVEL", $pp.INSTALLLEVEL )
	}

return $New_pp
}
