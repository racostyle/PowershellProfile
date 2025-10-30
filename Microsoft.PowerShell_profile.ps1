if (-not $Host.Name -eq 'ConsoleHost') { 
    # Skip loading the rest of the profile. Without this it will load shell every time any script is run in any program. It is a bubu!
    return
}

# Check if the current session is running as an administrator
# if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
#     Write-Host "Relaunching PowerShell as Administrator..."
#     Start-Process PowerShell -ArgumentList "-NoExit", "-File", $PROFILE -Verb RunAs
#     exit
# }

# Get the parent process name
$parentProcess = (Get-Process -Id (Get-WmiObject Win32_Process -Filter "ProcessId=$PID").ParentProcessId).Name

# Define allowed parent processes (user, task scheduler)
$allowedParents = @('explorer', 'taskeng')
if (-not ($allowedParents -contains $parentProcess)) {
    return
}

Set-Alias gh Get-Help

[System.Console]::WindowWidth = 200
[System.Console]::WindowHeight = 50
[System.Globalization.CultureInfo]::CurrentCulture = 'sl-SI'
$OutputEncoding = [System.Text.Encoding]::UTF8

# Load user data
. "C:\Users\<user>\Documents\WindowsPowerShell\UserVars.ps1"

$host.UI.RawUI.BackgroundColor = "Black"
$host.UI.RawUI.ForegroundColor = "White"

$host.PrivateData.ErrorBackgroundColor = "Gray"
$host.PrivateData.ErrorForegroundColor = "Red"

function gs { git status }
function gss { git status -s }

Set-Location $repos
Clear-Host

#HELPERS
function Go-Back {
    param (
        [string]$inputPath
    )

    # Check if input is valid (must start with two dots and only dots after that)
    if ($inputPath -match '^\.\.+$') {
        $dotCount = ($inputPath.Length - 2)
        $path = ('../' * ($dotCount + 1)).TrimEnd('/')
        Set-Location $path
    }
    else {
        Write-Host "Invalid input. Input should be in the format of '..', '...', '....', etc."
    }
}
Set-Alias bb Go-Back

<#
Example usage of SS:

1. Store the solution in the current directory: SS store
2. List all stored solutions: SS list
3. Open a stored solution by name: SS solutionName 
4. Open a solution file in a directory: SS C:\path\to\directory\
5. Open a specific solution file: SS C:\path\to\solution.sln
6. Open the `.sln` file in the current directory: SS

Notes:
- Case Insensitivity: Solution names are matched without regard to case (e.g., `SS Bcc` and `SS bcc` both work).
- Fallback Behavior: If the input doesn't match a stored solution, the function checks for a valid directory or file path.
#>


# Define where to store the solution paths (e.g., in %appdata%)
$solutionStoragePath = "$env:APPDATA\StartSlnSolutions.json"

function SSEdit(){
    if (Test-Path $solutionStoragePath) {
        Invoke-Item $solutionStoragePath
    } else {
        Write-Host "File does not exit. Store some solutions first"
    }
}

function Open-Solution {
    param (
        [Parameter(Mandatory=$true)]
        [string]$SolutionPath
    )

    if (-not (Test-Path $SolutionPath)) {
        Write-Host "Solution file not found: $SolutionPath" -ForegroundColor Red
        return
    }

    $solutionFile = Get-Item $SolutionPath

    Write-Host "Opening solution: $($solutionFile.FullName)" -ForegroundColor Green
    Invoke-Expression "Start-Process 'devenv.exe' -ArgumentList '$($solutionFile.FullName)' -Verb RunAs"
    $host.UI.RawUI.WindowTitle = "$($solutionFile.Name)"
}

