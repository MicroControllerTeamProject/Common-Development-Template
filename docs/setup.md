# Configurazione Common: Git locale, GitHub e Jira

## 1. Hook Jira globale su Windows 11

Dal clone aggiornato di Common, in CMD:

```bat
scripts\install-global-jira.bat
git config --global --get core.hooksPath
```

Risultato atteso: `C:/GitHooks`. Il batch copia `hooks/prepare-commit-msg` in `C:\GitHooks\prepare-commit-msg`, senza estensione. Git for Windows lo esegue automaticamente tramite la shell inclusa in Git. SourceTree usa il medesimo Git solo se configurato a utilizzare quell'installazione o una configurazione globale equivalente.

La procedura e idempotente: se il file coincide non serve altro; se esiste un file diverso, il batch si ferma senza modificarlo. Con `-Force` ne crea prima una copia `.bak.<timestamp>`. Se `core.hooksPath` globale punta gia a un'altra cartella, l'installer si ferma per non disattivare hook gia esistenti: analizza e integra gli hook prima di modificarlo.

Il controllo locale applica il pattern **`[A-Z][A-Z0-9]*-[0-9]+`** con delimitatori nel nome branch. Esempi:

| Branch | Messaggio scritto | Risultato |
| --- | --- | --- |
| `feature/GS-5-sms` | `Fix ricezione SMS` | `GS-5 Fix ricezione SMS` |
| `feature/GS-5-sms` | `GS-5: Fix SMS` | `GS-5 Fix SMS` |
| `feature/GS-5-sms` | `GS-5 Fix SMS` | Invariato |
| `develop` | `Fix SMS` | Invariato |
| `release/1.0.0` | `Release pronta` | Invariato |

L'hook non modifica commit Git di merge, squash e amend, né gli altri tipi di commit che non hanno una chiave Jira nella branch. Per disabilitarlo in un singolo repository non Jira: `git config --local common.jira.enabled false`. Per riattivarlo: `git config --local --unset common.jira.enabled`.

Se un repository ha un `core.hooksPath` **locale**, questo prevale sulla configurazione globale. Verifica dalla root del progetto con:

```bat
git config --show-origin --get core.hooksPath
```

Non rimuovere a caso un hook locale gia esistente. Se la configurazione locale `.githooks` deriva dal precedente installatore e non contiene altri hook necessari, si puo eliminare con `git config --local --unset core.hooksPath`.

## 2. Workflow di un repository (AVR oppure altro)

Dalla root del clone Common:

```bat
scripts\install-common.bat -ProjectPath "C:\Progetti\MioRepository" -Modules all
```

Il comando copia soltanto `.github/workflows/branch-policy.yml` e `.github/workflows/jira-traceability.yml`. `-Modules release` e `-Modules jira` consentono di copiarne uno solo. I file esistenti differenti vengono preservati; usa `-Force` per creare una copia di backup e aggiornarli. Esegui `git status`, verifica le differenze, poi fai commit e push.

Flusso: `feature/GS-5-descrizione` → `develop` → `release/1.0.0` → `main`. Il workflow Jira verifica la chiave delle branch `feature/*`, `bugfix/*`, `fix/*`, `hotfix/*`, `task/*`; la policy verso `main` richiede una PR da `release/*` dello stesso repository.

## 3. Protezioni remote e integrazione Jira

Per bloccare realmente le PR non autorizzate, crea la protezione di `main` nelle impostazioni **Settings > Rules > Rulesets** del repository GitHub, richiedendo PR e il check obbligatorio **Validate source branch**. Se proteggi `develop`, puoi rendere obbligatorio il check **Validate Jira issue key**, assicurandoti che il workflow sia in esecuzione sulle PR interessate. I controlli GitHub Actions non impediscono i merge da soli; le protezioni dipendono anche dal piano e dalle impostazioni del repository.

Collega GitHub all'istanza Jira mediante **GitHub for Jira**, autorizzando i repository appropriati. Il Git hook genera un riferimento testuale; da solo non crea issue né aggiorna automaticamente Jira. Non sono richiesti token Jira nei file di questo Common.

## 4. Aggiornamenti e limiti

- **Hook locale**: aggiornalo in `C:\GitHooks` con `scripts\install-global-jira.bat -Force` dopo aver fatto `git pull` del Common.
- **Workflow per repository**: esegui nuovamente `scripts\install-common.bat`, verifica i diff e aggiorna con `-Force` se opportuno.
- `firmware-ci.yml`, `GenerateGitVersion.bat`, `board.txt`, configurazioni FQBN e librerie rimangono specifiche di **AVR-Firmware-Template**.
