# Cyber Increment — Feuille de route

Jeu incrémental. Thème : **hacker solo**. Cible : **desktop Windows**.
Ressource principale : **Données** (le butin).

## Étapes

- [x] **Brique 1 — Cœur clicker** : une ressource (Données) + un bouton manuel `+1`.
- [x] **Brique 2 — Génération automatique** : générateur "Script automatisé"
      qu'on achète (coût exponentiel) et qui produit des Données/seconde via `_process`.
- [x] **Brique 2b — Plusieurs générateurs (data-driven)** : liste `generators`,
      scène réutilisable `GeneratorRow` instanciée par générateur, signal `buy_requested`.
- [x] **Brique 3 — Sauvegarde** : JSON dans `user://save.json`, autosave 15 s +
      sauvegarde à la fermeture, boutons Sauvegarder/Réinitialiser.
- [~] **Brique 4 — Progression offline** : ~~gains crédités au chargement~~
      RETIRÉE le 2026-07-14 (rendait le jeu trop simple ; on veut du jeu actif).
- [x] **Brique 5 — Prestige / palier** : "Compiler l'IA" → reset run contre des
      Fragments d'IA (monnaie permanente), +10 %/fragment de production globale.
      Gain = floor(sqrt(run_earned / 10000)), confirmation par ConfirmationDialog.
- [x] **Brique 8 — Boutique d'augmentations** (inspiré Scritchy Scratchy) : 5 items
      permanents en Fragments (Puissance/Efficacité/Variété), scène `ItemRow`, effets
      data-driven (prod_mult, click_mult, cost_reduc, autoclick, synergy). Layout passé
      en `ScrollContainer`.
- [x] **Brique 9 — Couche "hack à risque"** : opérations quitte-ou-double (cooldown,
      70% réussite), jauge de traçage (+34%/échec, décroît, malus prod /4 à 100%),
      failles zero-day aléatoires (prod x3 30s). `randf`, timers via `_process`,
      `event_multiplier()`. Effets transitoires non sauvegardés.
- [x] **Brique 6 — Habillage cyber** : `theme/cyber_theme.tres` (StyleBox néon,
      police Share Tech Mono), fond sombre, titre magenta glow, pulse Tween sur PIRATER.
- [x] **Brique 7 — Export Windows** : `export_presets.cfg` (Windows Desktop, pck
      embarqué), templates 4.4.1 installés, `build/CyberIncrement.exe` (~97 Mo,
      fichier unique autonome), lancement vérifié.

- [x] **Brique 10a — Juice / feedback** : +X flottant au clic/opération, pop du
      compteur, flash d'écran (cyan faille / rouge traçage), shake sur échec,
      particules (CPUParticles2D) sur PIRATER. Tout en Tween, asset-free.
- [x] **Brique 10b — Ambiance de fond** : shader `background.gdshader` sur le fond
      (grille défilante + pluie de code + scanlines + vignette), paramètres exposés.
- [x] **Brique 10d — Refonte HUD "vrai jeu"** : layout tableau de bord (barre de
      ressources en chips, terminal de hack central cliquable via `gui_input` +
      log RichTextLabel qui défile, opérations à gauche, TabContainer
      Générateurs/Augmentations à droite, prestige mis en avant).
- [x] **Brique 10c — Sprites & icônes** : 9 icônes game-icons.net (CC BY 3.0, voir
      ATTRIBUTIONS.md), fond retiré + teinture néon via modulate. TextureRect dans
      GeneratorRow/ItemRow. Barres de progression néon stylées (theme ProgressBar).

- [x] **Brique 11 — Gameplay clavier** : mini-jeu de frappe. Une commande de hack
      s'affiche, on la tape (`_input` + `event.unicode`), bonne lettre = +1 clic,
      commande finie = bonus (× longueur × combo). Combo qui décroît (`COMBO_DECAY`).
- [x] **Brique 11b — Commandes rares + malus** : commandes RARES longues (bonus ×2.5,
      +2 combo) dont la proba monte avec le combo ; mauvaise touche = combo cassé +
      traçage `WRONG_KEY_TRACE` (peut déclencher le malus de production).

- [x] **Brique 12 — Contre-mesure d'urgence** : à 100% de traçage, état INTRUSION avec
      compte à rebours (`INTRUSION_TIME`) ; taper `purge logs` = échappé (pas de malus),
      timeout = **remise à zéro des Données** + malus production. Faute pendant l'alerte
      = -0.5 s. Remplace le malus auto. Écran "TRACÉ" plein écran (façon BUSTED) à
      l'échec : montre les Données perdues + malus, anim pop/shake, clic ou 3 s pour fermer.

## Extension gameplay (série demandée le 2026-07-14) — ordre prévu
- [x] 1. Contre-mesure d'urgence (Brique 12)
- [x] 2. Programmes actifs (daemons) : barre de capacités cliquables.
      AUTOPWN/OVERCLOCK = déblocage + amélioration en Fragments (onglet PROGRAMMES,
      niveau ↑ = cooldown -10% + durée ↑). GHOST = usage payant (flag `pay_per_use`,
      `use_cost` Fragments/usage, toujours dispo, pas de cooldown). Niveaux sauvegardés.
- [x] 3b. Boss multiples (data-driven `BOSS_TYPES`, tirés au hasard) : FIREWALL (standard),
      EDR (rares uniquement), ANALYSTE SOC (faute = soin), CHIFFREMENT SSL (brouillage),
      ANTI-DDOS (dégâts fixes, volume). `boss_type` + gimmicks, titre/toast dynamiques.
