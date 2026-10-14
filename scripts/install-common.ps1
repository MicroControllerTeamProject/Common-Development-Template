param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,

    [ValidateSet('all', 'release', 'jira')]
    [string]$Modules = 'all',

    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$sourceRoot = (Resolve-Path -LiteralPath (Split-Path -Parent $PSScriptRoot)).Path
$script:skipped = 0

function Install-File {
    param([string]$RelativeSource, [string]$RelativeDestination)

    $source = Join-Path $sourceRoot $RelativeSource
    $destination = Join-Path $repoRoot $RelativeDestination
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
        throw "File sorgente mancante: $source"
    }
    if (Test-Path -LiteralPath $destination -PathType Leaf) {
        if ((Get-FileHash -LiteralPath $source).Hash -eq (Get-FileHash -LiteralPath $destination).Hash) {
            Write-Host "OK (gia presente): $RelativeDestination"
            return $true
        }
        if (-not $Force) {
            Write-Warning "File diverso, non sovrascritto: $RelativeDestination (usa -Force)"
            $script:skipped++
            return $false
        }
        $backup = "$destination.bak.$(Get-Date -Format 'yyyyMMddHHmmssfff')"
        Copy-Item -LiteralPath $destination -Destination $backup
        Write-Host "Backup: $backup"
    }

    $parent = Split-Path -Parent $destination
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
    Copy-Item -LiteralPath $source -Destination $destination -Force
    Write-Host "Installato: $RelativeDestination"
    return $true
}

try {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw "Git non e disponibile nel PATH."
    }
    $requestedPath = (Resolve-Path -LiteralPath $ProjectPath).Path
    $gitRoot = & git -C $requestedPath rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $gitRoot) {
        throw "La destinazione deve essere un repository Git esistente."
    }
    $repoRoot = (Resolve-Path -LiteralPath ($gitRoot | Select-Object -First 1)).Path
    if ($repoRoot.TrimEnd('\', '/') -eq $sourceRoot.TrimEnd('\', '/')) {
        throw "Indica un repository di destinazione diverso dal Common."
    }

    Write-Host "Destinazione: $repoRoot"
    if ($Modules -in @('all', 'release')) {
        Install-File '.github/workflows/branch-policy.yml' '.github/workflows/branch-policy.yml' | Out-Null
    }

    if ($Modules -in @('all', 'jira')) {
        Install-File '.github/workflows/jira-traceability.yml' '.github/workflows/jira-traceability.yml' | Out-Null
        Install-File '.githooks/.gitattributes' '.githooks/.gitattributes' | Out-Null
        $hookReady = Install-File '.githooks/commit-msg' '.githooks/commit-msg'
        if ($hookReady) {
            $existingPath = & git -C $repoRoot config --local --get core.hooksPath
            $existingPath = "$existingPath".Trim()
            if ($existingPath -and $existingPath -ne '.githooks' -and -not $Force) {
                Write-Warning "core.hooksPath gia configurato ($existingPath), non modificato. Usa -Force solo dopo aver valutato gli hook precedenti."
                $script:skipped++
            } else {
                & git -C $repoRoot config --local core.hooksPath .githooks
                if ($LASTEXITCODE -ne 0) { throw "Impossibile configurare core.hooksPath." }
                Write-Host 'Git hook Jira attivato localmente.'
            }
        }
    }

    Write-Host 'NOTA: su GitHub configura i check obbligatori e, per Jira, collega GitHub for Jira.'
    if ($script:skipped -gt 0) { exit 2 }
    exit 0
}
catch {
    Write-Error $_
    exit 1
}
