param($installPath, $toolsPath, $package, $project)

# find the Web.config file
$config = $project.ProjectItems | where {$_.Name -eq "Web.config"}

# find its path on the file system
$localPath = $config.Properties | where {$_.Name -eq "LocalPath"}

[io.file]::readalltext($localPath.Value) -replace "(?s)<!--(<authentication.+?</authentication>)-->", "$+" | set-content $localPath.Value
