## Introduction

_Provide a brief summary of the update._

## New Features

_List the new features and give a short description of what the feature does._

## Bug fixes

_Bulleted list of bug fixes and issue resolutions: Discuss the resolved issues and their impact._

## Known issues

_Ongoing issue that are still being worked on._

## Quick start guide

> [!IMPORTANT] 
> All the Containers-Toolkit files, including \*.ps1, \*.psd1, \*.psm1, and \*.ps1xml, have been
> code signed. This means that you will be able to run the module in a PowerShell session
> where the execution policy is set to `AllSigned` or `RemoteSigned`.
> To learn more about PowerShell execution policies, see [about_Execution_Policies](https://go.microsoft.com/fwlink/?LinkID=135170).

### Install from PowerShell Gallery

```PowerShell
Install-Module -Name Containers-Toolkit -RequiredVersion "__NEW_VERSION__"
```

If the module is already installed, update the module:

```PowerShell
Update-Module -Name Containers-Toolkit -RequiredVersion "__NEW_VERSION__"
```

### Download Source Files

1. Download source files
1. Open a new terminal
1. cd into the location of the downloaded files
    Example: If downloaded to the downloads folder:

    ```PowerShell
    cd "$env:USERPROFILE\Downloads\containers-toolkit"
    ```

1. Unblock the files

    ```PowerShell
    Get-ChildItem -Path . -Recurse | Unblock-File"
    ```

1. Import the module

See instructions in the [Installing and importting Containers-Toolkit module](../../README.md#download-source-files) section

## Visuals

_Screenshots, Side-by-side comparisons, 30-second videos_

## Discussions

_**Update the discussoin link**_

For any questions or feedback on this release, see the discussion: [Containers.ToolKit v__NEW_VERSION__](<LINK-TO-VERSION-DISCUSSION>)

## Release Authors

[ADD YOUR NAME HERE] (@[ADD YOUR GITHUB ID HERE])
