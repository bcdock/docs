# Helpers shared by the BCDock .AL-Go override scripts. AL-Go for GitHub runs on a free
# ubuntu runner with no Docker: the BC "container" is a BCDock environment, created with the
# bcdock CLI and driven with Microsoft's altool (publish + remote tests). Supported: BC 28+.

Set-StrictMode -Version 3.0
# Windows PowerShell 5.1 does not preload the zip types used by Get-AppTestCodeunitIds.
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem

# Where the env created for this build is remembered between override calls.
function Get-BcDockStateFile {
    $dir = if ($env:RUNNER_TEMP) { $env:RUNNER_TEMP } else { [System.IO.Path]::GetTempPath() }
    return Join-Path $dir 'bcdock-algo-env.json'
}

# Parse an AL-Go artifact URL (.../{sandbox|onprem}/{version}/{country}) into what env create needs.
function ConvertFrom-ArtifactUrl {
    param([Parameter(Mandatory)][string] $ArtifactUrl)
    $path = ([Uri]($ArtifactUrl.Split('?')[0])).AbsolutePath.Trim('/').Split('/')
    if ($path.Count -lt 3) { throw "Unrecognised artifact URL: $ArtifactUrl" }
    $type, $version, $country = $path[-3], $path[-2], $path[-1]
    $parts = $version.Split('.')
    $major = [int]$parts[0]
    if ($major -lt 28) {
        throw "BC $version is not supported: BCDock's AL-Go integration needs BC 28 or later (remote test running needs the server's dev API 7.0)."
    }
    # MajorMinor is what env create is given: AL-Go has already resolved "28.5/au/latest" to Microsoft's
    # newest build, which BCDock may not have a ready image for yet, so BCDock picks its own newest 28.5.
    $majorMinor = if ($parts.Count -ge 2) { '{0}.{1}' -f $parts[0], $parts[1] } else { $parts[0] }
    [pscustomobject]@{ Type = $type.ToLowerInvariant(); Version = $version; MajorMinor = $majorMinor; Country = $country.ToLowerInvariant(); Major = $major }
}

# The altool package major for a BC major: 18.x drives BC 28-29; a BC 30+ server is refused by 18.x
# as too new, so it needs 30.x.
function Get-AlToolPackageVersion {
    param([Parameter(Mandatory)][int] $BcMajor)
    if ($BcMajor -ge 30) { return '30.*-*' }   # prerelease while 30.x is beta
    return '18.*'
}

# The text of one entry inside a .app, or $null if it has none. A .app is a NAVX header (its length at
# offset 4) followed by a zip.
function Read-AppEntryText {
    param([Parameter(Mandatory)][string] $AppFile, [Parameter(Mandatory)][string] $EntryName)
    $bytes = [System.IO.File]::ReadAllBytes($AppFile)
    if ([System.Text.Encoding]::ASCII.GetString($bytes, 0, 4) -ne 'NAVX') { throw "$AppFile is not a NAVX .app" }
    $headerLength = [BitConverter]::ToInt32($bytes, 4)
    $zipStream = [System.IO.MemoryStream]::new($bytes, $headerLength, $bytes.Length - $headerLength)
    $zip = [System.IO.Compression.ZipArchive]::new($zipStream, [System.IO.Compression.ZipArchiveMode]::Read)
    try {
        $entry = $zip.GetEntry($EntryName)
        if (-not $entry) { return $null }
        $reader = [System.IO.StreamReader]::new($entry.Open(), [System.Text.Encoding]::UTF8)
        try { return $reader.ReadToEnd().TrimStart([char]0xFEFF) } finally { $reader.Dispose() }
    }
    finally { $zip.Dispose() }
}

# Id, name, publisher and version of a .app. Microsoft's own apps in a BC artifact are "ready to run"
# packages, which wrap the app and describe it in readytorunappmanifest.json instead.
function Get-AppManifest {
    param([Parameter(Mandatory)][string] $AppFile)
    $xml = Read-AppEntryText -AppFile $AppFile -EntryName 'NavxManifest.xml'
    if ($xml) {
        $app = ([xml]$xml).Package.App
        return [pscustomobject]@{ Id = $app.Id; Name = $app.Name; Publisher = $app.Publisher; Version = $app.Version }
    }
    $r2r = Read-AppEntryText -AppFile $AppFile -EntryName 'readytorunappmanifest.json'
    if ($r2r) {
        $m = $r2r | ConvertFrom-Json
        return [pscustomobject]@{ Id = $m.EmbeddedAppId; Name = $m.EmbeddedAppName; Publisher = $m.EmbeddedAppPublisher; Version = $m.EmbeddedAppVersion }
    }
    throw "$AppFile has neither NavxManifest.xml nor readytorunappmanifest.json"
}

