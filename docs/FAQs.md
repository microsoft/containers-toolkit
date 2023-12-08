# FAQs

## Table of Contents

- [Uninstall Error (Access to path denied)](#resolving-uninstall-error-access-to-path-denied)

<br />

## Resolving uninstall error (Access to path denied)

<details>

<summary>Resolving uninstall error (Access to path denied)</summary>

If you encounter an Access to path denied error during the uninstall process, even with Administrator privileges, it typically stems from issues with folder ownership. To resolve this, you'll need to reassign ownership to an account with administrative privileges. You can accomplish this using the `takeown` command.

Example:

```PowerShell
takeown /f "C:\ProgramData\containerd" /r /d Y
```

After successfully changing the ownership, you can proceed to remove the folder manually.

If the issue persists, navigate to the folder's properties and choose the option to `Replace all child object permission entries with inheritable permission entries from this object`. This action will apply the inheritable permissions set on this folder to all sub-folders and files within it.

![alt text](../assets/child-object-permission.png)

1. Navigate to the folder.
2. Right-click on the folder and choose **Properties**.
3. Go to the **Security** tab.
4. Click on **Advanced**.
5. In the Advanced Security Settings, select the option `Replace all child object permission entries with inheritable permission entries from this object`.
6. Apply the changes and confirm.

</details>
