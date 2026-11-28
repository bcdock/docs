---
title: Install a third-party app and build a PTE on it
description: Put an ISV's apps into a BCDock environment with the CLI, then compile and publish your own per-tenant extension on top. Worked example with Continia Expense Management.
schema_type: HowTo
---

# Install a third-party app and build a PTE on it

Your customers run ISV apps, and your per-tenant extension (PTE) often extends one of them. You can install those apps into a BCDock environment yourself and build your PTE against them, all from a terminal:

1. Get the ISV's `.app` files.
2. Publish them into your environment in dependency order.
3. Download symbols, which now include the ISV's.
4. Compile and publish your PTE.

The worked example below uses **Continia Expense Management** on BC 28.5 (AU) because it is the one we tested end to end. The same steps apply to any ISV whose app files you can get. Continia is an example only: BCDock is not affiliated with Continia or any other ISV.

This is a CLI flow. The portal has no app upload today.

## Before you start

- **The ISV's licence and activation are between your customer and the ISV.** Installing an app in a sandbox environment does not license it. Some ISV pages refuse to open until the ISV's own setup is done. Continia Expense Management's pages, for example, show "The Expense Management Setup does not exist" until Continia's setup has run. Your PTE still compiles and publishes before that, and its table fields are there.
- **Pick a BC version the ISV supports.** ISVs build each release for specific BC versions. Continia Expense Management 28.7 needs BC 28.0 or later; we tested it on BC 28.5.
- **You need** `bcdock` signed in (`bcdock auth whoami`), PowerShell 7 (`pwsh`, on Windows, macOS or Linux), and an AL project for your PTE.

## 1. Create an environment

```bash
bcdock env create --name isv-dev --version 28.5 --country au --region australiaeast --wait
```

Single-tenant and multi-tenant both work: we ran the whole flow in each. Environments are multi-tenant by default; add `--multi-tenant=false` for single-tenant.

## 2. Get the ISV's app files

Where the files come from depends on the ISV:

- **A public package feed.** Some ISVs publish their releases to a NuGet feed for build pipelines, and anyone can download from it. Continia does: see Continia's guide to [accessing Continia apps in build pipelines](https://docs.continia.com/en-us/continia-banking/development-and-administration/development-and-customization/accessing-continia-apps-in-build-pipelines/).
- **The ISV's partner portal**, if you are a partner of that ISV.
- **Your customer**, who may already hold the files for their version.

An app usually depends on other apps from the same ISV. The ISV's install documentation lists them; on a NuGet feed, each package lists its dependencies.

### Worked example: Continia Expense Management from Continia's feed

Expense Management 28.7 needs 12 Continia apps. This downloads the newest 28.7 build of each into `isv-apps/`, in the order you will publish them:

```powershell
$feed = 'https://pkgs.dev.azure.com/continia-repository/ContiniaBCPublicFeeds/_packaging/AppSourceApps/nuget/v3/index.json'
$base = (Invoke-RestMethod $feed).resources |
  Where-Object '@type' -eq 'PackageBaseAddress/3.0.0' |
  Select-Object -ExpandProperty '@id'

$packages = @(
  'continiasoftware.continiasystemapplication.e4b442d0-e8e3-4210-bfca-f1e66686caa0'
  'continiasoftware.continiacore.4b915d7e-c02a-435f-85ab-649086c1e002'
  'continiasoftware.continiaconnectorapp.2b9992c2-5eaf-4cdc-b33b-592d917780d2'
  'continiasoftware.continiabusinessfoundation.bbb72c8a-3abf-478f-9239-a34dbc252d07'
  'continiasoftware.continiaapprovals.4ec0dd0d-89ca-4266-bdec-c0bdacf923e3'
  'continiasoftware.continiaonlineconnector.d90c350c-df9b-4d16-8871-6f8d7b102f98'
  'continiasoftware.continiacustomeronboarding.16757e5a-764d-48f4-a6af-1dc35d6b226b'
  'continiasoftware.continiadeliverynetwork.0745e76d-0b72-4641-87c2-ee45db5d2c32'
  'continiasoftware.continiadeliverynetwork-onboarding.a4d67f3d-a67f-46be-9d43-fe782796a9b2'
  'continiasoftware.continiadocumentoutput.f4b69b55-c90d-4937-8f53-2742898fa948'
  'continiasoftware.continiadocumentcapture.6da8dd2f-e698-461f-9147-8e404244dd85'
  'continiasoftware.continiaexpensemanagement.8d4eab29-8c7f-4b6c-be9a-b7fdfb9da196'
)

Remove-Item isv-apps -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory isv-apps | Out-Null
$n = 0
foreach ($id in $packages) {
  $n++
  $out = 'isv-apps/{0:D2}-{1}.app' -f $n, $id
  try {
    $ver = (Invoke-RestMethod "$base$id/index.json").versions |
      Where-Object { $_.StartsWith('28.7.') } | Select-Object -Last 1
    if (-not $ver) { throw 'no 28.7 build on the feed' }
    Invoke-WebRequest "$base$id/$ver/$id.$ver.nupkg" -OutFile pkg.zip
    Expand-Archive pkg.zip -DestinationPath pkg -Force -ErrorAction Stop
    $app = Get-ChildItem pkg -Filter *.app -Recurse | Select-Object -First 1
    if (-not $app) { throw 'no .app in the package' }
    Move-Item $app.FullName $out -ErrorAction Stop
  }
  catch {
    Write-Host "failed: $id ($($_.Exception.Message))"
    break
  }
  finally {
    Remove-Item pkg.zip, pkg -Recurse -Force -ErrorAction SilentlyContinue
  }
}
Get-ChildItem isv-apps | Select-Object Name
```

