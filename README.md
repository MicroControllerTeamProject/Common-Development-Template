# Common Development Template

Standard **Git / GitHub / Jira** comuni a progetti AVR, .NET e altri.

| Componente | Installazione | Funzione |
| --- | --- | --- |
| **Hook Jira** | **Una sola volta sul PC** | Aggiunge la issue key ai commit locali |
| **Release Policy** | In ogni repository GitHub | Ammette verso `main` solo PR da `release/*` |
| **Jira workflow** | In ogni repository GitHub | Valida la issue key delle branch nelle PR |

## 1. Configurare Windows (una sola volta)

Clona il Common e avvia **CMD nella cartella Common**:

```bat
scripts\install-global-jira.bat
```

Il batch copia `hooks/prepare-commit-msg` in `C:\GitHooks` e configura `git config --global core.hooksPath C:/GitHooks`. Se un hook diverso esiste, non viene sovrascritto senza `-Force` (crea un backup). Non cambia i singoli repository.

## 2. Installare i workflow GitHub in ogni progetto

```bat
scripts\install-common.bat -ProjectPath "C:\Progetti\MioRepository" -Modules all
```

`-Modules release` o `-Modules jira` selezionano un solo workflow. Non vengono sovrascritti file diversi senza `-Force` (backup automatico). Committa e pubblica i workflow installati.

## Regole

- Branch: `feature/GS-5-descrizione` → `develop` → `release/1.0.0` → `main`.
- Commit: **`GS-5 Descrizione del commit`**, **senza due punti**. Hook basato sulla regex `[A-Z][A-Z0-9]*-[0-9]+`; non modifica i commit sulle branch senza chiave.
- Repo senza Jira: opzionalmente `git config --local common.jira.enabled false`.
- Le **branch protection/ruleset GitHub** devono rendere obbligatori i check: il solo YAML non blocca i merge.
- Per visualizzare branch e commit nelle issue Jira serve l'integrazione **GitHub for Jira**.

[Dettagli e verifiche](docs/setup.md) · I file di compilazione (`firmware-ci.yml`, `board.txt`, `GenerateGitVersion.bat`) restano nel template AVR.