# Test codeunit ids in a compiled .app, read from its SymbolReference.json. Offline, any BC version.
function Get-AppTestCodeunits {
    param([Parameter(Mandatory)][string] $AppFile)
    $text = Read-AppEntryText -AppFile $AppFile -EntryName 'SymbolReference.json'
    if (-not $text) { throw "$AppFile has no SymbolReference.json" }
    $json = $text | ConvertFrom-Json

    $collect = {
        param($node)
        if ($node.PSObject.Properties['Codeunits']) { $script:found += @($node.Codeunits) }
        if ($node.PSObject.Properties['Namespaces']) { foreach ($n in $node.Namespaces) { & $collect $n } }
    }
    $script:found = @()
    & $collect $json
    $codeunits = foreach ($cu in $script:found) {
        $subtype = @($cu.Properties | Where-Object { $_.Name -eq 'Subtype' } | ForEach-Object { $_.Value })
        if ($subtype -contains 'Test') { [pscustomobject]@{ Id = [int]$cu.Id; Name = [string]$cu.Name } }
    }
    return @($codeunits | Sort-Object Id -Unique)
}

function Get-AppTestCodeunitIds {
    param([Parameter(Mandatory)][string] $AppFile)
    return @(Get-AppTestCodeunits -AppFile $AppFile | ForEach-Object { $_.Id })
}

# Convert altool runtests JSON (one or more runs) to JUnit, appending to $ResultsFile, in the shape
# BcContainerHelper's own test runner writes and AL-Go's AnalyzeTests reads: one testsuite per codeunit
# named "<id> <name>", with time/tests/failures/errors/skipped and extensionid + appName properties.
# altool adds a row per codeunit with an EMPTY methodName that repeats a failure; those rows are
# not tests and are skipped, so its summary counts (data.failed) are not trusted either.
# Returns $true only if every test passed and at least one test ran.
function Write-AlToolResultsAsJUnit {
    param(
        [Parameter(Mandatory)][object[]] $Runs,       # parsed altool JSON objects
        [Parameter(Mandatory)][string] $ResultsFile,
        [Parameter(Mandatory)][string] $AppName,
        [string] $ExtensionId = '',
        [hashtable] $CodeunitNames = @{},             # codeunit id -> name, for the suite names
        [switch] $Append
    )
    $inv = [Globalization.CultureInfo]::InvariantCulture
    $doc = [System.Xml.XmlDocument]::new()
    if ($Append -and (Test-Path $ResultsFile)) { $doc.Load($ResultsFile) }
    $root = $doc.SelectSingleNode('/testsuites')
    if (-not $root) {
        $root = $doc.CreateElement('testsuites')
        [void]$doc.AppendChild($root)
    }
    $newSuite = {
        param([string] $name)
        $s = $doc.CreateElement('testsuite')
        $s.SetAttribute('name', $name)
        $s.SetAttribute('timestamp', (Get-Date -Format s))
        $s.SetAttribute('hostname', [Environment]::MachineName)
        $props = $doc.CreateElement('properties')
        foreach ($p in @(@('extensionid', $ExtensionId), @('appName', $AppName))) {
            if ($p[1]) {
                $e = $doc.CreateElement('property'); $e.SetAttribute('name', $p[0]); $e.SetAttribute('value', $p[1])
                [void]$props.AppendChild($e)
            }
        }
        [void]$s.AppendChild($props)
        return $s
    }

    $allPassed = $true
    $ran = 0
    foreach ($run in $Runs) {
        $rows = @()
        if ($run.PSObject.Properties['data'] -and $run.data -and $run.data.PSObject.Properties['results']) {
            $rows = @($run.data.results | Where-Object { $_.methodName })
        }
        if ($rows.Count -eq 0) {
            # No test rows: altool failed before running anything (auth, connection, version gate).
            $allPassed = $false
            $suite = & $newSuite $AppName
            foreach ($a in @(@('time', '0'), @('tests', '1'), @('errors', '1'), @('failures', '0'), @('skipped', '0'))) { $suite.SetAttribute($a[0], $a[1]) }
            $case = $doc.CreateElement('testcase'); $case.SetAttribute('classname', $AppName); $case.SetAttribute('name', 'altool runtests'); $case.SetAttribute('time', '0')
            $err = $doc.CreateElement('error'); $err.SetAttribute('message', [string]$run.message); $err.InnerText = [string]$run.message
            [void]$case.AppendChild($err); [void]$suite.AppendChild($case); [void]$root.AppendChild($suite)
            continue
        }
        foreach ($group in ($rows | Group-Object codeunitId)) {
            $cuName = $CodeunitNames[[int]$group.Name]
            $suiteName = if ($cuName) { "$($group.Name) $cuName" } else { "$($group.Name)" }
            $suite = & $newSuite $suiteName
            $failures = @($group.Group | Where-Object { $_.status -eq 'failed' }).Count
            $skipped = @($group.Group | Where-Object { $_.status -eq 'skipped' }).Count
            $seconds = (@($group.Group | ForEach-Object { [double]$_.durationMs }) | Measure-Object -Sum).Sum / 1000
            $suite.SetAttribute('time', ([Math]::Round($seconds, 3)).ToString($inv))
            $suite.SetAttribute('tests', [string]$group.Count)
            $suite.SetAttribute('errors', '0')
            $suite.SetAttribute('failures', [string]$failures)
            $suite.SetAttribute('skipped', [string]$skipped)
            foreach ($row in $group.Group) {
                $ran++
                $case = $doc.CreateElement('testcase')
                $case.SetAttribute('classname', $suiteName)
                $case.SetAttribute('name', [string]$row.methodName)
                $case.SetAttribute('time', ([Math]::Round([double]$row.durationMs / 1000, 3)).ToString($inv))
                if ($row.status -eq 'failed') {
                    $allPassed = $false
                    $f = $doc.CreateElement('failure')
                    $f.SetAttribute('message', ([string]$row.output).Split("`n")[0].Trim())
                    $f.InnerText = [string]$row.output
                    [void]$case.AppendChild($f)
                }
                elseif ($row.status -eq 'skipped') {
                    [void]$case.AppendChild($doc.CreateElement('skipped'))
                }
                elseif ($row.status -ne 'passed') {
                    $allPassed = $false
                    $e = $doc.CreateElement('error'); $e.SetAttribute('message', "unknown status '$($row.status)'")
                    [void]$case.AppendChild($e)
                }
                [void]$suite.AppendChild($case)
            }
            [void]$root.AppendChild($suite)
        }
    }
    $doc.Save($ResultsFile)
    return ($allPassed -and $ran -gt 0)
}

