# 🧩 PowerShell Profile Utilities

This profile extends PowerShell with developer-friendly commands for **Git**, **system automation**, and **quick navigation**.
It’s designed to be self-contained and portable — no secrets, no machine-locked paths.

---

## 📁 Structure

| File                               | Purpose                                                                         |
| ---------------------------------- | ------------------------------------------------------------------------------- |
| `Microsoft.PowerShell_profile.ps1` | Main startup script that imports aliases, functions, and user variables.        |
| `UserVars.ps1`                     | Centralized path and user-specific variable definitions (all environment-safe). |

---

## ⚙️ Setup

1. Place both files in your PowerShell profile directory:

   ```
   $PROFILE
   $PROFILE directory: $env:USERPROFILE\Documents\PowerShell\
   ```

2. Adjust any paths inside `UserVars.ps1` to your local structure if needed.

3. Restart PowerShell.

---

## 🧠 Key Functions

### Git Helpers

| Function                      | Description                                                                                |
| ----------------------------- | ------------------------------------------------------------------------------------------ |
| **`G_Push "message"`**        | Stages, commits, and pushes to the current branch. Automatically sets upstream if missing. |
| **`G_FetchReset [path]`**     | Fetches and pulls the latest changes for a repository (default = current folder).          |
| **`G_Init <originUrl>`**      | Initializes a new Git repo, adds remote, and syncs with its default branch.                |
| **`Copy-GitBranch`**          | Copies the current Git branch name to clipboard.                                           |
| **`Get-DefaultOriginBranch`** | Detects the default branch of the remote (`main`, `master`, etc.).                         |

## 🧩 Environment Variables

Defined in **`UserVars.ps1`**, these make the scripts portable:

```powershell
$user      = $env:USERPROFILE
$repos     = Join-Path $user "source\repos"
$desktop   = Join-Path $user "Desktop"
$appdata   = Join-Path $user "AppData"
$documents = Join-Path $user "Documents"
$downloads = Join-Path $user "Downloads"
```

You can extend this with project-specific paths (`$gdrive`, `$rdcs`, etc.), but they are optional.

---

## 🧹 Guidelines

- Avoid running Git operations automatically at shell startup — use functions instead.
- Replace any hard-coded `C:\Users\<User>` paths with `$env:USERPROFILE`.
- No private tokens or credentials should be stored in these scripts.
- Use the included `G_DefaultOriginBranch` to avoid assuming `main`.

---

## 🧩 Example Usage

```powershell
PS> cd $repos\MyProject
PS> G_Push "Fixed logging bug"
Pushed to origin/main.

PS> Copy-GitBranch
Copied branch: main

PS> G_Init https://github.com/YourUser/NewRepo.git
Initialized and synced with origin/main.
```

---

## 🪶 License

Free to use, modify, and share.
