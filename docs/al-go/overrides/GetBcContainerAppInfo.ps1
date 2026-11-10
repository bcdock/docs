# AL-Go "which apps are installed". A BCDock build env is created fresh for every build, so
# its installed apps beyond Microsoft's are exactly the ones this build published; PublishBcContainerApp
# records each one. Run-AlPipeline uses the answer to choose install or upgrade and, with the compiler
# folder off, to check a test app is installed before running its tests. No OData calls (each would
# reveal the env's access key and write an audit row).
Param([Hashtable] $parameters)
. (Join-Path $PSScriptRoot '_bcdock.ps1')
Get-BcDockPublishedApps
