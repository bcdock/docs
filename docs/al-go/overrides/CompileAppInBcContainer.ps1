# AL-Go "compile an app in the container" -> compile against this build's BCDock env, so the
# runner downloads no BC artifacts. Microsoft's symbols come from the env (bcdock env download-symbols),
# the build's own earlier apps are already in AL-Go's symbols folder, and the compiler is the env's own
# (bcdock al compile --env). Returns the .app path, as Compile-AppInBcContainer does.
Param([Hashtable] $parameters)
# Optional keys are read with $parameters['key']: Run-AlPipeline omits some (failOn for test apps),
# and under strict mode a missing key read with a dot throws.
. (Join-Path $PSScriptRoot '_bcdock.ps1')
$buildEnv = Get-BuildEnv
$project = $parameters.appProjectFolder
$symbols = $parameters.appSymbolsFolder
New-Item -ItemType Directory -Force $symbols, $parameters.appOutputFolder | Out-Null
$appJson = Get-Content (Join-Path $project 'app.json') -Raw | ConvertFrom-Json
Write-BcDockBanner "compile $($appJson.name) against $($buildEnv.name)"

# Symbols from the env for Microsoft's apps only. The build's own apps (a test app's dependency on the
# app built just before it) are not in the env yet; AL-Go has copied them into the symbols folder.
$deps = @()
if ($appJson.PSObject.Properties['dependencies']) { $deps = @($appJson.dependencies | Where-Object { $_.publisher -eq 'Microsoft' }) }
$symbolsJson = Join-Path ([IO.Path]::GetTempPath()) "bcdock-symbols-$([guid]::NewGuid()).json"
$selection = [ordered]@{ dependencies = $deps }
foreach ($k in 'application', 'platform') { if ($appJson.PSObject.Properties[$k]) { $selection[$k] = $appJson.$k } }
ConvertTo-Json -InputObject $selection -Depth 5 | Set-Content $symbolsJson
Write-Host "Downloading Microsoft symbols for $($appJson.name) from $($buildEnv.name)"
Invoke-BcDock env download-symbols $buildEnv.id --app-json $symbolsJson --out-dir $symbols | Out-Host

# The alc options BcContainerHelper's compile passes.
$alcArgs = @()
foreach ($k in 'sourceRepositoryUrl', 'sourceCommit', 'buildBy', 'buildUrl') {
    if ($parameters[$k]) { $alcArgs += "/$($k.Substring(0,1).ToUpperInvariant())$($k.Substring(1)):$($parameters[$k])" }
}
if ($parameters['features']) { $alcArgs += "/features:$(@($parameters['features']) -join ',')" }
foreach ($s in @($parameters['preProcessorSymbols'])) { if ($s) { $alcArgs += "/D:$s" } }
foreach ($cop in 'EnableCodeCop', 'EnableAppSourceCop', 'EnablePerTenantExtensionCop', 'EnableUICop') {
    if ($parameters[$cop]) { Write-Host "::warning::BCDock: $cop is not applied yet when compiling against a BCDock env" }
}

$appFile = Join-Path $parameters.appOutputFolder "$($appJson.publisher)_$($appJson.name)_$($appJson.version).app"
Write-Host "Compiling $($appJson.name) with $($buildEnv.name)'s compiler"
$raw = @(& bcdock al compile --env $buildEnv.id --project $project --package-cache $symbols --out $appFile -- @alcArgs 2>&1 | ForEach-Object { "$_" })
$code = $LASTEXITCODE

# Into the build log and BuildOutput.txt through AL-Go's OutputTo, with failOn applied as AL-Go does.
$gha = [bool]$parameters['GitHubActions']
$formatted = Format-AlcOutput -Lines $raw -GitHubActions $gha -BasePath ([string]$env:GITHUB_WORKSPACE)
$sink = $parameters['OutputTo']
# (.Invoke returns a collection: discard it, or it would join the .app path this script returns.)
foreach ($line in $formatted.Lines) { if ($sink) { $null = $sink.Invoke($line) } else { Write-Host $line } }
$failOn = if ($parameters['failOn']) { [string]$parameters['failOn'] } else { 'error' }
if ($code -ne 0 -or -not (Test-Path $appFile)) { throw "App generation failed (bcdock al compile exit $code)" }
if ($failOn -eq 'error' -and $formatted.Errors -gt 0) { throw "App generation failed: $($formatted.Errors) error(s)" }
if ($failOn -eq 'warning' -and ($formatted.Errors + $formatted.Warnings) -gt 0) { throw "App generation failed: $($formatted.Warnings) warning(s) with failOn warning" }

if ($parameters['CopyAppToSymbolsFolder']) { Copy-Item $appFile $symbols -Force }
Write-Host "$appFile successfully created"
return $appFile