- [x] 3. Pare-feux / boss de frappe : firewall à PV apparaissant périodiquement.
      Chaque commande complétée inflige des dégâts (= sa longueur), à briser en
      FIREWALL_TIME s. Victoire = gros butin + 1 Fragment ; échec = contre-attaque
      (prod /2). PV montent à chaque victoire (boss_level). Réutilise la frappe.
      Toasts non-bloquants (apparition / victoire / échec) ~3 s, réutilisables.
- [x] 4. Carte du réseau : onglet RÉSEAU, graphe de nœuds (Line2D + boutons) conquis
      de proche en proche (fog of war). Nœuds payés en Données, bonus prod/click/cost
      ou one-shot data/frag. **Procédurale roguelike** : génération en anneaux
      déterministe depuis un seed (`_generate_network`), régénérée à chaque prestige.
      Coûts/bonus pilotés par formules (NETWORK_COST_BASE/GROWTH, `_node_value`).
      Seed + owned sauvegardés (la run survit à une fermeture). Vue zoom (molette) +
      pan (glisser) via un Node2D transformé, avec cadrage auto (`_fit_network_view`).
      Nœuds = pastilles rondes (StyleBoxFlat circulaire) + icône par type + coût.
- [x] **Icône d'exe** : `tools/make_icon.gd` génère `icon.ico` MULTI-tailles (16→256 ;
      Godot rasterise le SVG + écriture manuelle du conteneur .ico). Appliquée PENDANT
      l'export (application/icon + modify_resources=true, chemin rcedit dans les réglages
      éditeur), PAS après (rcedit post-build casse le .pck embarqué).

- [x] **Brique 13 — Fin / objectif (Singularité)** : objectif = AWAKEN_TARGET Fragments
      cumulés (`total_fragments_earned`, via `_gain_fragments`). Atteint → la commande
      d'ÉVEIL dorée remplace les commandes ; la taper = victoire → écran plein
      "SINGULARITÉ // IA ÉVEILLÉE" + récap (fragments, prestiges, temps). Bouton
      Continuer (mode libre). `has_won` sauvegardé (SAVE_VERSION 6).

## À faire — Progression & aide (onboarding progressif) [plan validé]
Idée directrice : ne rien montrer que le joueur n'a pas encore débloqué ; révéler
les mécaniques une par une via l'économie de Fragments.

- [x] **P0 — Gating de l'UI** : `unlocked{augment,daemons,operations,network}`,
      `_apply_gating()` (set_tab_hidden + visibilité DaemonsPanel/OpButton/OpsTitle...).
      Failles zero-day + boss bridés tant que `operations` non débloqué. Anciennes
      sauvegardes = tout débloqué (pas de régression). SAVE_VERSION 7.
- [x] **P1 — 1er Fragment → Augmentations** : 1er prestige débloque l'onglet + toast.
- [x] **P2 — Déblocages via Augmentations** : entrées "mystère" (`unlocks`, nom masqué,
      coût visible, apparaissent au seuil `reveal`) en haut de l'onglet Augmentations ;
      achat → `_unlock_feature` + toast explicatif. (P3 aide détaillée & P4 events : à venir.)
- [x] **P3 — Aide détaillée** : bouton "? AIDE" (footer) → HelpOverlay avec thèmes
      (Terminal, Générateurs, Traçage, Prestige, Augmentations, Opérations, Daemons,
      Firewalls, Réseau) filtrés par déblocage. Data-driven (`help_topics`), texte
      détaillé par thème (daemons = les 3 pouvoirs expliqués).
- [x] **P4 — Événements aléatoires** : framework (spawn 40-80 s, durée 12 s, après 1er
      prestige). "Instabilité connexion" = commande brouillée (lettres qui clignotent
      vraies/parasites, `_glitch_char`). "Surcharge" = production ×0.6. Toasts + statut.

Points de design à trancher au moment de coder :
- Le traçage/intrusion (perte des Données) est DUR pour un débutant : à adoucir ou
  gater aussi tant que les Opérations à risque ne sont pas débloquées ?
- Ordre et seuils exacts des déblocages (Daemons vs Opérations vs Réseau).
- Copie des entrées "mystère" (ex. "??? — 5 Fragments" + tooltip énigmatique).

- [x] **Scaling frappe** : le COMBO booste la PRODUCTION (`combo_prod_mult` = 1 +
      min(combo,20)×5%, plafonné à +100%), replié dans `production_per_second()`.
      La frappe reste pertinente à tout stade (jeu actif dope l'idle) au lieu de
      décrocher (elle n'était indexée que sur `click_value`).

- [x] **Audio** : SFX chiptune synthétisés (`tools/make_sounds.gd` génère les .wav :
      key/wrong/command/rare/buy/prestige/alert/unlock/boss/victory) + drone d'ambiance
      bouclé. Pool d'AudioStreamPlayer (`_play_sfx`), branché sur toutes les actions.
      Bouton SON (mute) + SLIDER de volume des effets dans le footer (état sauvegardé).
      Sons d'événements : glitch (instabilité), overload (surcharge), stable (fin).

- [x] **Divers polish** : +commandes (20 normales / 11 rares) contre la répétitivité ;
      son d'achat en gamme ascendante selon le nombre possédé (`_buy_pitch_step`, linéaire,
      pas de log car ajout fixe) ; fenêtre par défaut 1498×842 (+30 %).
- [x] **Documentation** : `README.md` (référence état actuel : jouer, mécaniques, architecture,
      build, réglages, crédits). `ROADMAP.md` = historique.

## Idées de contenu (à trier plus tard)
- Générateurs : Script auto → Botnet → Ferme de serveurs → IA distribuée…
- Améliorations (upgrades) : multiplient la production ou le gain par clic.
- Événements : "traçage" (risque), "faille zero-day" (bonus temporaire).
