param($installPath, $toolsPath, $package)

if (Get-Module Auth10) {
	Remove-Module Auth10
}

Import-Module (Join-Path $toolsPath Auth10.psm1)