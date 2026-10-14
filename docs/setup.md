# Installazione e regole operative

## Installare in un repository esistente

1. Clona `Common-Development-Template` sul PC Windows.
2. Apri **CMD** nella cartella del Common ed esegui:

```bat
scripts\install-common.bat -ProjectPath "C:\Progetti\MioRepository" -Modules all
```

`-Modules release` installa solo la policy delle release. `-Modules jira` installa workflow Jira e Git hook. Ripeti il comando per altri progetti. Con `-Force` sovrascrivi i file differenti **dopo backup**; senza il flag non vengono toccati. Controlla `git status` e fai commit dei file installati, inclusa la cartella `.githooks`; il valore `core.hooksPath` e configurato solo nel clone locale, dunque **ogni sviluppatore deve attivarlo sul suo PC** (o installarlo con lo stesso batch).

## Branch e Jira

| Branch | Scopo |
| --- | --- |
| `develop` | Integrazione continua dello sviluppo |
| `feature/GS-5-descrizione` | Feature collegata alla issue Jira GS-5 |
| `bugfix/GS-6-descrizione` | Correzione collegata a Jira |
| `release/1.0.0` | Preparazione della versione |
| `main` | Versioni rilasciate |

Il modulo Jira controlla che le branch `feature/*`, `bugfix/*`, `fix/*`, `hotfix/*`, `task/*` contengano una chiave come `GS-5` nelle **pull request**. La chiave viene aggiunta automaticamente al primo rigo del messaggio di commit tramite hook **locale**, nel formato `GS-5 Descrizione` (senza due punti); non modifica l'issue Jira e non sostituisce l'integrazione **GitHub for Jira** da abilitare nell'istanza Jira.

Il flusso normale e `feature/* -> develop -> release/* -> main`. Il workflow `branch-policy.yml` blocca il check delle PR verso `main` se la sorgente non e `release/*` dello stesso repository.

## Applicare effettivamente il blocco su GitHub

Per ogni repository, in **Settings -> Rules -> Rulesets** (oppure **Branches / Branch protection rules**, in base al piano e all'interfaccia):

- Proteggi `main`, richiedi pull request e rendi obbligatorio **Validate source branch**.
- Proteggi `develop` se vuoi vietare push diretti e richiedi **Validate Jira issue key** se il progetto usa Jira.
- Evita bypass amministrativi non necessari e applica le regole anche ai soggetti che potrebbero aggirarle, se disponibile.
- Verifica il blocco con una PR `develop -> main` (deve fallire) e una `release/1.0.0 -> main` (il check deve passare). **Il check GitHub Actions senza ruleset obbligatorio non blocca i merge.**

In repository pubblici, le funzionalita di ruleset/protezione dipendono dal piano GitHub e dalle impostazioni del repository. Per il collegamento Jira-GitHub, installa/configura l'integrazione nell'istanza Jira con accesso ai repository opportuni. Non sono richiesti token Jira nei workflow qui inclusi.

## Limiti e aggiornamenti

- GitHub Actions verifica le PR remote; il Git hook modifica i messaggi **solo nei cloni locali configurati**, non via interfaccia web o altri cloni.
- Se il repository possiede gia altri hook, non usare `-Force` senza verificare l'effetto del cambio di `core.hooksPath`: un nuovo percorso puo disattivare quelli precedenti. Se necessario, combina gli hook manualmente.
- Per aggiornare i file installati, esegui il batch dal Common aggiornato, verifica il diff e poi committa le modifiche.
- **Non sono moduli comuni**: `firmware-ci.yml` (compilatore, FQBN, librerie), `GenerateGitVersion.bat` (identificativo build AVR), `board.txt` e `.gitignore` dedicati a `GitVersion.h`: rimangono in AVR-Firmware-Template.