function SS {

    if (-not (Test-Path $solutionStoragePath)) {
        New-Item -ItemType File -Path $solutionStoragePath -Force | Out-Null
        Set-Content -Path $solutionStoragePath -Value "[]" # Initialize with empty JSON array
    }

    if ($args.Count -gt 0) {
        $input = $args[0]
    } else {
         # If no input is provided, open the .sln file in the current directory
        $currentDirectory = Get-Location
        $solutionFile = Get-ChildItem -Path $currentDirectory -Filter *.sln | Select-Object -First 1

        if ($solutionFile) {
            Open-Solution -SolutionPath $solutionFile.FullName
        } else {
            Write-Host "No .sln file found in the current directory."
        }
        return
    }

    # Handle actions like 'list' or 'store'
    switch ($input.ToLower()) {
        'list' {
            try {
                $solutions = Get-Content -Path $solutionStoragePath -Raw | ConvertFrom-Json
                if (-not $solutions -or $solutions.Count -eq 0) {
                    Write-Host "No solutions stored."
                    return
                }

                Write-Host "Stored Solutions:"
                $maxNameLength = ($solutions | ForEach-Object { $_.Name.Length }) | Measure-Object -Maximum
                $maxNameLength = $maxNameLength.Maximum

                $solutions | ForEach-Object {
                    $namePadded = $_.Name.PadRight($maxNameLength)
                    Write-Host -NoNewline -ForegroundColor Cyan "$namePadded"
                    Write-Host " - $($_.Path)"
                }
            } catch {
                Write-Host "Error reading stored solutions. The storage file may be corrupted."
            }
        }
        'store' {
            $currentDirectory = Get-Location
            $solutionFile = Get-ChildItem -Path $currentDirectory -Filter *.sln | Select-Object -First 1

            if ($solutionFile) {
                $solutionPath = $solutionFile.FullName
                try {
                    $solutions = Get-Content -Path $solutionStoragePath -Raw | ConvertFrom-Json

                    if ($solutions -isnot [array]) {
                        $solutions = @($solutions)  # Wrap into an array if it's a single object
                    }

                    $solutionName = [System.IO.Path]::GetFileNameWithoutExtension($solutionPath)

                    if (-not ($solutions | Where-Object { $_.Path -eq $solutionPath })) {
                        $newSolution = [pscustomobject]@{
                            Name = $solutionName
                            Path = $solutionPath
                        }

                        $solutions += $newSolution

                        $solutions | ConvertTo-Json -Depth 10 | Set-Content -Path $solutionStoragePath -Encoding utf8
                        Write-Host "Stored solution '$solutionName' at '$solutionPath'."
                    } else {
                        Write-Host "Solution '$solutionName' is already stored."
                    }
                } catch {
                    Write-Host "Error storing the solution. The storage file may be corrupted."
                }
            } else {
                Write-Host "No .sln file found in the current directory to store."
            }
        }
        default {
            try {
                # Check if the input is a valid directory with a .sln file
                if ((Test-Path $input) -and (Get-Item $input).PSIsContainer) {
                    $solutionFile = Get-ChildItem -Path $input -Filter *.sln | Select-Object -First 1
                    if ($solutionFile) {
                        Open-Solution -SolutionPath $solutionFile.FullName
                        cd $input
                        return
                    } else {
                        Write-Host "No .sln file found in the directory: $input" -ForegroundColor Red
                        return
                    }
                }

                # Check if the input is a direct path to a .sln file
                if ((Test-Path $input) -and ($input -like "*.sln")) {
                    Open-Solution -SolutionPath $input.FullName
                    cd (Split-Path -Path $input -Parent)
                    return
                }

                $solutions = Get-Content -Path $solutionStoragePath -Raw | ConvertFrom-Json
                $storedSolution = $null

                # Iterate over the solutions to find a match
                foreach ($solution in $solutions) {
                    if ($solution.Name -ieq $input) {
                        $storedSolution = $solution
                        break
                    }
                }

                if (Test-Path $storedSolution.Path) {
                    $path = $storedSolution.Path;
                    # Build the command to run Visual Studio with admin rights
                    $newDirectory = Split-Path -Path $path -Parent
                    Set-Location $newDirectory

                    Open-Solution -SolutionPath $path
                    return
                }
                else {
                    $path = $storedSolution.Path;
                    Write-Host "Solution or folder path '$path' not found."
                }

                # If none of the above, show an error
                Write-Host "Solution or path '$input' not found." -ForegroundColor Red
            } catch {
                Write-Host "Error occurred: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}


#GIT

function G_DefaultOriginBranch {
    try {
        $sym = git symbolic-ref refs/remotes/origin/HEAD 2>$null
        if ($sym) { return ($sym -split '/')[ -1 ] }
        # Fallback: try common names
        foreach ($b in 'main','master','trunk') {
            if (git ls-remote --heads origin $b 2>$null) { return $b }
        }
    } catch {}
    return $null
}

function G_FetchReset {
    param (
        [string]$repositoryPath = "."
    )

    # Ensure the repository path is provided
    if (-not $repositoryPath) {
        Write-Host "Repository path is required"
        return
    }

    # Change directory to the repository path
    Push-Location -Path $repositoryPath

    # Detect the current branch
    $currentBranch = git rev-parse --abbrev-ref HEAD
    
    try {
        # Execute git commands
        git branch --set-upstream-to=origin/$currentBranch
        git fetch origin $currentBranch
        git status
        git pull

        Write-Host "Repository updated successfully."
    }
    catch {
        Write-Host "An error occurred while updating the repository."
    }
    finally {
        Pop-Location
    }
}

function G_Push {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommitMessage
    )
    
    # Get the Git repository root
    $repositoryPath = git rev-parse --show-toplevel 2>$null

    if (-Not $repositoryPath) {
        Write-Host "This directory does not appear to be a Git repository."
        return
    }

    # Check for dubious ownership and add to safe directory if necessary
    $ownershipWarning = git status 2>&1 | Select-String "dubious ownership"
    if ($ownershipWarning) {
        Write-Host "Detected dubious ownership in repository at '$repositoryPath'."
        git config --global --add safe.directory $repositoryPath
        Write-Host "Added '$repositoryPath' to Git safe directory."
    }

    Push-Location $repositoryPath

    try {
        git add .

        Write-Host "Staged changes:"
        git status

        git commit -m "$CommitMessage"

        # Detect current branch
        $currentBranch = git rev-parse --abbrev-ref HEAD

        $confirmation = Read-Host "Are you sure you want to push changes to '$currentBranch'? (y/n)"
        if ($confirmation -eq 'y') {
            # Push changes
            git push origin $currentBranch
            Write-Host "Changes pushed to '$currentBranch'."
        }
        else {
            Write-Host "Commit and Push cancelled."
            git reset HEAD~
        }
    }
    catch {
        Write-Error "An error occurred: $_"
    }
    finally {
        Pop-Location
    }
}


function G_CreateNewBranch {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FeatureName
    )
    
    if (-Not $FeatureName) {
        Write-Error "Feature name is required."
        return
    }

    git checkout -b $FeatureName

    $pushResult = git push -u origin $FeatureName

    if ($pushResult -match "error") {
        Write-Error "Failed to push and track the branch on remote."
    }
    else {
        Write-Host "New feature branch '$FeatureName' created, switched to, and tracking set on remote."
    }
}

# Function to check if the provided Git URL is accessible
function G_TestGitRemoteUrl {
    param (
        [string]$url
    )

    # Check if the URL is accessible and valid
    try {
        $output = git ls-remote $url 2>&1
        if ($output -match "Could not resolve host" -or $output -match "Repository not found") {
            return $false
        }
        return $true
    } catch {
        return $false
    }
}


function G_Init {
    param([Parameter(Mandatory=$true)][string]$originUrl)

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "Git not installed." -ForegroundColor Red; return
    }
    if (-not (G_TestGitRemoteUrl -url $originUrl)) {
        Write-Host "Remote URL invalid or inaccessible." -ForegroundColor Red; return
    }

    git init
    git remote remove origin 2>$null
    git remote add origin $originUrl

    $default = G_DefaultOriginBranch
    if ($default) {
        git fetch origin $default
        try { git checkout -b $default } catch { git checkout $default }
        try { git pull origin $default --allow-unrelated-histories } catch {}
    } else {
        Write-Host "Couldn’t detect default remote branch; staying on current."
    }

    git add .
    git commit -m "Initial commit" 2>$null
    git push -u origin (git rev-parse --abbrev-ref HEAD)
}


# G_BranchCleanup staging
function G_BranchCleanup {
    param (
        [Parameter(Mandatory = $true)]
        [string]$KeepBranch
    )

    Write-Host "Pruning remote tracking branches..." -ForegroundColor Cyan
    git fetch --prune

    Write-Host "Deleting local branches merged into '$KeepBranch'..." -ForegroundColor Cyan
    git branch --merged $KeepBranch | ForEach-Object {
        $branch = $_.Trim()

        # Skip the branch we want to keep
        if ($branch -ne $KeepBranch -and $branch -ne "* $KeepBranch") {
            Write-Host "Removing branch: $branch" -ForegroundColor Yellow
            git branch -d $branch
        }
    }
}

function G_CopyBranch {
    try {
        $branch = git rev-parse --abbrev-ref HEAD 2>$null
        if (-not $branch) {
            Write-Host "Not a Git repository or unable to detect branch." -ForegroundColor Yellow
            return
        }

        Set-Clipboard $branch
        Write-Host "Copied branch: $branch" -ForegroundColor Green
    }
    catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}



#NETWORKING
function Info_Ports {
    # Get all active TCP connections
    $connections = Get-NetTCPConnection

    # Select only the local ports and ensure uniqueness
    $openPorts = $connections | Select-Object -Property LocalPort, State, RemoteAddress, RemotePort | Sort-Object -Property LocalPort -Unique

    # Display the open ports in a table
    $openPorts | Format-Table LocalPort, State, RemoteAddress, RemotePort -AutoSize
}

# DIAGNOSTICS
function Info_SystemStats {
    
    $cpuLoad = Get-WmiObject -Class Win32_Processor | Measure-Object -Property LoadPercentage -Average | Select-Object -ExpandProperty Average

    $totalRAM = (Get-CimInstance -ClassName Win32_OperatingSystem).TotalVisibleMemorySize
    $freeRAM = (Get-CimInstance -ClassName Win32_OperatingSystem).FreePhysicalMemory
    $usedRAM = $totalRAM - $freeRAM
    $ramUsagePercentage = [math]::Round(($usedRAM / $totalRAM) * 100, 2)

    # Get disk usage
    $diskUsage = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3" | 
    Select-Object DeviceID, 
    @{Name = "TotalSize"; Expression = { [math]::Round($_.Size / 1GB, 2) } }, 
    @{Name = "FreeSpace"; Expression = { [math]::Round($_.FreeSpace / 1GB, 2) } }, 
    @{Name = "UsedSpace"; Expression = { [math]::Round(($_.Size - $_.FreeSpace) / 1GB, 2) } }, 
    @{Name = "Percentage"; Expression = { [math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 2) } }

    Write-Host ""
    Write-Host "===== CPU Usage ====="
    Write-Host "Average CPU Load: $cpuLoad%"
    Write-Host ""
    Write-Host "===== RAM Usage ====="
    Write-Host "Total RAM: $([math]::Round($totalRAM / 1MB, 2)) GB"
    Write-Host "Used RAM: $([math]::Round($usedRAM / 1MB, 2)) GB"
    Write-Host "Free RAM: $([math]::Round($freeRAM / 1MB, 2)) GB"
    Write-Host "RAM Usage: $ramUsagePercentage%"
    Write-Host ""
    Write-Host "===== Disk Usage (in MB) ====="
    $diskUsage | Format-Table DeviceID, 'TotalSize', 'FreeSpace', 'UsedSpace', 'Percentage' -AutoSize
    Write-Host ""
}

function Info_PingQuick {
    param (
        [string]$TargetHost = "8.8.8.8"  # Default to Google's DNS server for ping
    )

    Write-Host ""
    Write-Host "===== Ping Stats ====="
    try {
        $pingResult = Test-Connection -ComputerName $TargetHost -Count 4 -ErrorAction Stop

        # Display ping results
        $pingResult | ForEach-Object {
            Write-Host "Reply from $($_.Address): time=$($_.ResponseTime)ms"
        }
    }
    catch {
        Write-Host "Ping failed: $_"
    }
    Write-Host "" 
}

function Info_PingLong {
    param (
        [string]$TargetHost = "8.8.8.8"  # Default to Google's DNS server for ping
    )

    Write-Host ""
    Write-Host "===== Ping Stats ====="

    # Array to store the ping response times
    $responseTimes = @()

    # Perform ping 10 times, with 1 second between each ping
    for ($i = 1; $i -le 10; $i++) {
        try {
            $pingResult = Test-Connection -ComputerName $TargetHost -Count 1 -ErrorAction Stop
            $responseTimes += $pingResult.ResponseTime
            Write-Host "Reply from $($pingResult.Address): time=$($pingResult.ResponseTime)ms"
        }
        catch {
            Write-Host "Ping failed: $_"
        }
        Start-Sleep -Seconds 1
    }

    if ($responseTimes.Count -gt 0) {
        $avgTime = [math]::Round(($responseTimes | Measure-Object -Average).Average, 2)
        $minTime = $responseTimes | Measure-Object -Minimum | Select-Object -ExpandProperty Minimum
        $maxTime = $responseTimes | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum

        Write-Host ""
        Write-Host "===== Ping Statistics ====="
        Write-Host "Average Response Time: $avgTime ms"
        Write-Host "Lowest Response Time: $minTime ms"
        Write-Host "Highest Response Time: $maxTime ms"
    }
    else {
        Write-Host "No successful pings."
    }
    Write-Host "" 
}

# UTILITY

# Function to copy the current path to clipboard
Add-Type -AssemblyName System.Windows.Forms
function U_Copy {
    $currentPath = Get-Location
    [System.Windows.Forms.Clipboard]::SetText($currentPath)
    Write-Output "Current path '$currentPath' copied to clipboard."
}

# Function to schedule a shutdown with an optional time in minutes (default is 15)
function U_Shutdown {
    param (
        [int]$Minutes = 15
    )
    $seconds = $Minutes * 60
    Stop-Process -Name "shutdown" -ErrorAction SilentlyContinue # Stop any previous shutdowns
    Start-Process -FilePath "shutdown" -ArgumentList "/s /t $seconds"
    Write-Output "Shutdown scheduled in $Minutes minutes."
}