# Print altool runtests results to the build log the way BcContainerHelper's test runner does: a line
# per codeunit and per test, and for each failure a GitHub annotation ("::error::Function <test> <msg>",
# or ::warning:: when AL-Go treats test failures as warnings) plus the error and the AL call stack.
function Write-AlToolResultsToHost {
    param(
        [Parameter(Mandatory)][object[]] $Runs,
        [hashtable] $CodeunitNames = @{},
        [ValidateSet('error', 'warning', 'no')][string] $GitHubActions = 'no'
    )
    foreach ($run in $Runs) {
        $rows = @()
        if ($run.PSObject.Properties['data'] -and $run.data -and $run.data.PSObject.Properties['results']) {
            $rows = @($run.data.results | Where-Object { $_.methodName })
        }
        if ($rows.Count -eq 0) {
            if ($GitHubActions -ne 'no') { Write-Host "::$($GitHubActions)::altool runtests ran no tests: $($run.message)" }
            Write-Host "  altool runtests ran no tests: $($run.message)"
            continue
        }
        foreach ($group in ($rows | Group-Object codeunitId)) {
            $failed = @($group.Group | Where-Object { $_.status -ne 'passed' -and $_.status -ne 'skipped' }).Count
            $seconds = [Math]::Round((@($group.Group | ForEach-Object { [double]$_.durationMs }) | Measure-Object -Sum).Sum / 1000, 3)
            $label = (@($group.Name, $CodeunitNames[[int]$group.Name]) | Where-Object { $_ }) -join ' '
            Write-Host ("  Codeunit {0} {1} ({2} seconds)" -f $label, $(if ($failed) { 'Failure' } else { 'Success' }), $seconds)
            foreach ($row in $group.Group) {
                $t = [Math]::Round([double]$row.durationMs / 1000, 3)
                if ($row.status -eq 'passed') { Write-Host "    Testfunction $($row.methodName) Success ($t seconds)"; continue }
                if ($row.status -eq 'skipped') { Write-Host "    Testfunction $($row.methodName) Skipped"; continue }
                # altool's output is the error message, then "AL Callstack:" and the stack.
                $text = [string]$row.output
                $parts = $text -split "AL Callstack:", 2
                $message = $parts[0].Trim()
                if ($GitHubActions -ne 'no') { Write-Host "::$($GitHubActions)::Function $($row.methodName) $(($message -split "`n")[0])" }
                Write-Host "    Testfunction $($row.methodName) Failure ($t seconds)"
                Write-Host "      Error:"
                foreach ($line in ($message -split "`n")) { Write-Host "        $($line.TrimEnd())" }
                if ($parts.Count -gt 1 -and $parts[1].Trim()) {
                    Write-Host "      Call Stack:"
                    foreach ($line in ($parts[1].Trim() -split "`n")) { Write-Host "        $($line.TrimEnd())" }
                }
            }
        }
    }
}

# Turn alc output into what AL-Go reads back from BuildOutput.txt: with GitHub Actions, each
# diagnostic "<file>(<line>,<col>): error|warning <id>: <msg>" becomes an annotation
# "::error|warning file=<relative file>,line=<line>,col=<col>::<id> <msg>" (the container-mode form
# AL-Go's new-warnings check parses), other lines pass through. Counts errors and warnings.
function Format-AlcOutput {
    param(
        [string[]] $Lines = @(),
        [bool] $GitHubActions = $false,
        [string] $BasePath = ''
    )
    $out = @(); $errors = 0; $warnings = 0
    foreach ($line in $Lines) {
        if ($line -match '^(?<file>.+)\((?<line>\d+),(?<col>\d+)\): (?<sev>error|warning) (?<id>[A-Z]{2}\d{4}): (?<msg>.+)$') {
            if ($Matches.sev -eq 'error') { $errors++ } else { $warnings++ }
            if ($GitHubActions) {
                $file = $Matches.file
                if ($BasePath -and $file.StartsWith($BasePath)) { $file = $file.Substring($BasePath.Length).TrimStart('/', '\') }
                $out += "::$($Matches.sev) file=$file,line=$($Matches.line),col=$($Matches.col)::$($Matches.id) $($Matches.msg)"
                continue
            }
        }
        $out += $line
    }
    [pscustomobject]@{ Lines = $out; Errors = $errors; Warnings = $warnings }
}

# The apps this build has published to its env, recorded by PublishBcContainerApp and reported
# by GetBcContainerAppInfo: a fresh env per build means these are exactly the build's apps installed.
function Get-BcDockPublishedFile {
    return Join-Path (Split-Path (Get-BcDockStateFile)) 'bcdock-algo-published.json'
}

function Add-BcDockPublishedApp {
    param([Parameter(Mandatory)] $Manifest)
    $file = Get-BcDockPublishedFile
    $apps = @()
    if (Test-Path $file) { $apps = @(Get-Content $file -Raw | ConvertFrom-Json) }
    $apps = @($apps | Where-Object { $_.AppId -ne $Manifest.Id })
    $apps += [pscustomobject]@{ AppId = $Manifest.Id; Name = $Manifest.Name; Publisher = $Manifest.Publisher; Version = $Manifest.Version; IsInstalled = $true }
    ConvertTo-Json -InputObject @($apps) -Depth 3 | Set-Content $file
}

function Get-BcDockPublishedApps {
    $file = Get-BcDockPublishedFile
    if (-not (Test-Path $file)) { return @() }
    return @(Get-Content $file -Raw | ConvertFrom-Json)
}

# Non-Microsoft dependencies from NuGet, for InstallMissingDependencies. The feeds are the ones the repo
# trusts in its AL-Go settings (TrustedNuGetFeeds); the overrides carry no feed list of their own. A BC app's
# package id ends in ".<appId>"; symbols-only packages (".symbols.") cannot be installed and are ignored.
function ConvertFrom-NuGetVersionRange {
    param([Parameter(Mandatory)][string] $Range)
    # "28.7.0.0", "[28.7.0.0,)" or "[28.7.0.0,29.0.0.0)": the minimum is what an app dependency means.
    $min = ($Range.Trim() -replace '^[\[\(]', '' -split ',')[0].Trim()
    return [Version]$min
}

function Get-BcDockNuGetFeed {
    param([Parameter(Mandatory)][string] $Url)
    $index = Invoke-RestMethod -Uri $Url -UseBasicParsing
    $base = @($index.resources | Where-Object { "$($_.'@type')" -like 'PackageBaseAddress/3.0.0*' } | ForEach-Object { $_.'@id' })
    $search = @($index.resources | Where-Object { "$($_.'@type')" -like 'SearchQueryService*' } | ForEach-Object { $_.'@id' })
    if (-not $base) { throw "NuGet feed $Url has no PackageBaseAddress resource" }
    return [pscustomobject]@{ Url = $Url; Base = $base[0].TrimEnd('/') + '/'; Search = $(if ($search) { $search[0] } else { $null }) }
}

function Find-BcDockNuGetPackageId {
    param([Parameter(Mandatory)] $Feed, [Parameter(Mandatory)][string] $AppId)
    if (-not $Feed.Search) { return $null }
    $found = Invoke-RestMethod -Uri "$($Feed.Search)?q=$AppId&prerelease=false&take=100" -UseBasicParsing
    $ids = @($found.data | ForEach-Object { $_.id } | Where-Object { $_.ToLowerInvariant().EndsWith(".$($AppId.ToLowerInvariant())") -and $_ -notmatch '\.symbols\.' })
    if ($ids) { return $ids[0] }
    return $null
}

function Get-BcDockNuGetVersions {
    param([Parameter(Mandatory)] $Feed, [Parameter(Mandatory)][string] $PackageId)
    try { $r = Invoke-RestMethod -Uri "$($Feed.Base)$($PackageId.ToLowerInvariant())/index.json" -UseBasicParsing }
    catch { return @() }
    $out = @()
    foreach ($v in @($r.versions)) { $parsed = $null; if ($v -notlike '*-*' -and [Version]::TryParse($v, [ref]$parsed)) { $out += $parsed } }
    return $out
}

function Get-BcDockNuGetDependencies {
    param([Parameter(Mandatory)] $Feed, [Parameter(Mandatory)][string] $PackageId, [Parameter(Mandatory)][Version] $Version)
    $idl = $PackageId.ToLowerInvariant()
    $content = (Invoke-WebRequest -Uri "$($Feed.Base)$idl/$Version/$idl.nuspec" -UseBasicParsing).Content
    if ($content -is [byte[]]) { $content = [System.Text.Encoding]::UTF8.GetString($content) }
    $nuspec = [xml]($content.TrimStart([char]0xFEFF))  # feeds serve it with a byte-order mark
    return @($nuspec.SelectNodes("//*[local-name()='dependency']") | ForEach-Object {
        [pscustomobject]@{ Id = $_.GetAttribute('id'); MinVersion = (ConvertFrom-NuGetVersionRange $_.GetAttribute('version')) } })
}

# Resolve the given non-Microsoft dependencies, and theirs, to packages in the feeds, in publish order
# (each package after everything it depends on). Picks the highest version with the required major that
# is at least the required one and whose Microsoft.Application / Microsoft.Platform minimum the env meets.
# Throws, naming every app no feed has, BEFORE anything is downloaded or published.
function Resolve-BcDockNuGetApps {
    param([Parameter(Mandatory)] $Feeds,
          [Parameter(Mandatory)] $Dependencies,  # objects with AppId, Name, MinVersion
          [Parameter(Mandatory)][Version] $EnvVersion)
    $resolved = [ordered]@{}; $missing = @(); $order = New-Object System.Collections.ArrayList
    $queue = New-Object System.Collections.Queue
    foreach ($d in $Dependencies) { $queue.Enqueue([pscustomobject]@{ PackageId = $null; AppId = $d.AppId; Name = $d.Name; MinVersion = [Version]$d.MinVersion }) }
    while ($queue.Count) {
        $want = $queue.Dequeue()
        $key = if ($want.PackageId) { $want.PackageId.ToLowerInvariant() } else { "app:$($want.AppId.ToLowerInvariant())" }
        if ($resolved.Contains($key)) { continue }
        $hit = $null; $why = 'no configured feed has it'
        foreach ($feed in $Feeds) {
            $pkg = if ($want.PackageId) { $want.PackageId } else { Find-BcDockNuGetPackageId -Feed $feed -AppId $want.AppId }
            if (-not $pkg) { continue }
            $candidates = @(Get-BcDockNuGetVersions -Feed $feed -PackageId $pkg | Where-Object { $_.Major -eq $want.MinVersion.Major -and $_ -ge $want.MinVersion } | Sort-Object -Descending)
            if (-not $candidates) { if ($want.PackageId) { continue }; $why = "no version $($want.MinVersion.Major).x at or above $($want.MinVersion)"; continue }
            foreach ($v in $candidates) {
                $deps = Get-BcDockNuGetDependencies -Feed $feed -PackageId $pkg -Version $v
                $needs = @($deps | Where-Object { $_.Id -in 'Microsoft.Application', 'Microsoft.Platform' } | ForEach-Object { $_.MinVersion })
                if (@($needs | Where-Object { $_ -gt $EnvVersion }).Count -eq 0) { $hit = [pscustomobject]@{ PackageId = $pkg; Version = $v; Feed = $feed; Deps = $deps }; break }
                $why = "no version fits BC $EnvVersion"
            }
            if ($hit) { break }
        }
        if (-not $hit) { $missing += "$($want.Name) ($($want.MinVersion)): $why"; $resolved[$key] = $null; continue }
        $resolved[$key] = $hit
        $resolved[$hit.PackageId.ToLowerInvariant()] = $hit
        foreach ($dep in $hit.Deps) {
            if ($dep.Id -like 'Microsoft.*') { continue }  # the env has Microsoft's apps for its BC version
            $queue.Enqueue([pscustomobject]@{ PackageId = $dep.Id; AppId = $null; Name = $dep.Id; MinVersion = $dep.MinVersion })
        }
    }
    if ($missing) { throw "BCDock: these dependencies cannot be installed from the NuGet feeds in your AL-Go settings that need no sign-in (TrustedNuGetFeeds): $($missing -join '; '). Nothing was published." }
    $done = @{}
    $visit = $null
    $visit = {
        param($h)
        $k = $h.PackageId.ToLowerInvariant()
        if ($done.ContainsKey($k)) { return }
        $done[$k] = $true
        foreach ($dep in $h.Deps) { if ($dep.Id -notlike 'Microsoft.*') { & $visit $resolved[$dep.Id.ToLowerInvariant()] } }
        [void]$order.Add($h)
    }
    foreach ($k in @($resolved.Keys)) { if ($k -like 'app:*') { & $visit $resolved[$k] } }
    return @($order)
}

# Download one resolved package and return the path of the .app inside it.
function Save-BcDockNuGetApp {
    param([Parameter(Mandatory)] $Package, [Parameter(Mandatory)][string] $Folder)
    $idl = $Package.PackageId.ToLowerInvariant()
    $nupkg = Join-Path $Folder "$idl.$($Package.Version).nupkg"
    Invoke-WebRequest -Uri "$($Package.Feed.Base)$idl/$($Package.Version)/$idl.$($Package.Version).nupkg" -OutFile $nupkg -UseBasicParsing
    $zip = [System.IO.Compression.ZipFile]::OpenRead($nupkg)
    try {
        $entry = @($zip.Entries | Where-Object { $_.FullName -like '*.app' })
        if ($entry.Count -ne 1) { throw "$($Package.PackageId) $($Package.Version) holds $($entry.Count) .app files, expected 1" }
        $appFile = Join-Path $Folder ($entry[0].Name)
        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry[0], $appFile, $true)
    }
    finally { $zip.Dispose() }
    Remove-Item $nupkg -Force
    return $appFile
}

# The BCDock wordmark ([) inside the D), printed by each override as its step starts, so the build log
# shows which steps BCDock runs instead of BcContainerHelper.
function Write-BcDockBanner {
    param([Parameter(Mandatory)][string] $Step)
    $lines = @'
 ___  ___ ___          _
| _ )/ __|   \ ___  __| |__
| _ \ (__| [) / _ \/ _| / /
|___/\___|___/\___/\__|_\_\
'@ -split "`r?`n"
    Write-Host ''
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($i -eq $lines.Count - 1) { Write-Host "$($lines[$i])  $Step" } else { Write-Host $lines[$i] }
    }
}

Export-ModuleMember -Function Get-BcDockStateFile, ConvertFrom-ArtifactUrl, Get-AlToolPackageVersion, Get-AppManifest, Get-AppTestCodeunits, Get-AppTestCodeunitIds, Write-AlToolResultsAsJUnit, Write-AlToolResultsToHost, Format-AlcOutput, Get-BcDockPublishedFile, Add-BcDockPublishedApp, Get-BcDockPublishedApps, Write-BcDockBanner, Get-BcDockNuGetFeed, Resolve-BcDockNuGetApps, Save-BcDockNuGetApp
