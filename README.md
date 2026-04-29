# PowerShell Profile Utilities

This profile adds helper commands for Git, navigation, diagnostics, and daily developer workflows.
It is designed to stay portable and avoid user-specific hardcoded paths.

## Files

- `Microsoft.PowerShell_profile.ps1`: main profile script.
- `UserVars.ps1`: user variables (paths and other personal environment values).
- `UserProfileExtensions.ps1`: user-specific settings and methods.

## Startup behavior

On startup, the profile:

- looks for `UserVars.ps1` and `UserProfileExtensions.ps1` in:
  - `$HOME\Documents\WindowsPowerShell\`
  - `$HOME\Documents\PowerShell\`
  - profile script folder (`$PSScriptRoot`)
- creates missing files automatically
- writes minimal required defaults into a newly created `UserVars.ps1`:
  - `$user = $HOME`
  - `$repos = Join-Path $user "source\repos"`
- prints guidance so you can complete your own values/settings
- dot-sources both files
- changes location to `$repos` only when it exists

## What to put in user files

- `UserVars.ps1`: variables like `$repos`, `$desktop`, `$documents`, `$downloads`, project path shortcuts, etc.
- `UserProfileExtensions.ps1`: user preferences and optional custom functions, for example:
  - `[System.Globalization.CultureInfo]::CurrentCulture = 'sl-SI'`

## Key functions

- `G_CleanReset`: fetches, hard-resets to upstream branch, previews ignored and untracked cleanup separately, and asks for confirmation before deletion.
- `G_BranchCleanup <KeepBranch>`: prunes remotes and interactively asks per merged branch whether to delete it.
- `G_DefaultOriginBranch`: detects remote default branch.
- `G_FetchReset [path]`: fetches and pulls latest changes for repo path.
- `G_Push "message"`: stages, commits, and pushes current branch with confirmation.
- `G_Init <originUrl>`: initializes repository and links remote origin.
- `G_CopyBranch`: copies current branch name to clipboard.

## Notes

- Keep credentials/secrets out of profile scripts.
- Prefer `$HOME`, `$env:USERPROFILE`, and `Join-Path` over absolute user paths.
- Review branch and cleanup prompts carefully before confirming delete operations.
