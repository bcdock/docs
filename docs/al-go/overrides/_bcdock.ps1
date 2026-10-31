# Shared setup dot-sourced by every BCDock override. Loads the helpers, finds the bcdock CLI and
# altool, and reads back the env this build created. BCDOCK_TOKEN must be in the job's environment.
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'bcdock/BCDock.AlGo.psm1') -Force

# The BCDock API key: AL-Go's ReadSecrets puts the requested secrets in $env:Secrets as JSON, each value
# base64-encoded. BCDOCK_TOKEN must be in the build job's secrets list (see the BCDock AL-Go guide).
if (-not $env:BCDOCK_TOKEN -and $env:Secrets) {
    $all = $env:Secrets | ConvertFrom-Json
    if ($all.PSObject.Properties['BCDOCK_TOKEN'] -and $all.BCDOCK_TOKEN) {
        $env:BCDOCK_TOKEN = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($all.BCDOCK_TOKEN))
        if ($env:GITHUB_ACTIONS) { Write-Host "::add-mask::$($env:BCDOCK_TOKEN)" }
    }
}
if (-not $env:BCDOCK_TOKEN) { throw 'BCDOCK_TOKEN is not set: add the BCDock API key as a repo secret named BCDOCK_TOKEN and include it in the build job''s secrets.' }

# Tools on a fresh ubuntu runner: the bcdock CLI from npm, and dotnet global tools (altool, command 'al') on PATH.
$dotnetTools = Join-Path $HOME '.dotnet/tools'
if (($env:PATH -split [IO.Path]::PathSeparator) -notcontains $dotnetTools) { $env:PATH = "$dotnetTools$([IO.Path]::PathSeparator)$env:PATH" }
# 0.5.10 or later: it accepts --version 28.5 (major.minor), and since 0.5.9 a wait retries a passing failure itself.
function Test-BcDockCliCurrent {
    if (-not (Get-Command bcdock -ErrorAction SilentlyContinue)) { return $false }
    $v = "$(& bcdock --version 2>$null)" -replace '^.*version\s+', ''
    $parsed = $null
    return ([Version]::TryParse(($v -split '[-+ ]')[0], [ref]$parsed) -and $parsed -ge [Version]'0.5.10')
}
if (-not (Test-BcDockCliCurrent)) {
    npm install --global --silent @bcdock/cli | Out-Host
    if (-not (Test-BcDockCliCurrent)) { throw 'Could not install bcdock CLI 0.5.10 or later (npm install -g @bcdock/cli).' }
}

function Invoke-BcDock {
    param([Parameter(ValueFromRemainingArguments)][string[]] $Arguments)
    $out = & bcdock @Arguments
    if ($LASTEXITCODE -ne 0) { throw "bcdock $($Arguments -join ' ') failed (exit $LASTEXITCODE)" }
    return $out
}

function Get-BuildEnv {
    $file = Get-BcDockStateFile
    if (-not (Test-Path $file)) { throw "No BCDock env recorded for this build ($file): NewBcContainer did not run." }
    return Get-Content $file -Raw | ConvertFrom-Json
}

# altool connection to the env's dev endpoint. BCDock envs are multi-tenant: --tenant default is
# required (without it publish fails and the test hub answers 401).
function Get-AlToolConnectionArgs {
    param([Parameter(Mandatory)] $BuildEnv)
    $dev = [Uri]$BuildEnv.devEndpointUrl
    $creds = Invoke-BcDock env credentials $BuildEnv.id --output json | ConvertFrom-Json
    if ($env:GITHUB_ACTIONS -and $creds.password) { Write-Host "::add-mask::$($creds.password)" }
    $env:BC_SERVER_USERNAME = if ($creds.username) { $creds.username } else { 'admin' }
    $env:BC_SERVER_PASSWORD = $creds.password
    return @('--server', "$($dev.Scheme)://$($dev.Host)", '--serverinstance', $dev.Segments[1].TrimEnd('/'),
             '--port', [string]$dev.Port, '--authentication', 'UserPassword', '--tenant', 'default',
             '--environmenttype', $(if ($BuildEnv.type -eq 'onprem') { 'OnPrem' } else { 'Sandbox' }))
}

function Invoke-AlTool {
    param([Parameter(ValueFromRemainingArguments)][string[]] $Arguments)
    # The NuGet package's command is 'al', though its help calls itself altool.
    & al @Arguments
}
