# AL-Go "install the dependencies the container lacks". Run-AlPipeline lists them as
# "<appId>:<Publisher>_<Name>_<Version>.app". A BCDock env already has Microsoft's apps for its BC
# version (published, and installed with the app that needs them), so those need nothing. Any other
# dependency would have to come from a feed or AppSource, which the BCDock overrides do not do yet:
# fail with its name rather than build against a dependency that is not there.
# (Without this override AL-Go supplies its own, which calls BcContainerHelper's Get-BcContainerAppInfo
# on a docker container and fails on a BCDock env.)
Param([Hashtable] $parameters)
$others = @()
foreach ($dependency in @($parameters['missingDependencies'])) {
    if (-not $dependency) { continue }
    $appFile = ($dependency -split ':', 2)[-1]
    if ($appFile -like 'Microsoft_*') {
        Write-Host "BCDock: $appFile is part of the env's BC version; nothing to install"
    }
    else {
        $others += $appFile
    }
}
if ($others) {
    throw "BCDock: these dependencies are not in the env and cannot be installed by the BCDock overrides yet: $($others -join ', ')"
}
