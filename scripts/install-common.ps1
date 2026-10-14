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
    param([string]$RelativePath)

    $source = Join-Path $sourceRoot $RelativePath
    $destination = Join-Path $repoRoot $RelativePath
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
        throw "File sorgente mancante: $source"
    }

    if (Test-Path -LiteralPath $destination -PathType Leaf) {
        if ((Get-FileHash -LiteralPath $source).Hash -eq (Get-FileHash -LiteralPath $destination).Hash) {
            Write-Host "Gia aggiornato: $RelativePath"
            return
        }
        if (-not $Force) {
            Write-Warning "File esistente non sovrascritto: $RelativePath (usa -Force)"
            $script:skipped++
            return
        }
        $backup = "$destination.bak.$(Get-Date -Format 'yyyyMMddHHmmssfff')"
        Copy-Item -LiteralPath $destination -Destination $backup
        Write-Host "Backup: $backup"
    }

    New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
    Copy-Item -LiteralPath $source -Destination $destination -Force
    Write-Host "Installato: $RelativePath"
}

try {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw 'Git non e disponibile nel PATH.'
    }
    $requestedPath = (Resolve-Path -LiteralPath $ProjectPath).Path
    $gitRoot = & git -C $requestedPath rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $gitRoot) {
        throw 'La destinazione deve essere un repository Git esistente.'
    }
    $repoRoot = (Resolve-Path -LiteralPath ($gitRoot | Select-Object -First 1)).Path
    if ($repoRoot.TrimEnd('\', '/') -eq $sourceRoot.TrimEnd('\', '/')) {
        throw 'Indica un repository diverso dal Common.'
    }

    Write-Host "Destinazione: $repoRoot"
    if ($Modules -in @('all', 'release')) {
        Install-File '.github/workflows/branch-policy.yml'
    }
    if ($Modules -in @('all', 'jira')) {
        Install-File '.github/workflows/jira-traceability.yml'
    }

    $localHooks = (& git -C $repoRoot config --local --get core.hooksPath 2>$null | Out-String).Trim()
    if ($localHooks) {
        Write-Warning "Questo repository ha core.hooksPath locale = '$localHooks': prevale su quello globale. Verifica prima di rimuoverlo."
    }

    Write-Host 'NOTA: le ruleset di GitHub devono rendere obbligatori i check per bloccare i merge.'
    Write-Host 'Gli hook Jira si installano una sola volta sul PC con scripts\install-global-jira.bat.'
    if ($script:skipped -gt 0) { exit 2 }
    exit 0
}
catch {
    Write-Error $_
    exit 1
}
