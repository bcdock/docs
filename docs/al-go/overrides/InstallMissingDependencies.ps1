# AL-Go "install the dependencies the container lacks". Run-AlPipeline lists them as
# "<appId>:<Publisher>_<Name>_<Version>.app". A BCDock env already has Microsoft's apps for its BC
# version (published, and installed with the app that needs them), so those need nothing. Any other
# dependency, and every non-Microsoft app it depends on, comes from the NuGet feeds the repo trusts in its
# AL-Go settings (TrustedNuGetFeeds), anonymous feeds only. They are all resolved first: if a feed lacks
# one, the build stops naming it before anything is published. Then each is published to this build's env
# in dependency order, and copied to the symbols folder the compile step reads.
# (Without this override AL-Go supplies its own, which calls BcContainerHelper's Get-BcContainerAppInfo
# on a docker container and fails on a BCDock env.)
Param([Hashtable] $parameters)
$others = @()
foreach ($dependency in @($parameters['missingDependencies'])) {
    if (-not $dependency) { continue }
    $appId, $appFile = $dependency -split ':', 2
    if ($appFile -like 'Microsoft_*') {
        Write-Host "BCDock: $appFile is part of the env's BC version; nothing to install"
        continue
    }
    # <Publisher>_<Name>_<Version>.app: the version is after the last underscore.
    $base = [IO.Path]::GetFileNameWithoutExtension($appFile)
    $others += [pscustomobject]@{ AppId = $appId; Name = $base; MinVersion = [Version]($base.Substring($base.LastIndexOf('_') + 1)) }
}
if (-not $others) { return }

. (Join-Path $PSScriptRoot '_bcdock.ps1')
$buildEnv = Get-BuildEnv
Write-BcDockBanner "install dependencies into $($buildEnv.name)"

# The repo's feeds, as AL-Go hands them to BcContainerHelper. A feed with a token is not used yet.
$config = Get-Variable -Name bcContainerHelperConfig -ValueOnly -ErrorAction SilentlyContinue
$configured = @()
if ($config -and $config.ContainsKey('TrustedNuGetFeeds')) { $configured = @($config.TrustedNuGetFeeds) }
$feeds = @()
foreach ($f in $configured) {
    $hasToken = $f.PSObject.Properties['Token'] -and $f.Token
    if ($hasToken) { Write-Host "BCDock: skipping NuGet feed $($f.url): feeds that need a token are not supported by the BCDock overrides yet"; continue }
    try { $feeds += Get-BcDockNuGetFeed -Url $f.url }
    catch { Write-Host "BCDock: cannot read NuGet feed $($f.url): $($_.Exception.Message)" }
}
Write-Host "BCDock: looking for $(($others | ForEach-Object { $_.Name }) -join ', ') in $($feeds.Count) NuGet feed(s): $(($feeds | ForEach-Object { $_.Url }) -join ', ')"

$envInfo = Invoke-BcDock env get $buildEnv.id --output json | ConvertFrom-Json
$plan = Resolve-BcDockNuGetApps -Feeds $feeds -Dependencies $others -EnvVersion ([Version]$envInfo.bcVersion)
Write-Host "BCDock: publishing $($plan.Count) app(s) in dependency order:"
$plan | ForEach-Object { Write-Host "  $($_.PackageId) $($_.Version)" }

$work = Join-Path ([IO.Path]::GetTempPath()) "bcdock-deps-$([guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Force $work | Out-Null
try {
    foreach ($package in $plan) {
        $app = Save-BcDockNuGetApp -Package $package -Folder $work
        Write-Host "Publishing $([IO.Path]::GetFileName($app)) to $($buildEnv.name)"
        Invoke-BcDock env publish $buildEnv.id $app --tenant default | Out-Host
        Add-BcDockPublishedApp -Manifest (Get-AppManifest -AppFile $app)
        foreach ($k in 'appSymbolsFolder', 'CopyInstalledAppsToFolder') {
            if ($parameters[$k]) { New-Item -ItemType Directory -Force $parameters[$k] | Out-Null; Copy-Item $app $parameters[$k] -Force }
        }
    }
}
finally { Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue }
