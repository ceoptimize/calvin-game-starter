#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$UnitySkills = @(
    "unity-foundations",
    "unity-lifecycle",
    "unity-game-architecture",
    "unity-multiplayer",
    "unity-graphics",
    "unity-lighting-vfx",
    "unity-physics",
    "unity-input",
    "unity-animation",
    "unity-cinemachine",
    "unity-performance",
    "unity-level-design"
)
$GameDevSkills = @("game-feel", "create-game-assets")
$DiscoverySkills = @("find-skills")
$SkillAgents = @("claude-code", "codex")
$Results = New-Object System.Collections.Generic.List[object]
$WingetAvailable = $false

function Refresh-Path {
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $pathParts = New-Object System.Collections.Generic.List[string]
    foreach ($pathValue in @($env:Path, $machinePath, $userPath)) {
        if (-not [string]::IsNullOrWhiteSpace($pathValue)) {
            foreach ($pathPart in ($pathValue -split ';')) {
                if (-not [string]::IsNullOrWhiteSpace($pathPart) -and $pathParts -notcontains $pathPart) {
                    $pathParts.Add($pathPart)
                }
            }
        }
    }
    $env:Path = $pathParts -join ';'
}

function Test-Command {
    param([Parameter(Mandatory = $true)][string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function New-StepOutcome {
    param(
        [Parameter(Mandatory = $true)][string]$Result,
        [Parameter(Mandatory = $true)][string]$Detail
    )
    return [pscustomobject]@{ Result = $Result; Detail = $Detail }
}

function Add-StepResult {
    param(
        [Parameter(Mandatory = $true)][string]$Step,
        [Parameter(Mandatory = $true)][string]$Result,
        [Parameter(Mandatory = $true)][string]$Detail
    )
    $script:Results.Add([pscustomobject]@{ Step = $Step; Result = $Result; Detail = $Detail })
    Write-Host ("[{0}] {1}: {2}" -f $Result, $Step, $Detail)
}

function Invoke-Step {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][scriptblock]$Action
    )

    try {
        $outcome = & $Action
        if ($null -eq $outcome) {
            throw "The step did not return an outcome."
        }
        $allowedResults = @("installed", "already present", "updated", "failed", "manual")
        if ($allowedResults -notcontains $outcome.Result) {
            throw "The step returned an invalid result: $($outcome.Result)"
        }
        Add-StepResult -Step $Name -Result $outcome.Result -Detail $outcome.Detail
    }
    catch {
        Add-StepResult -Step $Name -Result "failed" -Detail $_.Exception.Message
    }
}

function Compare-Version {
    param(
        [Parameter(Mandatory = $true)][string]$A,
        [Parameter(Mandatory = $true)][string]$B
    )
    $cleanA = (($A -replace '^[vV]', '') -split '-', 2)[0]
    $cleanB = (($B -replace '^[vV]', '') -split '-', 2)[0]
    return ([version]$cleanA).CompareTo([version]$cleanB)
}

function Resolve-Launcher {
    param([Parameter(Mandatory = $true)][string]$Name)

    foreach ($candidate in @("${Name}.cmd", "${Name}.exe", $Name)) {
        $command = Get-Command $candidate -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($null -ne $command) {
            return $command.Source
        }
    }
    return $null
}

function Get-SkillRoot {
    param([Parameter(Mandatory = $true)][string]$Agent)

    if ($Agent -eq "claude-code") {
        if (-not [string]::IsNullOrWhiteSpace($env:CLAUDE_CONFIG_DIR)) {
            $configRoot = $env:CLAUDE_CONFIG_DIR
        }
        else {
            $configRoot = Join-Path $env:USERPROFILE ".claude"
        }
    }
    elseif ($Agent -eq "codex") {
        if (-not [string]::IsNullOrWhiteSpace($env:CODEX_HOME)) {
            $configRoot = $env:CODEX_HOME
        }
        else {
            $configRoot = Join-Path $env:USERPROFILE ".codex"
        }
    }
    else {
        throw "Unsupported skills agent: $Agent"
    }

    return (Join-Path $configRoot "skills")
}

function Invoke-NativeCommand {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [string[]]$Arguments = @(),
        [int[]]$OkExitCodes = @(0),
        [switch]$AllowFailure
    )

    $ErrorActionPreference = "Continue"
    if (Test-Path variable:PSNativeCommandUseErrorActionPreference) {
        $PSNativeCommandUseErrorActionPreference = $false
    }
    $output = & $FilePath @Arguments 2>&1
    $exitCode = $LASTEXITCODE
    $text = ($output | Out-String).Trim()
    if ($AllowFailure) {
        return [pscustomobject]@{ ExitCode = $exitCode; Output = $text }
    }
    if ($OkExitCodes -notcontains $exitCode) {
        if ([string]::IsNullOrWhiteSpace($text)) {
            throw "${FilePath} failed with exit code $exitCode."
        }
        throw "${FilePath} failed with exit code ${exitCode}: $text"
    }
    return $text
}

function Install-WingetPackage {
    param([Parameter(Mandatory = $true)][string]$Id)

    $null = Invoke-NativeCommand "winget" @("install", "--id", $Id, "-e", "--silent", "--accept-source-agreements", "--accept-package-agreements") -OkExitCodes @(0, -1978335189)
    Refresh-Path
}

function Install-MissingSkills {
    param(
        [Parameter(Mandatory = $true)][string]$Repo,
        [Parameter(Mandatory = $true)][string[]]$Skills,
        [Parameter(Mandatory = $true)][string[]]$Agents
    )

    $missingByAgent = @{}
    foreach ($agent in $Agents) {
        $skillRoot = Get-SkillRoot -Agent $agent

        $agentMissing = @($Skills | Where-Object {
            $skillFile = Join-Path $skillRoot "$_\SKILL.md"
            -not (Test-Path -LiteralPath $skillFile)
        })
        if ($agentMissing.Count -gt 0) {
            $missingByAgent[$agent] = $agentMissing
        }
    }

    if ($missingByAgent.Count -eq 0) {
        return (New-StepOutcome "already present" "All requested skills are already present.")
    }

    $npxLauncher = Resolve-Launcher "npx"
    if ([string]::IsNullOrWhiteSpace($npxLauncher)) {
        throw "npx is unavailable. Install Node.js LTS, then re-run."
    }
    $installedGroups = @()
    foreach ($agent in $Agents) {
        if (-not $missingByAgent.ContainsKey($agent)) {
            continue
        }

        $agentMissing = @($missingByAgent[$agent])
        $arguments = @("--yes", "skills", "add", $Repo, "--skill") + $agentMissing + @("--agent", $agent, "--global", "--copy", "--yes")
        $installerOutput = Invoke-NativeCommand $npxLauncher $arguments
        $skillRoot = Get-SkillRoot -Agent $agent
        $stillMissing = @($agentMissing | Where-Object {
            $skillFile = Join-Path $skillRoot "$_\SKILL.md"
            -not (Test-Path -LiteralPath $skillFile)
        })
        if ($stillMissing.Count -gt 0) {
            throw "The skills installer did not create for ${agent}: $($stillMissing -join ', '). Installer output: $installerOutput"
        }
        $installedGroups += "${agent}: $($agentMissing -join ', ')"
    }
    return (New-StepOutcome "installed" "Installed missing skills: $($installedGroups -join '; ').")
}

Invoke-Step "winget" {
    Refresh-Path
    $script:WingetAvailable = Test-Command "winget"
    if ($script:WingetAvailable) {
        New-StepOutcome "already present" "App Installer and winget are available."
    }
    else {
        New-StepOutcome "failed" "Install App Installer from the Microsoft Store, then re-run."
    }
}

Invoke-Step "PowerShell script policy" {
    $machinePolicy = Get-ExecutionPolicy -Scope MachinePolicy
    $userPolicy = Get-ExecutionPolicy -Scope UserPolicy
    $currentUser = Get-ExecutionPolicy -Scope CurrentUser
    $localMachine = Get-ExecutionPolicy -Scope LocalMachine

    if ($machinePolicy -ne "Undefined" -or $userPolicy -ne "Undefined") {
        $groupPolicy = $machinePolicy
        if ($groupPolicy -eq "Undefined") {
            $groupPolicy = $userPolicy
        }
        if ($groupPolicy -eq "Restricted" -or $groupPolicy -eq "AllSigned") {
            New-StepOutcome "manual" "A group policy restricts PowerShell scripts on this PC; ask a parent to change it or use codex.cmd and npx.cmd"
        }
        else {
            New-StepOutcome "already present" "The persistent PowerShell execution policy is $groupPolicy."
        }
    }
    else {
        $persistent = $currentUser
        if ($persistent -eq "Undefined") {
            $persistent = $localMachine
        }
        if ($persistent -eq "Undefined") {
            $persistent = "Restricted"
        }

        if ($persistent -eq "Restricted") {
            try {
                Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
                New-StepOutcome "installed" "PowerShell can now run the helper scripts that Node installs (needed by codex and npx)."
            }
            catch {
                $currentUserAfterSet = Get-ExecutionPolicy -Scope CurrentUser
                if ($currentUserAfterSet -eq "RemoteSigned") {
                    New-StepOutcome "installed" "PowerShell can now run the helper scripts that Node installs (needed by codex and npx)."
                }
                else {
                    New-StepOutcome "manual" "Ask a parent to run: Set-ExecutionPolicy -Scope CurrentUser RemoteSigned"
                }
            }
        }
        elseif ($persistent -eq "AllSigned") {
            New-StepOutcome "manual" "PowerShell on this PC only runs signed scripts. Type codex.cmd and npx.cmd instead of codex and npx, or ask a parent to run: Set-ExecutionPolicy -Scope CurrentUser RemoteSigned"
        }
        else {
            New-StepOutcome "already present" "The persistent PowerShell execution policy is $persistent."
        }
    }
}

Invoke-Step "Git" {
    if (Test-Command "git") {
        New-StepOutcome "already present" "Git is available."
    }
    elseif (-not $script:WingetAvailable) {
        New-StepOutcome "manual" "Install App Installer, then re-run to install Git."
    }
    else {
        Install-WingetPackage -Id "Git.Git"
        if (-not (Test-Command "git")) { throw "Git was installed but is not available on PATH." }
        New-StepOutcome "installed" "Git was installed."
    }
}

Invoke-Step "Node.js LTS" {
    $minimumNodeVersion = "22.20.0"
    $wasPresent = Test-Command "node"
    if (-not $wasPresent) {
        if (-not $script:WingetAvailable) {
            New-StepOutcome "manual" "Install App Installer, then re-run to install Node.js LTS."
            return
        }
        Install-WingetPackage -Id "OpenJS.NodeJS.LTS"
        if (-not (Test-Command "node")) { throw "Node.js was installed but is not available on PATH." }
    }

    $versionOutput = Invoke-NativeCommand "node" @("--version")
    if ($versionOutput -notmatch '^v?(\d+\.\d+\.\d+(?:-[^\s]+)?)') {
        throw "Could not read the Node.js version from: $versionOutput"
    }
    $installedVersion = $Matches[1]
    $originalVersion = $installedVersion
    if ((Compare-Version $installedVersion $minimumNodeVersion) -lt 0 -and $script:WingetAvailable) {
        Install-WingetPackage -Id "OpenJS.NodeJS.LTS"
        $versionOutput = Invoke-NativeCommand "node" @("--version")
        if ($versionOutput -notmatch '^v?(\d+\.\d+\.\d+(?:-[^\s]+)?)') {
            throw "Could not read the Node.js version after the update: $versionOutput"
        }
        $installedVersion = $Matches[1]
    }

    $npmLauncher = Resolve-Launcher "npm"
    if ([string]::IsNullOrWhiteSpace($npmLauncher)) {
        throw "Node.js is installed, but npm is unavailable on PATH. Repair or reinstall Node.js LTS."
    }

    if ((Compare-Version $installedVersion $minimumNodeVersion) -lt 0) {
        New-StepOutcome "manual" "Node is $installedVersion; install Node.js LTS 22.20 or newer from nodejs.org"
    }
    elseif (-not $wasPresent) {
        New-StepOutcome "installed" "Node.js $installedVersion was installed."
    }
    elseif ((Compare-Version $originalVersion $minimumNodeVersion) -lt 0) {
        New-StepOutcome "updated" "Node.js was updated from $originalVersion to $installedVersion."
    }
    else {
        New-StepOutcome "already present" "Node.js $installedVersion meets the minimum version."
    }
}

Invoke-Step "uv" {
    if (Test-Command "uvx") {
        New-StepOutcome "already present" "uvx is available."
    }
    elseif (-not $script:WingetAvailable) {
        New-StepOutcome "manual" "Install App Installer, then re-run to install uv."
    }
    else {
        Install-WingetPackage -Id "astral-sh.uv"
        if (-not (Test-Command "uvx")) { throw "uv was installed but uvx is not available on PATH." }
        New-StepOutcome "installed" "uv was installed."
    }
}

Invoke-Step "Unity Hub" {
    $unityHubPaths = @()
    if (-not [string]::IsNullOrWhiteSpace($env:ProgramFiles)) {
        $unityHubPaths += Join-Path $env:ProgramFiles "Unity Hub\Unity Hub.exe"
    }
    if (-not [string]::IsNullOrWhiteSpace(${env:ProgramFiles(x86)})) {
        $unityHubPaths += Join-Path ${env:ProgramFiles(x86)} "Unity Hub\Unity Hub.exe"
    }
    if (-not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
        $unityHubPaths += Join-Path $env:LOCALAPPDATA "Programs\Unity Hub\Unity Hub.exe"
    }
    $unityHubPresent = @($unityHubPaths | Where-Object { Test-Path -LiteralPath $_ }).Count -gt 0
    if ($unityHubPresent) {
        New-StepOutcome "manual" "Unity Hub is already present. Open it, install a Unity 6 (6000.x) editor, then create the project as the README says."
    }
    elseif (-not $script:WingetAvailable) {
        New-StepOutcome "manual" "Install App Installer, then re-run. Open Unity Hub, install a Unity 6 (6000.x) editor, then create the project as the README says."
    }
    else {
        Install-WingetPackage -Id "Unity.UnityHub"
        New-StepOutcome "manual" "Unity Hub was installed. Open Unity Hub, install a Unity 6 (6000.x) editor, then create the project as the README says."
    }
}

Invoke-Step "Claude Code" {
    if (Test-Command "claude") {
        try {
            $updateOutput = Invoke-NativeCommand "claude" @("update")
            if ($updateOutput -match '(?i)up.?to.?date|already.+latest|latest version') {
                New-StepOutcome "already present" "Claude Code is up to date."
            }
            else {
                New-StepOutcome "updated" "Claude Code was updated."
            }
        }
        catch {
            New-StepOutcome "already present" "Claude Code is installed; the update check failed: $($_.Exception.Message)"
        }
    }
    else {
        $null = Invoke-NativeCommand "powershell" @("-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", "irm https://claude.ai/install.ps1 | iex")
        Refresh-Path
        if (-not (Test-Command "claude")) { throw "Claude Code was installed but is not available on PATH." }
        New-StepOutcome "installed" "Claude Code was installed."
    }
}

Invoke-Step "Codex CLI" {
    $codexLauncher = Resolve-Launcher "codex"
    if ([string]::IsNullOrWhiteSpace($codexLauncher)) {
        $npmLauncher = Resolve-Launcher "npm"
        if ([string]::IsNullOrWhiteSpace($npmLauncher)) { throw "npm is unavailable. Install Node.js LTS, then re-run." }
        $null = Invoke-NativeCommand $npmLauncher @("install", "-g", "@openai/codex@latest")
        Refresh-Path
        $codexLauncher = Resolve-Launcher "codex"
        if ([string]::IsNullOrWhiteSpace($codexLauncher)) { throw "Codex was installed but is not available on PATH." }
        New-StepOutcome "installed" "The latest Codex CLI was installed."
    }
    else {
        $versionOutput = Invoke-NativeCommand $codexLauncher @("--version")
        if ($versionOutput -notmatch 'codex-cli\s+([vV]?\d+\.\d+\.\d+(?:-[^\s]+)?)') {
            throw "Could not read the Codex version from: $versionOutput"
        }
        $installedVersion = $Matches[1]
        if ((Compare-Version $installedVersion "0.153.0") -lt 0) {
            $npmLauncher = Resolve-Launcher "npm"
            if ([string]::IsNullOrWhiteSpace($npmLauncher)) { throw "Codex is older than 0.153.0 and npm is unavailable." }
            $null = Invoke-NativeCommand $npmLauncher @("install", "-g", "@openai/codex@latest")
            Refresh-Path
            New-StepOutcome "updated" "Codex was updated from $installedVersion to the latest version."
        }
        else {
            New-StepOutcome "already present" "Codex $installedVersion meets the minimum version."
        }
    }
}

Invoke-Step "Unity skills" {
    Install-MissingSkills -Repo "Nice-Wolf-Studio/unity-claude-skills" -Skills $UnitySkills -Agents $SkillAgents
}

Invoke-Step "Game development skills" {
    Install-MissingSkills -Repo "gamedev-skills/awesome-gamedev-agent-skills" -Skills $GameDevSkills -Agents $SkillAgents
}

Invoke-Step "Skill discovery" {
    Install-MissingSkills -Repo "vercel-labs/skills" -Skills $DiscoverySkills -Agents $SkillAgents
}

Invoke-Step "Unity MCP for Codex" {
    $codexLauncher = Resolve-Launcher "codex"
    if ([string]::IsNullOrWhiteSpace($codexLauncher)) { throw "Codex is unavailable. Install Codex, then re-run." }
    $mcpResult = Invoke-NativeCommand -FilePath $codexLauncher -Arguments @("mcp", "get", "UnityMCP") -AllowFailure
    if ($mcpResult.ExitCode -ne 0) {
        $null = Invoke-NativeCommand $codexLauncher @("mcp", "add", "UnityMCP", "--url", "http://127.0.0.1:8080/mcp")
        New-StepOutcome "installed" "The UnityMCP connection was added to Codex."
    }
    elseif ($mcpResult.Output -match '127\.0\.0\.1:8080/mcp') {
        New-StepOutcome "already present" "The UnityMCP connection is configured."
    }
    else {
        New-StepOutcome "manual" "Codex has an older UnityMCP entry. Run: codex mcp remove UnityMCP, then run this script again."
    }
}

Invoke-Step "Codex sign-in" {
    $codexLauncher = Resolve-Launcher "codex"
    if ([string]::IsNullOrWhiteSpace($codexLauncher)) {
        New-StepOutcome "manual" 'Install Codex, then run `codex login`.'
    }
    else {
        $loginResult = Invoke-NativeCommand -FilePath $codexLauncher -Arguments @("login", "status") -AllowFailure
        if ($loginResult.ExitCode -eq 0) {
            New-StepOutcome "already present" "Codex is signed in."
        }
        else {
            New-StepOutcome "manual" 'Run `codex login`.'
        }
    }
}

Invoke-Step "Claude sign-in" {
    $claudeProfile = Join-Path $env:USERPROFILE ".claude.json"
    if (Test-Path -LiteralPath $claudeProfile) {
        New-StepOutcome "already present" "Claude Code is probably signed in."
    }
    else {
        New-StepOutcome "manual" 'Run `claude` once and sign in.'
    }
}

Write-Host ""
Write-Host "Setup summary"
$Results | Format-Table -AutoSize -Wrap

$remaining = @($Results | Where-Object { $_.Result -eq "manual" -or $_.Result -eq "failed" })
Write-Host "Still to do by hand:"
if ($remaining.Count -eq 0) {
    Write-Host "  Nothing."
}
else {
    foreach ($item in $remaining) {
        Write-Host ("  - {0}: {1}" -f $item.Step, $item.Detail)
    }
}
Write-Host "You can run this script again at any time."

$failedCount = @($Results | Where-Object { $_.Result -eq "failed" }).Count
if ($failedCount -gt 0) {
    exit 1
}
exit 0
