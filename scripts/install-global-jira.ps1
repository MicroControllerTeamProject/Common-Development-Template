param(
    [string]$HooksPath = 'C:\GitHooks',
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

try {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw 'Git non e disponibile nel PATH.'
    }

    $source = Join-Path (Split-Path -Parent $PSScriptRoot) 'hooks\prepare-commit-msg'
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
        throw "Hook sorgente mancante: $source"
    }

    $destinationRoot = [System.IO.Path]::GetFullPath($HooksPath)
    $gitPath = $destinationRoot.Replace('\', '/').TrimEnd('/')
    $currentPath = (& git config --global --get core.hooksPath 2>$null | Out-String).Trim()

    if ($currentPath) {
        $normalizedCurrent = $currentPath.Replace('\', '/').TrimEnd('/')
        if ($normalizedCurrent -ine $gitPath) {
            throw "core.hooksPath globale e gia '$currentPath'. Non lo sostituisco per evitare di disattivare altri hook. Verifica prima la configurazione esistente."
        }
    }

    $target = Join-Path $destinationRoot 'prepare-commit-msg'
    if (Test-Path -LiteralPath $target -PathType Leaf) {
        $sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
        $targetHash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
        if ($sourceHash -ne $targetHash) {
            if (-not $Force) {
                throw "Il file '$target' e gia presente ed e diverso. Usa -Force per farne un backup e sostituirlo."
            }
            $backup = "$target.bak.$(Get-Date -Format 'yyyyMMddHHmmssfff')"
            Copy-Item -LiteralPath $target -Destination $backup
            Write-Host "Backup creato: $backup"
        } else {
            Write-Host "Hook gia aggiornato: $target"
        }
    }

    New-Item -Path $destinationRoot -ItemType Directory -Force | Out-Null
    Copy-Item -LiteralPath $source -Destination $target -Force

    & git config --global core.hooksPath $gitPath
    if ($LASTEXITCODE -ne 0) {
        throw 'Impossibile impostare core.hooksPath globale.'
    }

    $verified = (& git config --global --get core.hooksPath | Out-String).Trim()
    if ($verified -ine $gitPath) {
        throw "Verifica fallita: core.hooksPath risulta '$verified'."
    }

    Write-Host "OK - Hook Jira installato in $target"
    Write-Host "OK - core.hooksPath globale = $verified"
    Write-Host 'Funziona in tutti i repository senza una configurazione locale incompatibile.'
    Write-Host 'Per escludere un repository: git config --local common.jira.enabled false'
    exit 0
}
catch {
    Write-Error $_
    exit 1
}
