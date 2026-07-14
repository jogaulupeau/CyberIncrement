# Cyber Increment

Jeu **incrémental** sur fond **cyber / hacker solo**, développé avec **Godot 4.4.1** (desktop Windows).
La particularité : on ne se contente pas de cliquer, on **tape des commandes de hack au clavier** — la
frappe est le cœur du gameplay actif.

> Ce fichier = **référence de l'état actuel**. Pour l'historique chronologique des fonctionnalités
> (le « pourquoi » de chaque brique), voir [ROADMAP.md](ROADMAP.md).

---

## Lancer le jeu

- **Éditeur / test** : ouvrir `Godot_v4.4.1-stable_win64.exe`, importer `project.godot`, puis **F5**.
  (Godot est installé chez le dev à `C:\Users\jogau\Desktop\Dev Jeux\`.)
- **Exécutable** : `build/CyberIncrement.exe` — fichier unique autonome (`.pck` embarqué), lançable
  d'un double-clic, partageable sans Godot.
- Fenêtre par défaut : **1498×842** (16:9), `stretch = canvas_items` / `aspect = expand` (tout s'adapte
  au redimensionnement). Réglable dans `project.godot` → `window/size/...`.

## Comment jouer (boucle de jeu)

1. **Taper les commandes** affichées dans le terminal (ou cliquer le terminal pour +1). Chaque bonne
   lettre = des **Données** (`o`, la monnaie principale).
2. Enchaîner sans faute monte le **COMBO**, qui **booste toute la production** (+5 %/palier, plafonné).
   À combo élevé, des **commandes rares** (dorées) apparaissent.
3. Dépenser les Données dans des **générateurs** (production passive).
4. **Compiler l'IA** (prestige) : reset de la run contre des **Fragments d'IA** permanents.
5. Les Fragments débloquent/achètent tout le reste (augmentations, daemons, opérations, réseau…).
6. **Objectif final** : accumuler `AWAKEN_TARGET` Fragments cumulés → taper la **commande d'éveil** →
   écran de **Singularité** (victoire) → mode libre.

**Contrôles** : clavier (frappe des commandes), souris (achats, onglets, boutons ; molette = zoom carte
réseau, clic-glissé = déplacer la carte). Boutons bas : **SON** (mute), **slider VOL**, **? AIDE**,
**Sauvegarder**, **Réinitialiser**.

## Onboarding progressif (déblocage des mécaniques)

Un nouveau joueur ne voit qu'un jeu épuré ; les mécaniques se révèlent au fil des Fragments :

- **Début** : Terminal + Générateurs + jauge de Traçage uniquement. Onglets masqués.
- **1er Fragment** (1er prestige) → révèle l'onglet **Augmentations**.
- Dans les Augmentations, des **entrées « mystère »** (`[ ACCÈS VERROUILLÉ ]`, nom caché, coût visible,
  apparaissant à un seuil de Fragments) débloquent : **Opérations à risque** → **Daemons** → **Réseau**.
- **Aide** : bouton `? AIDE` → panneau listant seulement les mécaniques débloquées (anti-spoiler).
- Les **événements aléatoires** et **failles/boss** ne surviennent qu'après progression (voir gating).

## Les mécaniques

- **Frappe / combo** : commandes normales (`COMMANDS`, 20) + rares (`COMMANDS_RARE`, 11). Combo →
  production ×(1+5 %/palier) + bonus de complétion. Faute → combo cassé + traçage.
- **Traçage & intrusion** : les fautes (et échecs d'opérations) remplissent la jauge. À 100 % →
  **INTRUSION** : taper `purge logs` avant la fin du chrono. Échec → écran **TRACÉ (BUSTED)** :
  **toutes les Données effacées** + production /4 un moment.
- **Générateurs** : 4 types, coût exponentiel (×1,15), reset au prestige.
- **Prestige** : Fragments = `floor(sqrt(run_earned / PRESTIGE_DIV))`, +10 %/fragment de prod.
- **Augmentations** (items, payés en Fragments, permanents) : prod_mult, click_mult, cost_reduc,
  autoclick, synergy.
- **Daemons** (capacités actives) : **AUTOPWN** (toute touche validée) et **OVERCLOCK** (prod ×3) se
  débloquent/améliorent en Fragments ; **GHOST** (efface le traçage) est à **usage payant** (Fragments/usage).
- **Opérations à risque** : quitte-ou-double (70 % réussite = ~30 s de prod ; échec = traçage) + cooldown ;
  **failles zero-day** aléatoires (bouton à cliquer → prod ×3 temporaire).
- **Boss** (`BOSS_TYPES`, tirés au hasard toutes les ~2-3 min, uniquement si Opérations débloquées) :
  on les brise en tapant des commandes (dégâts). 5 types avec contraintes :
  FIREWALL (standard), EDR (rares only), ANALYSTE SOC (faute = soin), CHIFFREMENT SSL (brouillage),
  ANTI-DDOS (dégâts fixes, volume). Victoire = butin (× production) + Fragment.
- **Carte du réseau** (onglet Réseau) : graphe **procédural roguelike** régénéré à chaque prestige,
  conquis de proche en proche (fog of war). Nœuds payés en Données, bonus prod/click/cost ou one-shot
  data/frag. Zoom molette + déplacement clic-glissé.
- **Événements aléatoires** (après 1er prestige) : `instabilite` (commande brouillée) / `surcharge`
  (production ×0,6).
- **Audio** : SFX chiptune synthétisés + drone d'ambiance. Son d'achat en **gamme ascendante** selon le
  nombre possédé. Mute + slider de volume.
- **Juice** : +X flottant, pop du compteur, flash, shake, particules, toasts, overlays BUSTED/Singularité.

## Structure du projet

```
project.godot            config projet (scène de départ, taille fenêtre, config/icon)
export_presets.cfg       préréglage export Windows (embed_pck=true, icon=res://icon.ico)
scenes/
  main.tscn              LA scène (tout le HUD + overlays)
  generator_row.tscn     ligne réutilisable (un générateur)
  item_row.tscn          ligne réutilisable (item / daemon / entrée de déblocage mystère)
scripts/
  main.gd                TOUT le jeu (~1600 lignes ; sections repérées par des bandeaux commentés)
  generator_row.gd       affichage d'une ligne générateur (signal buy_requested)
  item_row.gd            affichage d'une ligne item/daemon/unlock (signal buy_requested)
theme/cyber_theme.tres   thème global (StyleBox néon, police, ProgressBar…)
shaders/background.gdshader  fond animé (grille + pluie de code + scanlines + vignette)
fonts/ShareTechMono-Regular.ttf  police mono (SIL OFL, cf. fonts/OFL.txt)
assets/icons/*.svg       icônes game-icons.net (CC BY 3.0, fond retiré, teintées via modulate)
assets/audio/*.wav       SFX + ambiance (SYNTHÉTISÉS, cf. tools/make_sounds.gd)
icon.ico / icon.png      icône du jeu (générés par tools/make_icon.gd)
tools/                   outils hors-jeu (voir plus bas)
build/CyberIncrement.exe l'exécutable exporté
ATTRIBUTIONS.md          crédits assets (obligatoire CC BY)
ROADMAP.md               historique chronologique des fonctionnalités
```

## Architecture du code (`scripts/main.gd`)

Tout le jeu tient dans un seul script attaché à la racine de `main.tscn`. Il est organisé en sections
(bandeaux `# ---`). Repères clés :

- **Constantes de réglage** en haut (voir « Équilibrage »). Puis l'**état** (`var`), les **données**
  data-driven (`generators`, `items`, `daemons`, `unlocks`, `BOSS_TYPES`, `help_topics`, `SFX_FILES`,
  `COMMANDS`/`COMMANDS_RARE`, `network_nodes` généré), et les **@onready** (nœuds `%UniqueName`).
- `_ready()` : construit les lignes (rows) et boutons, charge la partie, applique le gating, lance l'audio.
- `_process(delta)` → `_update_timers(delta)` (tous les compteurs : cooldowns, combo, traçage, intrusion,
  failles, boss, événements, daemons) puis `_update_display()` (rafraîchit toute l'UI).
- **Frappe** : `_input()` → `_type_char()` (comparaison caractère par caractère) ; `_pick_new_command()`,
  `_complete_command()`, `_update_typing_ui()` (rendu BBCode : normal / rare / éveil / brouillé).
- **Multiplicateurs** (composables) : `production_per_second()` = base × `prestige_multiplier()` ×
  `item_prod_mult()` × `event_multiplier()` × `network_prod_mult()` × `combo_prod_mult()`.
  Idem `click_value()` et `cost_of()`.
- **Systèmes** : prestige (`_do_prestige`), intrusion (`_start/_escape/_fail_intrusion`, `_show_busted`),
  daemons (`_activate_daemon`, `_on_daemon_buy`), opérations/failles, boss (`_start/_defeat/_fail_boss` +
  gimmicks via `boss_type`), réseau (`_generate_network`/`_rebuild_network_view`/zoom-pan/`_fit`),
  événements (`_start_random_event`), déblocage (`_apply_gating`/`_unlock_feature`/`_on_unlock_buy`),
  aide (`_open_help`), audio (`_setup_audio`/`_play_sfx`), fin (`_awaken_ai`/`_show_victory`).
- **Sauvegarde** : `save_game()`/`load_game()` (JSON dans `user://save.json`).

**Conventions** : tout est **data-driven** (ajouter un générateur / item / daemon / boss / commande /
thème d'aide = éditer un tableau). Les lignes d'UI répétées réutilisent `generator_row`/`item_row` +
signal `buy_requested`. Les nœuds accédés en code portent un **nom unique** (`%Nom`).

## Outils (dossier `tools/`)

Lancés en ligne de commande, hors du jeu, pour régénérer des assets :

```bash
# Régénérer les sons (WAV synthétisés). Réglages dans le script (fréquences, enveloppes…).
Godot_v4.4.1-stable_win64_console.exe --headless --path . --script res://tools/make_sounds.gd

# Régénérer l'icône (icon.ico multi-tailles + icon.png). L'œil cyber cyan sur fond sombre.
Godot_v4.4.1-stable_win64_console.exe --headless --path . --script res://tools/make_icon.gd
```

`tools/rcedit-x64.exe` = outil (electron/rcedit) utilisé par Godot pour poser l'icône dans l'exe.

## Builder l'exécutable

Prérequis (déjà en place) : templates d'export 4.4.1 installés ; chemin de `rcedit` renseigné dans les
**réglages de l'éditeur** (`export/windows/rcedit` = `tools/rcedit-x64.exe`).

```bash
Godot_v4.4.1-stable_win64_console.exe --headless --path . --export-release "Windows Desktop" "build/CyberIncrement.exe"
```

**Pièges connus (importants)** :
- L'icône DOIT être posée **pendant l'export** (Godot lance rcedit avant d'embarquer le `.pck`).
  Ne JAMAIS faire `rcedit` **après** un export à `.pck` embarqué → ça casse le pointeur du `.pck`
  (« Couldn't load project data »).
- Si l'export échoue sur « Impossible de renommer le fichier temporaire » : l'exe est **verrouillé**
  (une instance tourne) → **fermer le jeu** et réexporter (cf. mémoire de préférence : ne pas kill le process).
- Ouvrir l'éditeur Godot **réinitialise parfois** `export_presets.cfg` (repasse `embed_pck=false`,
  `application/icon=""`) → re-vérifier ces deux valeurs avant un build.

## Sauvegarde

- Fichier : `user://save.json` → `%APPDATA%\Godot\app_userdata\Cyber Increment\save.json`
  (partagé entre l'éditeur et l'exe, même `config/name`).
- Autosave toutes les 15 s + à la fermeture de la fenêtre.
- `SAVE_VERSION = 7`. Champs additifs (lus avec valeur par défaut) : items, daemons, réseau (seed +
  owned), objectif (`total_fragments_earned`, `has_won`, `prestige_count`, `play_time`), déblocages
  (`unlocked`, `unlocks_owned`), audio (`muted`, `sfx_volume`).
- **Pas de gains hors-ligne** (retiré volontairement : le jeu se veut actif).
- Compat : une save sans clé `unlocked` (ancienne) démarre **tout débloqué** (pas de régression).

## Équilibrage — principales constantes (haut de `scripts/main.gd`)

- Prestige : `PRESTIGE_DIV` (10000, quand tombe le 1er Fragment), `FRAGMENT_BONUS` (0.10).
- Fin : `AWAKEN_TARGET` (100 Fragments cumulés), `AWAKEN_COMMAND`.
- Combo : `COMBO_DECAY` (3 s), `COMBO_STEP` (bonus de fin), `COMBO_PROD_STEP`/`COMBO_PROD_CAP`
  (boost de production).
- Rares : `RARE_COMBO_THRESHOLD` (4), `RARE_BONUS_MULT` (2.5).
- Traçage/intrusion : `TRACE_PER_FAIL` (40), `TRACE_DECAY` (0.5), `WRONG_KEY_TRACE` (6),
  `MALUS_MULT`/`MALUS_DURATION`, `INTRUSION_TIME` (6 s).
- Opérations : `OP_COOLDOWN`, `OP_SUCCESS_CHANCE` (0.70), `OP_REWARD_SECONDS` (30).
- Failles : `ZERODAY_*`.
- Boss : `FIREWALL_*` (base HP, croissance, butin), `BOSS_TYPES` (hp_mult/time/gimmick par type),
  `BOSS_TYPO_HEAL`, `BOSS_THROTTLE_DMG`.
- Réseau : `NETWORK_RINGS`, `NETWORK_COST_BASE`/`GROWTH`, `_node_value()`.
- Événements : `EVENT_SPAWN_MIN/MAX`, `EVENT_DURATION`, `EVENT_SURCHARGE_MULT`.
- Déblocages : seuils/coûts dans le tableau `unlocks`. Daemons : `frag_base`/`frag_growth` par daemon.

## Crédits assets

- **Icônes** : [game-icons.net](https://game-icons.net) — **CC BY 3.0** (crédit obligatoire, voir
  [ATTRIBUTIONS.md](ATTRIBUTIONS.md)). Fond retiré, recolorées via `modulate`.
- **Police** : Share Tech Mono — **SIL OFL 1.1** (`fonts/OFL.txt`).
- **Sons & musique** : **synthétisés** dans le projet (aucun asset externe).
- **Shader de fond & icône du jeu** : faits maison.
