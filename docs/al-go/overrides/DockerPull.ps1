# A BCDock build has no local container, so there is no image to pull.
Param([string] $imageName)
Write-Host "BCDock: no local container; not pulling $imageName"
