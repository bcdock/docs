# AL-Go "publish an app to the container" -> altool publishapp against the BCDock env.
Param([Hashtable] $parameters)
. (Join-Path $PSScriptRoot '_bcdock.ps1')
$buildEnv = Get-BuildEnv
$conn = Get-AlToolConnectionArgs $buildEnv
Write-BcDockBanner "publish to $($buildEnv.name)"
foreach ($app in @($parameters.appFile)) {
    # AL-Go also hands over Microsoft's test toolkit apps from the BC artifact. A BCDock env already has
    # Microsoft's apps for its BC version, and BC refuses to publish one again ("already deployed as a
    # global application"), so they are skipped.
    $manifest = Get-AppManifest -AppFile $app
    if ($manifest.Publisher -eq 'Microsoft') {
        Write-Host "Skipping $($manifest.Name) $($manifest.Version) by Microsoft: the env already has it"
        continue
    }
    Write-Host "Publishing $app to $($buildEnv.name)"
    Invoke-AlTool publishapp $app @conn | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "altool publishapp failed for $app (exit $LASTEXITCODE)" }
    Add-BcDockPublishedApp -Manifest $manifest
}
