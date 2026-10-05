## Creating a Containers-Toolkit release

> [!IMPORTANT]  
> **It is recommended to test with pre-release versions before creating a final release.**
> The PowerShell Gallery does not support permanent deletion of packages. If the module version already exists, you will need to increment the version number  

### Create a GitHub tag

1. **Get the new module version:**

    To choose the new version, you can use the [Semantic Versioning](https://semver.org/) scheme. The version number is in the format `X.Y.Z`, where:
    - `X` is the *major* version number. Indicates significant **changes that may break backward compatibility** with previous versions (e.g., 1.0.0 to 2.0.0).
    - `Y` is the *minor* version number. Represents **new features/ functionality** that are backward compatible (e.g., 1.0.0 to 1.1.0).
    - `Z` is the *patch* version number. Refers to **bug fixes or minor changes** that do not affect functionality or compatibility (e.g., 1.0.0 to 1.0.1).

    ```PowerShell
    $NEW_VERSION = "<new version>" # e.g. 1.0.0
    ```

    If this is pre-release, concatenate the pre-release version to the module version. The pre-release version can be `-rc0`, `-beta0`, `-alpha0`, etc.

    ```PowerShell
    $PRERELEASE_TAG = "<pre-release version>" # e.g. -rc0, -beta0, -alpha0
    ```

    Get the release version and tag:

    ```PowerShell
    $RELEASE_VERSION = "${NEW_VERSION}-${PRERELEASE_TAG}".TrimEnd("-")
    $RELEASE_TAG = "v${RELEASE_VERSION}"
    ```

> [!IMPORTANT]  
> Ensure that the new version number is not already used in the [PowerShell Gallery][ctk-psg].
> If the version already exists, you will need to increment the version number.
> The PowerShell Gallery does not support permanent deletion of packages.
> Use the `Find-Module` command to check if the version already exists.
>
> ```PowerShell
> Find-Module -Name containers-toolkit -AllowPrerelease -RequiredVersion "$RELEASE_VERSION" | Where-Object { $_.Version -eq $RELEASE_VERSION }
> ```
>
> Alternatively, you can use the [build/hacks/get-newversion.ps1](../../hacks/get-newversion.ps1) script to get the new version number.
>
> ```PowerShell
> $RELEASE_TAG = build/hacks/get-newversion.ps1 -Version $NEW_VERSION -Prerelease $PRERELEASE_TAG -ReleaseType "major"
> ```

2. **Create a new branch from the main branch.**

    ```bash
    $BRANCH_NAME = "release/$RELEASE_TAG"
    git checkout -b "$BRANCH_NAME"
    ```

3. **Cherry-pick the changes to a new branch** from the main branch. The new branch name should be `release/X.Y.Z`, where `X.Y.Z` is the new version number.

    - Identify the commit hashes you want to include. You can find them using:

        ```bash
        git log
        ```

    - Cherry-pick the commits to the new branch. You can cherry-pick multiple commits at once by specifying their hashes separated by spaces.

        ```bash
        git cherry-pick <commit_hash_1> <commit_hash_2> <commit_hash_3>
        ```

    - Resolve Any Conflicts (If Necessary)

        If there are any conflicts during the cherry-pick process, Git will pause and allow you to resolve them. After resolving the conflicts, you can continue the cherry-pick process with:

        ```bash
        git status   # Identify conflicts
        # Resolve conflicts in your preferred editor
        git add .
        git cherry-pick --continue
        ```

4. **Create a tag and a release in GitHub.**

    ```bash
    git tag --sign "$RELEASE_TAG" -m "Release $RELEASE_TAG"
    git push upstream "$BRANCH_NAME" --tags
    ```

> [!TIP]  
> To delete an existing tag, use the following command:
>
> ```bash
> git tag --delete "$RELEASE_TAG"
> git push upstream :refs/tags/"$RELEASE_TAG"
> ```

### Create a release using the ADO release pipeline

Releases are created using the Containers-Toolkit ADO release pipeline. The release pipeline is triggered by the creation of a new release branch in GitHub. However, you can also create a [release manually](#manual-release).

#### Manual release

1. In the artifact section, select the `Default Branch` to use for the release.

    *The branch created in step 2 should be selected.*

    The release pipeline uses the branch name to determine the version number. The version number is derived from the branch name by removing the `release/` prefix.

    For example:

    | Branch Name          | Version Number |
    |----------------------|----------------|
    | `release/v1.0.0`     | `v1.0.0`       |
    | `release/v1.0.0-rc0` | `v1.0.0-rc0`   |

1. Create a new release.

    This publishes the module to the [PowerShell Gallery][ctk-psg] and creates a new release in GitHub.

### Verify the release

1. Verify the PowerShell Gallery release:

    ```PowerShell
    Find-Module -Name containers-toolkit -AllVersions -AllowPrerelease
    ```

> [!IMPORTANT]
> If the module has any issues, unlist the version in the [PowerShell Gallery][ctk-psg].

2. Go to the created release in GitHub and do the following:
    1. Update the release notes.
    2. Verify that all files have been uploaded correctly and the scripts are signed. There should be three files:
        - *containers-toolkit-<RELEASE_TAG>.tar.gz*
        - *containers-toolkit-<RELEASE_TAG>.zip*
        - *containers-toolkit-<RELEASE_TAG>.SHA256*
    3. Publish the release. By default, the release is marked as a draft. To publish the release:
        - Click on the **Edit** button.
        - If it is a pre-release, check the **Set as a pre-releasee** checkbox.
        - Finally, click on the **Publish release** button.

[ctk-psg]: https://www.powershellgallery.com/packages/containers-toolkit
