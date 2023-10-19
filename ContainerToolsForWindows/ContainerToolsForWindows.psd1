@{
    # Version number of this module.
    ModuleVersion     = '1.0.0'

    # Supported PSEditions
    # CompatiblePSEditions = @()

    # ID used to uniquely identify this module
    GUID              = '8a534dc0-6e6f-431b-9de8-29d4659af987'

    # Author of this module
    Author            = 'Microsoft Corporation'

    # Company or vendor of this module
    CompanyName       = 'Microsoft Corporation'

    # Copyright statement for this module
    Copyright         = '(c) Microsoft Corporation. All rights reserved.'

    # Description of the functionality provided by this module
    Description       = 'PowerShell functions that allow you to download, install, and configure Containerd, Buildkit, Nerdctl, and Windows CNI plugins'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.0'

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    NestedModules     = @(
        'Private\CommonToolUtilities.psm1'
        'Private\UpdateEnvironmentPath.psm1'
        'Public\AllToolsUtilities.psm1',
        'Public\BuildkitTools.psm1'
        'Public\ContainerdTools.psm1'
        'Public\ContainerNetworkTools.psm1'
        'Public\NerdctlTools.psm1'
    )

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
        'Show-ContainerTools',
        'Install-ContainerTools',
        'Get-BuildkitLatestVersion',
        'Install-Buildkit',
        'Register-BuildkitdService',
        'Start-BuildkitdService',
        'Stop-BuildkitdService',
        'Uninstall-Buildkit',
        'Get-ContainerdLatestVersion',
        'Install-Containerd',
        'Register-ContainerdService',
        'Start-ContainerdService',
        'Stop-ContainerdService',
        'Uninstall-Containerd',
        'Get-NerdctlLatestVersion',
        'Install-Nerdctl',
        'Uninstall-Nerdctl',
        'Get-WinCNILatestVersion',
        'Install-WinCNIPlugin',
        'Initialize-NatNetwork',
        'Uninstall-WinCNIPlugin'
    )

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport   = ''

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport   = 'Start-Containerd', 'Stop-Containerd', 'Start-Buildkitd', 'Stop-Buildkitd'

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData       = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags                       = @('Containerd', 'Buildkit', 'Nerdctl', 'Windows Containers', 'Container Tools')

            # A URL to the license for this module.
            LicenseUri                 = "https://cdn.githubraw.com/.../ContainerToolsForWindows/main/LICENSE"

            # A URL to the main website for this project.
            ProjectUri                 = 'https://github.com/.../ContainerToolsForWindows'

            # Flag to indicate whether the module requires explicit user acceptance for install/update/save
            RequireLicenseAcceptance   = $true

            # External dependent modules of this module
            ExternalModuleDependencies = @('HNS', 'ThreadJob')

        }
    }
}