A `.nupkg` is a zip file, and the `.app` is inside it. The number at the front of each file name keeps the publish order. If a package can't be downloaded, the loop prints `failed:` with its name and stops. The packages before it stay in `isv-apps/`, so fix the cause and run the whole block again before step 3. The block starts by clearing `isv-apps/`.

## 3. Publish the ISV apps in dependency order

Publish one app at a time, dependencies first:

```powershell
foreach ($app in Get-ChildItem isv-apps -Filter *.app | Sort-Object Name) {
  bcdock env publish isv-dev $app.FullName
  if ($LASTEXITCODE -ne 0) { Write-Host "failed: $($app.Name)"; break }
}
```

In our run each app took between a couple of seconds and about two minutes. The loop stops at the first failed publish, so the error is the last thing on screen.

Microsoft's apps that ISV apps depend on (System Application, Base Application, Intelligent Cloud Base and so on) are already in the environment, so you don't publish those.

## 4. Download symbols

Once the ISV apps are installed, the environment serves their symbols alongside Microsoft's. Add the ISV dependency to your PTE's `app.json`:

```json
"dependencies": [
  {
    "id": "8d4eab29-8c7f-4b6c-be9a-b7fdfb9da196",
    "name": "Continia Expense Management",
    "publisher": "Continia Software",
    "version": "28.7.0.0"
  }
],
"platform": "28.0.0.0",
"application": "28.0.0.0",
"runtime": "17.0",
"target": "Cloud"
```

Then, from your PTE's folder:

```bash
bcdock env download-symbols isv-dev --out-dir .alpackages
```

You don't need the ISV's own dependencies in `app.json`. Declaring the app you extend is enough.

## 5. Compile and publish your PTE

Our test PTE added a **Project Code** field to Continia's expense table and showed it on the expense card:

```al
tableextension 50100 "BCD CEM Expense Project" extends "CEM Expense"
{
    fields
    {
        field(50100; "BCD Project Code"; Code[20])
        {
            Caption = 'Project Code';
            DataClassification = CustomerContent;
        }
    }
}

pageextension 50100 "BCD CEM Expense Card Project" extends "CEM Expense Card"
{
    layout
    {
        addafter(Description)
        {
            field("BCD Project Code"; Rec."BCD Project Code")
            {
                ApplicationArea = All;
            }
        }
    }
}
```

Compile it with the environment's own compiler, then publish:

```shell
bcdock al compile --env isv-dev --package-cache .alpackages --out MyPte.app
bcdock env publish isv-dev MyPte.app
```

**Extension Management** in the environment now lists the ISV's apps and your PTE. From here it is the normal [AL extension loop](al-extension-loop.md): change, compile, publish.

## Hibernate and resume

The ISV apps and your PTE stay installed when you hibernate and resume on the same BC version. We confirmed this in both single-tenant and multi-tenant environments:

```shell
bcdock env hibernate isv-dev --wait
bcdock env resume isv-dev --wait
```

We have not tested resuming onto a newer BC version with ISV apps installed.

## If a publish fails

- **The error names an app that is not installed.** You skipped a dependency, or published out of order. Publish the named app first, then retry.
- **The error is about the licence or object ranges ("outside my range").** It did not happen with Continia's apps, but another ISV's apps may need a licence the environment does not have. Ask the ISV what their app needs to run in a sandbox container.
- **The app targets a different BC version.** Get the ISV's build for your environment's version, or create the environment on a version the ISV supports.

## AL-Go builds

An AL-Go for GitHub build can install the ISV app for you: name the ISV's NuGet feed in your AL-Go settings, and each build installs the app and its dependencies into its environment before compiling. See [AL-Go for GitHub](al-go.md#4-settings).
