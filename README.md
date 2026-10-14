# Common Development Template

Standard **Git / GitHub / Jira** riutilizzabili in qualsiasi progetto (AVR e non AVR).

| Modulo | Funzione | Installazione |
| --- | --- | --- |
| **release** | PR verso `main` consentite solo da `release/*` | Workflow GitHub |
| **jira** | Controllo chiave Jira nelle branch di lavoro; chiave inserita automaticamente nei commit locali | Workflow + Git hook |

## Applicazione a un repository esistente (Windows)

Clona questo repository, poi esegui da un prompt:

```bat
scripts\install-common.bat -ProjectPath "C:\percorso\progetto" -Modules all
```

Moduli alternativi: `release` oppure `jira`. I file esistenti **non vengono sovrascritti**; per aggiornare usa `-Force` (crea backup). La configurazione del Git hook è **locale al progetto**, non globale.

## Regole essenziali

- Sviluppo: `feature/GS-5-descrizione` → `develop` → `release/1.0.0` → `main`.
- La chiave Jira (`GS-5`) compare nella branch e viene anteposta ai commit in locale (esempio: `GS-5: fix SMS buffer`).
- **Per bloccare davvero i merge**, configura le *branch protection/rulesets* di GitHub con i controlli obbligatori. Il solo YAML non impedisce un merge.
- Il collegamento automatico degli sviluppi alle issue Jira richiede inoltre l'integrazione **GitHub for Jira** configurata su Jira.

**[Istruzioni operative e configurazione](docs/setup.md)** · Il modulo `firmware-ci.yml`, `board.txt` e `GenerateGitVersion.bat` restano specifici di **AVR-Firmware-Template**.
