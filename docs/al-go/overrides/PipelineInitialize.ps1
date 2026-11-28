# BCDock: two settings of Run-AlPipeline's own (the caller's scope), because AL-Go offers no override for
# either.
#
# Before creating the build container, Run-AlPipeline looks up the best generic image for the
# host OS, and that lookup is Windows-only (Get-CimInstance, HKLM). A BCDock build has no local
# container, so name the image up front: Run-AlPipeline then skips the lookup, and DockerPull.ps1
# skips the pull.
#
# Compile against the BCDock env, not a compiler folder. useCompilerFolder stays TRUE in
# settings.json, because only then does AL-Go skip downloading the BC artifacts (about 2 GB, 11 min on a
# runner) just to check the artifact setting (RunPipeline.ps1 passes doNotCheckArtifactSetting only with
# it). Here Run-AlPipeline is told to compile "in the container" instead, which goes through
# CompileAppInBcContainer.ps1 and so through the env. This runs before Run-AlPipeline first reads it.
foreach ($setting in @(@{ Name = 'useGenericImage'; Value = 'bcdock-no-local-container'; Only = 'empty' },
                       @{ Name = 'useCompilerFolder'; Value = $false; Only = 'always' })) {
    if (-not (Get-Variable -Name $setting.Name -Scope 1 -ErrorAction SilentlyContinue)) {
        throw "BCDock: Run-AlPipeline has no $($setting.Name) here; this BcContainerHelper version is not supported by the BCDock overrides."
    }
    if ($setting.Only -eq 'always' -or -not (Get-Variable -Name $setting.Name -Scope 1 -ValueOnly)) {
        Set-Variable -Name $setting.Name -Scope 1 -Value $setting.Value
    }
}
Write-Host "BCDock: no local container image; compiling against the BCDock env"
