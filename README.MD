# Chocolatey packages
This repo contains the source for the Temurin Chocolatey packages

# Changing the packages
* Install AU
* Run update.ps1

# Test the packages
* (as administrator): choco install [packageName] -dv -s .

# Uploading the packages
* Run pushpackages.ps1

# New Major Java release
* Update 'Temurin/update.ps1' and add the Java version number in two places. Simply search for the previous version and add it to the array.
  * https://github.com/johanjanssen/TemurinChocolateyPackages/blob/master/Temurin/update.ps1#L62
  * https://github.com/johanjanssen/TemurinChocolateyPackages/blob/master/Temurin/update.ps1#L149
* Run the 'Update Temurin Packages' GitHub action

# New Minor Java release
* Run the 'Update Temurin Packages' GitHub action
