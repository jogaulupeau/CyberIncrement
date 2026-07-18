extends Control
## Brique 8 : boutique d'augmentations permanentes (inspiré Scritchy Scratchy).
##
## Les Fragments d'IA gagnés au prestige servent enfin à quelque chose : on les
## dépense dans des ITEMS permanents (ils SURVIVENT au prestige). Trois familles :
##   - PUISSANCE   : multiplie production / gain au clic
##   - EFFICACITE  : réduit le coût des générateurs, ajoute de l'auto-clic
##   - VARIETE     : bonus de synergie (récompense la diversité de générateurs)
## Comme les générateurs, tout est data-driven : ajouter un item = une ligne.

const GeneratorRowScene := preload("res://scenes/generator_row.tscn")
const ItemRowScene := preload("res://scenes/item_row.tscn")

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 7                 # +items +daemons +network +objectif +déblocages

# Infos de publication (affichées dans l'aide "À propos" et le footer).
const GAME_VERSION := "0.3.0"
const GAME_AUTHOR := "Jonathan GAULUPEAU"
const GAME_YEAR := "2026"
const GAME_LICENSE := "Creative Commons BY-NC 4.0"

const FRAGMENT_BONUS := 0.10
const PRESTIGE_DIV := 10000.0

# --- Réglages "hack à risque" (Brique 9) ------------------------------------
const OP_COOLDOWN := 15.0              # délai entre deux opérations (s)
const OP_SUCCESS_CHANCE := 0.70        # proba de réussite (0..1)
const OP_REWARD_SECONDS := 30.0        # réussite = X secondes de production
const OP_MIN_REWARD_CLICKS := 25.0     # plancher de gain (en clics) pour le début de partie
const TRACE_MAX := 100.0
# Couleurs des EFFETS (flashs d'écran + textes flottants), palette DOS.
const FX_GAIN := Color(0.2, 0.9, 0.3)      # vert : gain / succès
const FX_ALERT := Color(0.9, 0.12, 0.12)   # rouge : danger / échec
const FX_SPECIAL := Color(1, 0.8, 0.2)     # ambre : faille, boost, éveil
const FX_EVENT := Color(0.95, 0.45, 0.1)   # orange : événement aléatoire
const EVENT_POPUP_DURATION := 3.5      # secondes de lecture forcée (boss/événement) avant reprise
const TRACE_PER_FAIL := 40.0           # 3 échecs enchaînés (même espacés du cooldown) => TRACÉ
const TRACE_DECAY := 0.5               # décroissance lente : les échecs "collent" entre les opérations
const MALUS_MULT := 0.25               # "TRACÉ" : production ×0.25 (soit ÷4)
const MALUS_DURATION := 20.0
const ZERODAY_MULT := 3.0              # faille : production ×3
const ZERODAY_BUFF_DURATION := 30.0
const ZERODAY_WINDOW := 10.0           # temps pour cliquer la faille
const ZERODAY_SPAWN_MIN := 45.0        # intervalle aléatoire entre deux failles
const ZERODAY_SPAWN_MAX := 90.0

# Lignes "hacker" affichées dans le terminal à chaque clic (choisies au hasard).
const HACK_LINES := [
	"breach: pare-feu contourné",
	"inject: payload livré",
	"scan: port 443 ouvert",
	"root: privilèges élevés",
	"exfil: données siphonnées",
	"crack: hash inversé",
	"spoof: adresse MAC changée",
	"tunnel: proxy enchaîné",
	"decrypt: clé AES cassée",
	"ghost: journaux effacés",
]

# Commandes à TAPER au clavier (minuscules, lettres/chiffres/espaces uniquement).
const COMMANDS := [
	"nmap scan subnet",
	"enumerate smb shares",
	"crack wpa handshake",
	"dump lsass memory",
	"spoof arp table",
	"bypass firewall rules",
	"exploit cve 2026",
	"resolve dns records",
	"dump user hashes",
	"flush iptables rules",
	"escalate root access",
	"sniff network packets",
	"mount remote share",
	"grep etc passwd",
	"patch zero day",
	"clone rfid badge",
	"hashcat crack md5",
	"bruteforce ssh login",
	"wipe access logs",
	"inject sql payload",
]
const COMBO_DECAY := 3.0                # secondes sans frappe correcte -> combo remis à 0
const COMBO_STEP := 0.20               # chaque palier de combo = +20% au bonus de fin
const COMBO_PROD_STEP := 0.05          # chaque palier de combo = +5% de PRODUCTION (jeu actif)
const COMBO_PROD_CAP := 20             # plafond du bonus de production du combo

# Commandes RARES (longues) : n'apparaissent qu'à combo élevé, mais rapportent gros.
const COMMANDS_RARE := [
	"pivot internal gateway compromise host",
	"exfiltrate encrypted database archive",
	"dump domain admin credentials mimikatz",
	"deploy persistent reverse shell backdoor",
	"crack kerberos service tickets offline",
	"escalate kernel exploit root privileges",
	"evade endpoint detection sandbox analysis",
	"enumerate active directory trust relations",
	"deploy cobalt strike beacon network",
	"intercept session tokens process memory",
	"chain exploits reach domain admin",
]
const RARE_COMBO_THRESHOLD := 4        # combo minimum pour qu'une commande rare puisse sortir
const RARE_BONUS_MULT := 2.5           # bonus des commandes rares (× en plus du calcul normal)

# Malus de frappe : une mauvaise touche casse le combo et fait monter le traçage.
const WRONG_KEY_TRACE := 6.0

# Contre-mesure : à 100% de traçage, on a INTRUSION_TIME secondes pour taper une commande
# d'évasion. Tirée au hasard dans ESCAPE_COMMANDS à chaque déclenchement (longueurs proches,
# pour que la difficulté reste comparable d'un tirage à l'autre) : avec l'intrusion qui devient
# plus fréquente (les boss peuvent la déclencher), une commande fixe deviendrait un réflexe
# mécanique plutôt qu'une vraie lecture/frappe.
const INTRUSION_TIME := 6.0
const ESCAPE_COMMANDS := [
	"purge logs",
	"flush trace",
	"kill session",
	"wipe audit",
	"drop uplink",
	"reset alarm",
	"kill netstat",
	"clear cache",
]

# Objectif de fin : rassembler AWAKEN_TARGET Fragments (cumulés), puis taper la
# commande d'éveil pour atteindre la Singularité (victoire).
const AWAKEN_TARGET := 200
const AWAKEN_COMMAND := "sudo awaken the ai singularity"

# Événements aléatoires (P4) : compliquent ponctuellement le gameplay.
const EVENT_SPAWN_MIN := 40.0
const EVENT_SPAWN_MAX := 80.0
const EVENT_DURATION := 12.0
const EVENT_SURCHARGE_MULT := 0.6      # "surcharge" : production réduite
const GLITCH_CHARS := "#%&@?$*"        # symboles de brouillage pour l'instabilité

# Programmes actifs (daemons).
const OVERCLOCK_MULT := 3.0            # production ×3 pendant le daemon OVERCLOCK

# Pare-feux (boss de frappe) : apparaissent périodiquement, à briser au clavier.
const FIREWALL_SPAWN_MIN := 100.0     # intervalle aléatoire entre deux firewalls
const FIREWALL_SPAWN_MAX := 160.0
const FIREWALL_BASE_HP := 80.0       # PV du 1er firewall (dégâts = longueur des commandes)
const FIREWALL_HP_GROWTH := 0.5       # +50% de PV par firewall vaincu
const BOSS_FAIL_TRACE := 60.0         # boss non vaincu : traçage +60% (peut déclencher l'intrusion)
const FIREWALL_REWARD_SECONDS := 90.0 # butin de base = X secondes de production
const FIREWALL_REWARD_LEVEL_STEP := 0.5 # +50% de butin par firewall déjà vaincu
const FIREWALL_COMBO_STEP := 0.05     # +5% de butin par palier de combo au moment de la victoire
# Butin de boss : le joueur choisit UNE récompense parmi 3 tirées (pondérées) dans un large pool.
# Chaque récompense a une RARETÉ : commune (fréquente), rare, légendaire (la meilleure, la plus rare).
# Le tirage est pondéré par ces poids -> plus une carte est puissante, plus elle est rare.
const REWARD_RARITY_WEIGHT := {"commune": 100, "rare": 12, "legendaire": 3}
# Couleur de FOND de la carte selon la rareté (lisibilité : texte clair sur rare/légendaire).
const RARITY_BG := {
	"commune": Color(0.70, 0.70, 0.70),
	"rare": Color(0.10, 0.45, 0.85),
	"legendaire": Color(0.90, 0.68, 0.12),
}
const RARITY_FG := {
	"commune": Color(0.10, 0.10, 0.10),
	"rare": Color(1, 1, 1),
	"legendaire": Color(0.12, 0.06, 0),
}
const RARITY_LABEL := {"commune": "COMMUN", "rare": "RARE", "legendaire": "LÉGENDAIRE"}
const BOSS_TYPO_HEAL := 8.0           # PV rendus par faute de frappe (Analyste SOC)
const BOSS_THROTTLE_DMG := 12.0       # dégâts FIXES par commande (AntiDDOS : le volume compte)

# Types de boss (tirés au hasard). gimmick : contrainte spéciale.
const BOSS_TYPES := [
	{ "id": "firewall", "name": "FIREWALL",        "hp_mult": 1.0, "time": 28.0, "gimmick": "",          "desc": "Pare-feu standard : chaque commande l'endommage." },
	{ "id": "edr",      "name": "EDR",             "hp_mult": 0.7, "time": 30.0, "gimmick": "rare_only", "desc": "Seules les commandes RARES l'endommagent vraiment (normales à 20 %)." },
	{ "id": "soc",      "name": "ANALYSTE SOC",    "hp_mult": 1.4, "time": 32.0, "gimmick": "typo_heal", "desc": "Sois précis : chaque faute de frappe fait du bruit et le soigne." },
	{ "id": "ssl",      "name": "CHIFFREMENT SSL", "hp_mult": 0.9, "time": 30.0, "gimmick": "glitch",    "desc": "Trafic chiffré : les commandes sont brouillées, tape à l'aveugle." },
	{ "id": "antiddos", "name": "ANTI-DDOS",       "hp_mult": 1.0, "time": 34.0, "gimmick": "throttle",  "desc": "Débit limité : dégâts fixes par commande — c'est le VOLUME qui compte." },
]

# --- État global ------------------------------------------------------------
var data: float = 0.0
var per_click: int = 1
var fragments: int = 0
var run_earned: float = 0.0

# État "hack à risque" (transitoire : non sauvegardé, remis à zéro au chargement).
var op_cooldown_remaining: float = 0.0
var trace: float = 0.0                 # jauge de traçage 0..TRACE_MAX
var malus_remaining: float = 0.0       # temps restant du malus "TRACÉ"
var zeroday_buff_remaining: float = 0.0 # temps restant du buff faille
# Buffs "récompense de boss" à intensité/durée variables (selon la rareté de la carte choisie).
var click_buff_remaining: float = 0.0  # temps restant du buff FRAPPE (clic ×N)
var click_buff_mult: float = 1.0       # multiplicateur de clic pendant le buff FRAPPE
var rwd_prod_remaining: float = 0.0    # temps restant du buff de production (FAILLE/SURRÉGIME/ROOTKIT)
var rwd_prod_mult: float = 1.0         # multiplicateur de production pendant ce buff
var zeroday_window_remaining: float = 0.0 # temps restant pour cliquer une faille visible
var zeroday_spawn_timer: float = 0.0   # compte à rebours avant la prochaine faille
var _pop_tween: Tween = null           # animation de "pop" en cours sur le compteur
var term_lines: Array[String] = []     # tampon des lignes affichées dans le terminal

# Mini-jeu de frappe (taper les commandes de hack).
var current_command: String = ""       # commande à taper actuellement
var typed_len: int = 0                 # nombre de caractères déjà tapés correctement
var combo: int = 0                     # nombre de commandes enchaînées
var combo_timer: float = 0.0           # temps écoulé depuis la dernière bonne frappe
var current_is_rare: bool = false      # la commande en cours est-elle une commande rare ?
var intrusion_active: bool = false     # est-on en état d'alerte (contre-mesure) ?
var intrusion_timer: float = 0.0       # temps restant pour s'échapper

# Objectif / fin de partie.
var total_fragments_earned: int = 0    # Fragments gagnés au total (compteur d'objectif)
var has_won: bool = false              # l'IA a-t-elle été éveillée ?
var final_command_active: bool = false # la commande affichée est-elle celle de l'éveil ?
var prestige_count: int = 0            # nombre de prestiges (pour le récap)
var play_time: float = 0.0             # temps de jeu cumulé (pour le récap)

# Statistiques / records (écran STATS, cumulés sur toute la partie, remis à zéro
# uniquement par une réinitialisation complète — pas par un prestige).
var best_combo: int = 0                # plus haut combo jamais atteint
var total_commands_typed: int = 0      # nombre de commandes complétées (normales + rares)
var total_rare_typed: int = 0          # dont commandes rares
var best_run_earned: float = 0.0       # meilleure run (Données accumulées avant reset/prestige)

# Événements aléatoires.
var event_active: bool = false
var event_id: String = ""
var event_timer: float = 0.0
var event_spawn_timer: float = 0.0

# Audio.
const SFX_FILES := {
	"key": "res://assets/audio/key.wav",
	"key_wrong": "res://assets/audio/key_wrong.wav",
	"command": "res://assets/audio/command.wav",
	"rare": "res://assets/audio/rare.wav",
	"buy": "res://assets/audio/buy.wav",
	"prestige": "res://assets/audio/prestige.wav",
	"alert": "res://assets/audio/alert.wav",
	"unlock": "res://assets/audio/unlock.wav",
	"boss": "res://assets/audio/boss.wav",
	"victory": "res://assets/audio/victory.wav",
	"reward": "res://assets/audio/reward.wav",
	"rare_reveal": "res://assets/audio/rare_reveal.wav",
	"boss_fail": "res://assets/audio/boss_fail.wav",
	"glitch": "res://assets/audio/glitch.wav",
	"overload": "res://assets/audio/overload.wav",
	"stable": "res://assets/audio/stable.wav",
}
var _sfx_streams := {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_idx := 0
var _music_player: AudioStreamPlayer
var muted: bool = false
var sfx_volume: float = 0.8            # volume des effets (0..1), réglé par le slider

# Déblocage progressif des mécaniques (onboarding). Booléens TYPÉS (une faute de frappe sur
# un accès direct devient une erreur de compilation, au lieu d'un null silencieux). Les usages
# DYNAMIQUES par nom (déblocage data-driven, gate d'aide, sauvegarde) passent par les accesseurs
# _is_unlocked / _set_unlocked. UNLOCK_FEATURES pilote les boucles (save/load/reset).
const UNLOCK_FEATURES := ["augment", "daemons", "operations", "network"]
var unlock_augment: bool = false
var unlock_daemons: bool = false
var unlock_operations: bool = false
var unlock_network: bool = false
# Entrées "mystère" dans la boutique : coût visible, nom masqué tant que non acheté.
# reveal = Fragments cumulés pour que l'entrée APPARAISSE ; cost = coût du déblocage.
var unlocks: Array[Dictionary] = [
	{ "id": "u_ops",     "feature": "operations", "name": "Opérations à risque",  "cost": 3,  "reveal": 2, "owned": false, "help": "Coups de poker : gros gain instantané, mais un échec fait monter le traçage." },
	{ "id": "u_daemons", "feature": "daemons",    "name": "Programmes (daemons)", "cost": 6,  "reveal": 5, "owned": false, "help": "Capacités actives (AUTOPWN, GHOST, OVERCLOCK) à débloquer et déclencher." },
	{ "id": "u_network", "feature": "network",    "name": "Carte du réseau",      "cost": 10, "reveal": 8, "owned": false, "help": "Un réseau de nœuds à pirater pour des bonus permanents." },
]
var unlock_rows: Array[ItemRow] = []

# Aide (P3). gate = "" -> toujours ; sinon nom de mécanique (voir _is_unlocked) requis pour l'afficher.
var help_topics: Array[Dictionary] = [
	{ "id": "terminal", "label": "Terminal", "gate": "",
		"title": "Le terminal (frappe)",
		"text": "Tape la commande affichée : chaque bonne lettre rapporte des Données. SURTOUT, tant que tu enchaînes sans faute, ton COMBO monte et BOOSTE toute ta production (+5 % par palier) — taper activement dope ton économie. Le combo retombe si tu t'arrêtes (3 s). À combo élevé, des commandes RARES (dorées) apparaissent et valent +2 au combo. Une mauvaise touche casse le combo et fait monter le traçage. Tu peux aussi cliquer le terminal pour +1." },
	{ "id": "generators", "label": "Générateurs", "gate": "",
		"title": "Générateurs",
		"text": "Achète-les avec des Données : ils produisent automatiquement, en continu. Le coût augmente à chaque achat. Ils sont remis à zéro quand tu compiles l'IA (prestige)." },
	{ "id": "tracage", "label": "Traçage", "gate": "",
		"title": "Traçage & intrusion",
		"text": "Les fautes de frappe, les opérations ratées et les boss non vaincus (+60 %) remplissent la jauge de TRAÇAGE. À 100 %, une INTRUSION se déclenche : une commande d'urgence apparaît (différente à chaque fois), tape-la vite pour t'échapper. Si le chrono s'écoule, tu PERDS toutes tes Données et ta production est divisée par 4 un moment. La jauge redescend doucement si tu joues prudemment." },
	{ "id": "prestige", "label": "Prestige", "gate": "",
		"title": "Compiler l'IA (prestige)",
		"text": "Sacrifie ta run en cours (Données + générateurs remis à zéro) contre des FRAGMENTS D'IA, permanents. Chaque Fragment donne +10 % de production pour toujours, et sert à débloquer/acheter dans les autres onglets. Objectif final : rassembler assez de Fragments pour ÉVEILLER l'IA." },
	{ "id": "augment", "label": "Augmentations", "gate": "augment",
		"title": "Augmentations",
		"text": "Dépense tes Fragments d'IA pour des bonus PERMANENTS (production, gain au clic, réduction de coût). C'est aussi ici que tu débloques de nouvelles mécaniques (entrées 'accès verrouillé' en haut de la liste)." },
	{ "id": "operations", "label": "Opérations", "gate": "operations",
		"title": "Opérations à risque",
		"text": "Un coup de poker : environ 70 % de chances de réussir pour un gros gain instantané (~30 s de production). En cas d'échec, le traçage monte. Un cooldown sépare deux tentatives. Parfois une FAILLE zero-day apparaît : clique-la pour un boost de production temporaire." },
	{ "id": "daemons", "label": "Daemons", "gate": "daemons",
		"title": "Programmes (daemons)",
		"text": "Des capacités actives, déclenchées au clic. Débloque-les et améliore-les avec des Fragments (onglet Programmes).\n• AUTOPWN : pendant sa durée, TOUTE touche valide la commande (martèle le clavier).\n• GHOST : efface instantanément le traçage (coûte des Fragments à chaque usage).\n• OVERCLOCK : production ×3 un moment. Astuce : garde-le pour le coup fatal d'un boss." },
	{ "id": "boss", "label": "Boss", "gate": "operations",
		"title": "Boss (défenses)",
		"text": "Périodiquement, une défense apparaît avec des PV et un chrono. Complète des commandes pour la briser avant la fin : gros butin + un Fragment. Échec = TRAÇAGE +60 % (peut déclencher une intrusion immédiate si la jauge est déjà haute). Chaque type a sa contrainte :\n• FIREWALL : standard (dégâts = longueur).\n• EDR : seules les commandes RARES l'endommagent.\n• ANALYSTE SOC : blindé, une faute de frappe le soigne (sois précis).\n• CHIFFREMENT SSL : commandes brouillées (à l'aveugle).\n• ANTI-DDOS : dégâts fixes par commande — enchaîne le VOLUME (AUTOPWN idéal)." },
	{ "id": "network", "label": "Réseau", "gate": "network",
		"title": "Carte du réseau",
		"text": "Un graphe de nœuds à pirater de proche en proche (tu ne peux prendre qu'un nœud voisin d'un nœud déjà conquis). Les nœuds coûtent des Données mais donnent des bonus (production, clic, coût) ou des paquets de Données/Fragments. La carte se régénère à chaque prestige. Molette = zoom, clic-glissé = déplacer." },
	{ "id": "stats", "label": "Stats", "gate": "",
		"title": "Statistiques",
		"text": "" },
	{ "id": "about", "label": "À propos", "gate": "",
		"title": "À propos",
		"text": "Cyber Increment — version %s\n\nAuteur : %s\n© %s %s\nLicence : %s\n\nCe jeu est distribué sous licence Creative Commons Attribution - Pas d'Utilisation Commerciale 4.0 (CC BY-NC 4.0) : tu peux le partager et le modifier à condition d'en créditer l'auteur et de ne pas en faire un usage commercial.\n\nMoteur : Godot Engine 4.4.1. Icônes : game-icons.net (CC BY 3.0). Police : VT323 (SIL OFL)." % [GAME_VERSION, GAME_AUTHOR, GAME_YEAR, GAME_AUTHOR, GAME_LICENSE] },
]
var help_buttons: Array[Button] = []

# Boss "firewall".
var boss_active: bool = false
var boss_hp: float = 0.0
var boss_max_hp: float = 0.0
var boss_timer: float = 0.0            # temps restant pour le briser
var boss_level: int = 0               # nombre de firewalls déjà vaincus (difficulté/récompense)
var boss_type: Dictionary = {}        # type du boss en cours (voir BOSS_TYPES)
var boss_spawn_timer: float = 0.0      # compte à rebours avant le prochain firewall

# --- Générateurs (achetés en Données, remis à zéro au prestige) --------------
var generators: Array[Dictionary] = [
	{ "name": "Script automatisé", "base_cost": 10.0,     "cost_growth": 1.15, "production": 1.0,   "count": 0, "icon": "res://assets/icons/processor.svg" },
	{ "name": "Botnet",            "base_cost": 120.0,    "cost_growth": 1.15, "production": 8.0,   "count": 0, "icon": "res://assets/icons/spider-alt.svg" },
	{ "name": "Ferme de serveurs", "base_cost": 1500.0,   "cost_growth": 1.15, "production": 50.0,  "count": 0, "icon": "res://assets/icons/server-rack.svg" },
	{ "name": "IA distribuée",     "base_cost": 20000.0,  "cost_growth": 1.15, "production": 300.0, "count": 0, "icon": "res://assets/icons/artificial-intelligence.svg" },
]

# --- Items (achetés en Fragments, PERMANENTS) --------------------------------
# effect : ce que l'item modifie. value : effet par niveau.
# base_cost/cost_growth : coût EN FRAGMENTS, qui double(-ish) à chaque niveau.
var items: Array[Dictionary] = [
	{ "id": "overclock", "name": "Overclock CPU",        "category": "PUISSANCE",  "effect": "prod_mult",  "value": 0.25, "base_cost": 1.0, "cost_growth": 2.0, "max_level": 10, "level": 0, "icon": "res://assets/icons/cpu.svg" },
	{ "id": "payload",   "name": "Injecteur de payload", "category": "PUISSANCE",  "effect": "click_mult", "value": 1.0,  "base_cost": 1.0, "cost_growth": 2.5, "max_level": 8,  "level": 0, "icon": "res://assets/icons/syringe.svg" },
	{ "id": "compiler",  "name": "Compilateur optimisé", "category": "EFFICACITE", "effect": "cost_reduc", "value": 0.05, "base_cost": 2.0, "cost_growth": 2.0, "max_level": 6,  "level": 0, "icon": "res://assets/icons/gears.svg" },
	{ "id": "daemon",    "name": "Daemon d'autoclic",    "category": "EFFICACITE", "effect": "autoclick",  "value": 1.0,  "base_cost": 3.0, "cost_growth": 2.5, "max_level": 10, "level": 0, "icon": "res://assets/icons/robot-golem.svg" },
	{ "id": "synergie",  "name": "Protocole synergique", "category": "VARIETE",    "effect": "synergy",    "value": 0.05, "base_cost": 2.0, "cost_growth": 2.2, "max_level": 10, "level": 0, "icon": "res://assets/icons/circuitry.svg" },
]

var gen_rows: Array[GeneratorRow] = []
var item_rows: Array[ItemRow] = []

# --- Daemons (capacités actives, déclenchées au clic) ------------------------
# cd_remaining : cooldown restant. active_remaining : durée d'effet restante.
# level 0 = verrouillé. Chaque niveau (payé en Fragments) réduit le cooldown (-10%)
# et allonge la durée (+duration_step). base_* = valeurs au niveau 1.
var daemons: Array[Dictionary] = [
	{ "id": "autopwn",   "name": "AUTOPWN",   "base_cooldown": 90.0, "base_duration": 6.0,  "duration_step": 1.5, "frag_base": 8.0, "frag_growth": 2.0, "max_level": 5, "level": 0, "cd_remaining": 0.0, "active_remaining": 0.0, "icon": "res://assets/icons/robot-golem.svg" },
	{ "id": "ghost",     "name": "GHOST",     "pay_per_use": true, "use_cost": 1, "base_cooldown": 60.0, "base_duration": 0.0,  "duration_step": 0.0, "frag_base": 3.0, "frag_growth": 2.0, "max_level": 5, "level": 0, "cd_remaining": 0.0, "active_remaining": 0.0, "icon": "res://assets/icons/circuitry.svg" },
	{ "id": "overclock", "name": "OVERCLOCK", "base_cooldown": 75.0, "base_duration": 20.0, "duration_step": 4.0, "frag_base": 5.0, "frag_growth": 2.0, "max_level": 5, "level": 0, "cd_remaining": 0.0, "active_remaining": 0.0, "icon": "res://assets/icons/cpu.svg" },
]
var daemon_buttons: Array[Button] = []
var daemon_rows: Array[ItemRow] = []

# --- Réseau (carte de nœuds à pirater, bonus PERMANENTS payés en Données) -----
# owned = conquis. On ne peut pirater qu'un nœud adjacent à un nœud déjà conquis.
# types : root (départ), prod (+% prod), click (+% frappe), cost (-% coût gén.),
#         data (paquet de Données), frag (Fragments).
# Carte PROCÉDURALE (roguelike) : régénérée à chaque prestige à partir d'un seed.
# Bonus valables pour la run en cours (remis à zéro au prestige, comme les générateurs).
const NETWORK_RINGS := 4              # nombre d'anneaux autour du CORE
const NETWORK_COST_BASE := 400.0      # coût (Données) d'un nœud de l'anneau 1
const NETWORK_COST_GROWTH := 5.0      # ×coût par anneau plus profond
const NETWORK_CELL := 46.0            # pas de la grille (schéma circuit imprimé, style DOS)
const NETWORK_NODE_SIZE := 32.0       # taille des pastilles carrées
var network_nodes: Array[Dictionary] = []
var network_connections: Array = []   # paires [i, j] d'indices reliés
var network_seed: int = 0
var network_buttons: Array[Button] = []
var network_labels: Array[Label] = []
var network_lines: Array = []
var _node_style_owned: StyleBoxFlat
var _node_style_hack: StyleBoxFlat
var _node_style_locked: StyleBoxFlat
var _network_fitted: bool = false     # la carte a-t-elle été recadrée sur la vue ?
const NET_MIN_ZOOM := 0.35
const NET_MAX_ZOOM := 2.5

# --- Interface --------------------------------------------------------------
@onready var data_label: Label = %DataLabel
@onready var prod_label: Label = %ProdLabel
@onready var terminal: PanelContainer = %Terminal
@onready var terminal_log: RichTextLabel = %TerminalLog
@onready var command_label: RichTextLabel = %CommandLabel
@onready var term_hint: Label = %TermHint
@onready var tabs: TabContainer = %Tabs
@onready var gen_container: VBoxContainer = %GenContainer
@onready var fragment_label: Label = %FragmentLabel
@onready var prestige_info: Label = %PrestigeInfo
@onready var prestige_button: Button = %PrestigeButton
@onready var confirm_overlay: Control = %ConfirmOverlay
@onready var confirm_title: Label = %ConfirmTitle
@onready var confirm_msg: RichTextLabel = %ConfirmMsg
@onready var confirm_ok: Button = %ConfirmOK
@onready var confirm_cancel: Button = %ConfirmCancel
@onready var reward_overlay: Control = %RewardOverlay
@onready var reward_title: Label = %RewardTitle
@onready var reward_cards: Array[Button] = [%RewardCard0, %RewardCard1, %RewardCard2]
@onready var event_popup: Control = %EventPopup
@onready var event_popup_bar: PanelContainer = %EventPopupBar
@onready var event_popup_title: Label = %EventPopupTitle
@onready var event_popup_msg: RichTextLabel = %EventPopupMsg
@onready var shop_container: VBoxContainer = %ShopContainer
@onready var daemons_bar: HBoxContainer = %DaemonsBar
@onready var daemon_container: VBoxContainer = %DaemonContainer
@onready var network_view: Control = %NetworkView
@onready var network_content: Node2D = %NetworkContent
@onready var op_button: Button = %OpButton
@onready var ops_title: Label = %OpsTitle
@onready var ops_desc: Label = %OpsDesc
@onready var daemons_panel: PanelContainer = %DaemonsPanel
@onready var op_fill: ColorRect = %OpFill
@onready var op_label: Label = %OpLabel
@onready var trace_label: Label = %TraceLabel
@onready var trace_bar: Panel = %TraceBar
@onready var trace_ticks: HBoxContainer = %Ticks
@onready var trace_pct: Label = %Pct
@onready var zeroday_button: Button = %ZeroDayButton
@onready var event_status: Label = %EventStatus
@onready var boss_panel: PanelContainer = %BossPanel
@onready var boss_title: Label = %BossTitle
@onready var boss_hp_bar: ProgressBar = %BossHPBar
@onready var boss_info: Label = %BossInfo
@onready var toast_stack: VBoxContainer = %ToastStack
@onready var objective_label: Label = %ObjectiveLabel
@onready var victory_overlay: Control = %VictoryOverlay
@onready var victory_panel: PanelContainer = %VictoryPanel
@onready var victory_stats: Label = %VictoryStats
@onready var continue_button: Button = %ContinueButton
@onready var logo_icon: TextureRect = %LogoIcon
@onready var fragment_icon: TextureRect = %FragmentIcon
@onready var fx_layer: Control = %FxLayer
@onready var click_particles: CPUParticles2D = %ClickParticles
@onready var flash_rect: ColorRect = %Flash
@onready var busted_overlay: Control = %BustedOverlay
@onready var busted_panel: PanelContainer = %BustedPanel
@onready var busted_lost: Label = %BustedLost
@onready var busted_malus: Label = %BustedMalus
@onready var mute_button: Button = %MuteButton
@onready var volume_slider: HSlider = %VolumeSlider
@onready var help_button: RichTextLabel = %HelpButton
@onready var help_overlay: Control = %HelpOverlay
@onready var help_topics_bar: HFlowContainer = %HelpTopics
@onready var help_text: RichTextLabel = %HelpText
@onready var help_close_button: Button = %CloseButton
@onready var save_button: RichTextLabel = %SaveButton
@onready var reset_button: RichTextLabel = %ResetButton
@onready var stats_button: RichTextLabel = %StatsButton
@onready var about_label: Label = %AboutLabel
@onready var title_ver: Label = %TitleVer
@onready var status_label: Label = %StatusLabel
@onready var clock_label: Label = %ClockLabel


func _ready() -> void:
	get_tree().auto_accept_quit = false

	terminal.gui_input.connect(_on_terminal_input)  # tout clic sur le terminal = piratage
	busted_overlay.gui_input.connect(_on_busted_input)
	network_view.gui_input.connect(_on_network_gui_input)
	continue_button.pressed.connect(_on_continue_pressed)
	# Items de menu façon FreeDOS (RichTextLabel cliquables, lettre-raccourci rouge).
	_setup_menu_item(help_button, "[color=#aa0000]A[/color]ide", "[color=#ffffff]Aide[/color]", _open_help)
	_setup_menu_item(save_button, "[color=#aa0000]S[/color]auver", "[color=#ffffff]Sauver[/color]", _on_save_pressed)
	_setup_menu_item(reset_button, "[color=#aa0000]R[/color]éinitialiser", "[color=#ffffff]Réinitialiser[/color]", _on_reset_pressed)
	_setup_menu_item(stats_button, "S[color=#aa0000]t[/color]ats", "[color=#ffffff]Stats[/color]", _open_stats)
	help_close_button.pressed.connect(_close_help)
	mute_button.pressed.connect(_on_mute_pressed)
	_build_help_topics()
	tabs.set_tab_title(0, "Générateurs")
	tabs.set_tab_title(1, "Augmentations")
	tabs.set_tab_title(2, "Programmes")
	tabs.set_tab_title(3, "Réseau")
	# Rafraîchit immédiatement l'onglet qu'on vient d'ouvrir (les lignes ne sont mises à jour
	# que pour l'onglet affiché ; sans ça, un frame de contenu périmé pourrait apparaître).
	tabs.tab_changed.connect(func(_t: int) -> void: _update_display())
	about_label.text = "v%s · © %s %s" % [GAME_VERSION, GAME_YEAR, GAME_AUTHOR]
	title_ver.text = "v%s" % GAME_VERSION
	about_label.tooltip_text = "Cyber Increment v%s\n© %s %s\nLicence : %s" % [GAME_VERSION, GAME_YEAR, GAME_AUTHOR, GAME_LICENSE]
	prestige_button.pressed.connect(_on_prestige_pressed)
	confirm_ok.pressed.connect(_on_confirm_ok)
	confirm_cancel.pressed.connect(_on_confirm_cancel)
	for i in reward_cards.size():
		reward_cards[i].pressed.connect(_pick_reward.bind(i))
	op_button.pressed.connect(_on_operation_pressed)
	zeroday_button.pressed.connect(_on_zeroday_pressed)
	# Pas de focus clavier sur les boutons désactivables dynamiquement : sinon le
	# style "focus" reste affiché par-dessus l'état désactivé après un clic.
	prestige_button.focus_mode = Control.FOCUS_NONE
	op_button.focus_mode = Control.FOCUS_NONE

	_build_trace_ticks()
	logo_icon.texture = load("res://assets/icons/ai-logo.svg")
	fragment_icon.texture = load("res://assets/icons/fragment.svg")
	_set_zeroday_shown(false)
	zeroday_spawn_timer = randf_range(ZERODAY_SPAWN_MIN, ZERODAY_SPAWN_MAX)
	boss_spawn_timer = randf_range(FIREWALL_SPAWN_MIN, FIREWALL_SPAWN_MAX)
	event_spawn_timer = randf_range(EVENT_SPAWN_MIN, EVENT_SPAWN_MAX)

	_build_generator_rows()
	_build_unlock_rows()
	_build_item_rows()
	_build_daemon_buttons()
	_build_daemon_rows()
	# Pastilles CARRÉES façon DOS (cohérent avec boutons/panneaux du reste du HUD) :
	# conquis = panneau gris plat, piratable = bouton cyan à ombre dure, verrouillé = grisé.
	_node_style_owned = _make_flat(Color(0.788, 0.788, 0.788), Color(0, 0, 0), 1, Vector2.ZERO)
	_node_style_hack = _make_flat(Color(0, 0.667, 0.667), Color(0, 0, 0), 1, Vector2(3, 3))
	_node_style_locked = _make_flat(Color(0.6, 0.6, 0.6), Color(0.3, 0.3, 0.3), 1, Vector2.ZERO)
	_regenerate_network()
	load_game()
	_setup_autosave()
	_seed_terminal()
	_pick_new_command()
	_apply_gating()
	_setup_audio()
	_update_display()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
		get_tree().quit()


func _build_generator_rows() -> void:
	for i in generators.size():
		var gen: Dictionary = generators[i]
		var row := GeneratorRowScene.instantiate() as GeneratorRow
		gen_container.add_child(row)
		row.setup(i)
		row.set_icon(load(gen.icon) as Texture2D, Color(0, 0, 0.5))  # bleu DOS
		row.buy_requested.connect(_on_gen_buy)
		gen_rows.append(row)


func _build_item_rows() -> void:
	for i in items.size():
		var it: Dictionary = items[i]
		var row := ItemRowScene.instantiate() as ItemRow
		shop_container.add_child(row)
		row.setup(i)
		row.set_icon(load(it.icon) as Texture2D, _category_color(it.category))
		row.buy_requested.connect(_on_item_buy)
		item_rows.append(row)


# Couleur DOS associée à chaque catégorie d'item (teinte d'icône sur fond gris clair).
func _category_color(category: String) -> Color:
	match category:
		"PUISSANCE":  return Color(0, 0, 0.5)         # bleu
		"EFFICACITE": return Color(0, 0.4, 0)         # vert
		"VARIETE":    return Color(0.541, 0, 0.541)   # magenta
	return Color(0, 0, 0)


# ---------------------------------------------------------------------------
# DÉBLOCAGE PROGRESSIF (onboarding)
# ---------------------------------------------------------------------------

# Accès par nom (pour les usages dynamiques : déblocage data-driven, gate d'aide, save/load).
func _is_unlocked(feature: String) -> bool:
	match feature:
		"augment":    return unlock_augment
		"daemons":    return unlock_daemons
		"operations": return unlock_operations
		"network":    return unlock_network
	return false


func _set_unlocked(feature: String, value: bool) -> void:
	match feature:
		"augment":    unlock_augment = value
		"daemons":    unlock_daemons = value
		"operations": unlock_operations = value
		"network":    unlock_network = value


# Applique la visibilité des mécaniques selon l'état de déblocage.
func _apply_gating() -> void:
	tabs.set_tab_hidden(1, not unlock_augment)
	tabs.set_tab_hidden(2, not unlock_daemons)
	tabs.set_tab_hidden(3, not unlock_network)
	daemons_panel.visible = unlock_daemons
	op_button.visible = unlock_operations
	ops_title.visible = unlock_operations
	ops_desc.visible = unlock_operations


func _unlock_feature(feature: String, announce_name: String, help: String) -> void:
	_set_unlocked(feature, true)
	_apply_gating()
	_play_sfx("unlock")
	_show_toast("DÉBLOQUÉ : %s" % announce_name, help, TOAST_SYS, 5.0)


# Entrées "mystère" de la boutique (en haut de l'onglet Augmentations).
func _build_unlock_rows() -> void:
	for i in unlocks.size():
		var row := ItemRowScene.instantiate() as ItemRow
		shop_container.add_child(row)
		row.setup(i)
		row.set_icon(load("res://assets/icons/circuitry.svg") as Texture2D, Color(1, 0.55, 0.2))
		row.buy_requested.connect(_on_unlock_buy)
		unlock_rows.append(row)


func _on_unlock_buy(index: int) -> void:
	var u: Dictionary = unlocks[index]
	if u.owned:
		return
	if fragments < u.cost:
		_set_status("Pas assez de Fragments (%d requis)." % int(u.cost))
		return
	fragments -= u.cost                 # dépense (ne touche pas au total cumulé)
	u.owned = true
	_unlock_feature(u.feature, u.name, u.help)
	_update_display()


func _refresh_unlock_row(i: int) -> void:
	var u: Dictionary = unlocks[i]
	var row: ItemRow = unlock_rows[i]
	# Apparaît seulement à partir du seuil, et disparaît une fois débloquée.
	row.visible = (total_fragments_earned >= u.reveal) and not u.owned
	if not row.visible:
		return
	row.refresh("[ ACCÈS VERROUILLÉ ]", "Débloque une capacité inconnue…", "Débloquer — %d Frag" % int(u.cost), fragments >= u.cost)


func _owned_unlock_ids() -> Array:
	var ids := []
	for u in unlocks:
		if u.owned:
			ids.append(u.id)
	return ids


# ---------------------------------------------------------------------------
# AIDE (P3)
# ---------------------------------------------------------------------------

var _help_active_style: StyleBoxFlat    # style du thème d'aide sélectionné (bloc bleu DOS)

func _build_help_topics() -> void:
	# Style de sélection : bloc bleu plein, comme une entrée surlignée sous DOS.
	_help_active_style = _make_flat(Color(0, 0, 0.8), Color(0, 0, 0), 1, Vector2(4, 4))
	_help_active_style.content_margin_left = 14.0
	_help_active_style.content_margin_right = 14.0
	_help_active_style.content_margin_top = 6.0
	_help_active_style.content_margin_bottom = 6.0
	for i in help_topics.size():
		var btn := Button.new()
		btn.text = help_topics[i].label
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect(_show_help_topic.bind(i))
		help_topics_bar.add_child(btn)
		help_buttons.append(btn)


const TRACE_TICKS := 48                 # nombre de barres verticales de la jauge de traçage

# Crée les barres verticales de la jauge de traçage (style barre de progression FreeDOS).
func _build_trace_ticks() -> void:
	for i in TRACE_TICKS:
		var tick := ColorRect.new()
		tick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tick.color = Color(0.6, 0.6, 0.6)   # gris "vide" par défaut
		tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
		trace_ticks.add_child(tick)


# Met à jour la jauge de traçage : remplissage + couleur selon le palier de menace.
func _update_trace_bar() -> void:
	var pct := clampf(trace / TRACE_MAX, 0.0, 1.0)
	var filled := int(round(pct * TRACE_TICKS))
	# Couleur selon la gravité : rouge (calme) -> orange (repéré) -> rouge vif clignotant (critique).
	var fill_col := Color(0.667, 0, 0)
	var state := "calme"
	if trace >= 85.0:
		state = "INTRUSION IMMINENTE"
		# Clignotement ~2/s en zone critique.
		var on := int(Time.get_ticks_msec() / 260) % 2 == 0
		fill_col = Color(0.88, 0, 0) if on else Color(0.45, 0, 0)
	elif trace >= 60.0:
		state = "repéré"
		fill_col = Color(0.8, 0.33, 0)
	var ticks := trace_ticks.get_children()
	for i in ticks.size():
		(ticks[i] as ColorRect).color = fill_col if i < filled else Color(0.6, 0.6, 0.6)
	trace_pct.text = "%d %%" % int(trace)
	trace_label.text = "TRAÇAGE — %s" % state


# Configure un item de menu FreeDOS : lettre-raccourci rouge au repos, tout blanc
# au survol, action au clic gauche. (RichTextLabel car un Button ne colore pas une lettre.)
func _setup_menu_item(item: RichTextLabel, base_bb: String, hover_bb: String, action: Callable) -> void:
	item.text = base_bb
	item.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			action.call())
	item.mouse_entered.connect(func() -> void: item.text = hover_bb)
	item.mouse_exited.connect(func() -> void: item.text = base_bb)


# ---------------------------------------------------------------------------
# MODAL DE CONFIRMATION (style newt : voile bleu + boîte claire à ombre dure)
# ---------------------------------------------------------------------------

var _confirm_action := Callable()       # action à exécuter si l'utilisateur confirme
var event_popup_active := false         # true pendant la popup d'alerte (boss/événement) : jeu en pause
var reward_choice_active := false       # true pendant la modale de choix de butin de boss : jeu en pause
var _reward_options: Array = []         # les 3 récompenses tirées, en attente du choix du joueur

# Affiche le modal. title/message (message en BBCode), texte du bouton OK.
# danger=true : action destructive -> focus par défaut sur Annuler, OK en rouge.
func _show_confirm(title: String, message_bb: String, ok_text: String, danger: bool, action: Callable) -> void:
	confirm_title.text = title
	confirm_msg.text = message_bb
	confirm_ok.text = ok_text
	confirm_ok.add_theme_color_override("font_color", Color(0.667, 0, 0) if danger else Color(0, 0, 0))
	_confirm_action = action
	confirm_overlay.visible = true
	confirm_overlay.modulate.a = 0.0
	create_tween().tween_property(confirm_overlay, "modulate:a", 1.0, 0.12)
	# Action destructive : le focus par défaut est sur Annuler (pas de destruction au réflexe).
	if danger:
		confirm_cancel.grab_focus()
	else:
		confirm_ok.grab_focus()


func _on_confirm_ok() -> void:
	confirm_overlay.visible = false
	var action := _confirm_action
	_confirm_action = Callable()
	if action.is_valid():
		action.call()


func _on_confirm_cancel() -> void:
	confirm_overlay.visible = false
	_confirm_action = Callable()


# ---------------------------------------------------------------------------
# POPUP D'ALERTE (boss / événement aléatoire) — même famille visuelle que
# le modal de confirmation, mais SANS bouton : lecture forcée puis reprise
# automatique. Le jeu est mis en pause (voir event_popup_active) pendant
# l'affichage, pour que le temps de lecture ne soit pas volé au combat/à
# l'événement (leur minuteur ne démarre qu'à la fermeture de la popup).
# ---------------------------------------------------------------------------

func _show_event_popup(title: String, message_bb: String, bar_color: Color) -> void:
	event_popup_title.text = title
	event_popup_msg.text = message_bb
	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = bar_color
	bar_style.content_margin_left = 20.0
	bar_style.content_margin_right = 20.0
	bar_style.content_margin_top = 12.0
	bar_style.content_margin_bottom = 12.0
	event_popup_bar.add_theme_stylebox_override("panel", bar_style)
	event_popup_active = true
	event_popup.visible = true
	event_popup.modulate.a = 0.0
	create_tween().tween_property(event_popup, "modulate:a", 1.0, 0.12)
	get_tree().create_timer(EVENT_POPUP_DURATION).timeout.connect(_hide_event_popup)


func _hide_event_popup() -> void:
	event_popup_active = false
	var t := create_tween()
	t.tween_property(event_popup, "modulate:a", 0.0, 0.2)
	t.tween_callback(func() -> void: event_popup.visible = false)


# Entrée de menu dédiée "Stats" : ouvre l'Aide directement sur ce thème.
func _open_stats() -> void:
	_open_help("stats")


# preferred_id : ouvre directement sur ce thème s'il est visible (ex. "stats" depuis
# son entrée de menu dédiée) ; sinon (ou si "") on retombe sur le 1er thème débloqué.
func _open_help(preferred_id: String = "") -> void:
	# On n'affiche que les thèmes des mécaniques débloquées (pas de spoiler).
	var first := -1
	var preferred := -1
	for i in help_topics.size():
		var gate: String = help_topics[i].gate
		var vis: bool = gate == "" or _is_unlocked(gate)
		help_buttons[i].visible = vis
		if vis and first < 0:
			first = i
		if vis and preferred_id != "" and help_topics[i].id == preferred_id:
			preferred = i
	if preferred >= 0:
		_show_help_topic(preferred)
	elif first >= 0:
		_show_help_topic(first)
	help_overlay.visible = true
	help_overlay.modulate.a = 0.0
	create_tween().tween_property(help_overlay, "modulate:a", 1.0, 0.15)


func _show_help_topic(i: int) -> void:
	var t: Dictionary = help_topics[i]
	var body: String = _build_stats_text() if t.id == "stats" else t.text
	help_text.text = "[color=#000080]%s[/color]\n\n%s" % [t.title, body]
	# Le thème actif passe en bloc bleu / texte blanc (sélection façon DOS).
	for j in help_buttons.size():
		var b := help_buttons[j]
		if j == i:
			b.add_theme_stylebox_override("normal", _help_active_style)
			b.add_theme_stylebox_override("hover", _help_active_style)
			b.add_theme_color_override("font_color", Color(1, 1, 1))
			b.add_theme_color_override("font_hover_color", Color(1, 1, 1))
		else:
			b.remove_theme_stylebox_override("normal")
			b.remove_theme_stylebox_override("hover")
			b.remove_theme_color_override("font_color")
			b.remove_theme_color_override("font_hover_color")


# Compose le texte de l'onglet "Stats" (calculé à chaque ouverture, pas mis en cache :
# ça doit refléter l'état courant de la partie).
func _build_stats_text() -> String:
	var mins := int(play_time / 60.0)
	var hours := mins / 60
	var time_str := "%dh%02d" % [hours, mins % 60] if hours > 0 else "%d min" % mins
	return "Temps de jeu : %s\nFragments d'IA cumulés : %d\nCompilations (prestiges) : %d\nBoss vaincus : %d\n\nMeilleur combo : x%d\nCommandes tapées : %d (dont %d rares)\nMeilleure run : %s o" % [
		time_str, total_fragments_earned, prestige_count, boss_level,
		best_combo, total_commands_typed, total_rare_typed, _fmt_short(best_run_earned),
	]


func _close_help() -> void:
	var tw := create_tween()
	tw.tween_property(help_overlay, "modulate:a", 0.0, 0.2)
	tw.tween_callback(func() -> void: help_overlay.visible = false)


# ---------------------------------------------------------------------------
# AUDIO
# ---------------------------------------------------------------------------

func _setup_audio() -> void:
	for k in SFX_FILES:
		_sfx_streams[k] = load(SFX_FILES[k])
	# Un petit pool de lecteurs pour permettre le chevauchement (frappe rapide).
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_players.append(p)
	# Musique d'ambiance en boucle.
	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)
	var amb = load("res://assets/audio/ambient.wav")
	if amb is AudioStreamWAV:
		amb.loop_mode = AudioStreamWAV.LOOP_FORWARD
		amb.loop_begin = 0
		amb.loop_end = amb.data.size() / 2   # 16-bit mono : 2 octets/échantillon
	_music_player.stream = amb
	_music_player.volume_db = -16.0
	_music_player.play()
	# On règle le slider AVANT de connecter (pour ne pas jouer un bip au démarrage).
	volume_slider.value = sfx_volume
	volume_slider.value_changed.connect(_on_volume_changed)
	_apply_mute()


func _on_volume_changed(v: float) -> void:
	sfx_volume = v
	_play_sfx("key")                    # petit bip témoin pour entendre le niveau


func _play_sfx(name: String, vol_db: float = 0.0, pitch: float = 1.0) -> void:
	if muted:
		return
	var st = _sfx_streams.get(name)
	if st == null:
		return
	var p := _sfx_players[_sfx_idx]
	_sfx_idx = (_sfx_idx + 1) % _sfx_players.size()
	p.stream = st
	p.volume_db = vol_db + linear_to_db(maxf(sfx_volume, 0.001))
	p.pitch_scale = pitch
	p.play()


# Tonalité de l'achat : montée LINÉAIRE selon le nombre déjà acquis (gamme ascendante
# qui reboucle tous les 12 crans pour rester agréable). Utilisé pour items/daemons/réseau.
func _buy_pitch_step(n: int) -> float:
	return 1.0 + float(n % 12) * 0.07


# Tonalité d'achat des GÉNÉRATEURS : fonction LINÉAIRE de la production totale (o/s).
# 1 o/s -> x1.0 ; 30000 o/s -> x2.5 ; au-delà plafonné à x2.5.
func _prod_pitch() -> float:
	return clampf(1.0 + (production_per_second() - 1.0) * (1.5 / 29999.0), 1.0, 2.5)


func _network_owned_count() -> int:
	var c: int = 0
	for nn in network_nodes:
		if nn.owned:
			c += 1
	return c


func _on_mute_pressed() -> void:
	muted = not muted
	_apply_mute()


func _apply_mute() -> void:
	if _music_player != null:
		_music_player.stream_paused = muted
	mute_button.text = "SON: OFF" if muted else "SON: ON"


# ---------------------------------------------------------------------------
# DAEMONS (capacités actives)
# ---------------------------------------------------------------------------

func _build_daemon_buttons() -> void:
	for i in daemons.size():
		var d: Dictionary = daemons[i]
		var btn := Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.tooltip_text = _daemon_desc(d)
		btn.focus_mode = Control.FOCUS_NONE   # pas de style "focus" persistant sur bouton désactivé
		btn.pressed.connect(_activate_daemon.bind(i))   # bind : passe l'index au callback
		daemons_bar.add_child(btn)
		daemon_buttons.append(btn)


func _activate_daemon(index: int) -> void:
	var d: Dictionary = daemons[index]

	# Daemon "à usage payant" (GHOST) : chaque activation coûte des Fragments.
	if d.get("pay_per_use", false):
		var use_cost := int(d.use_cost)
		if fragments < use_cost:
			_set_status("Pas assez de Fragments pour %s (%d requis)." % [d.name, use_cost])
			return
		fragments -= use_cost
		trace = 0.0
		if intrusion_active:
			_escape_intrusion()
		_set_status("GHOST : traçage effacé (-%d Fragment)." % use_cost)
		_flash(FX_GAIN, 0.25)
		_update_display()
		return

	# Daemons classiques (débloqués + cooldown).
	if d.level < 1:
		return                                          # verrouillé
	if d.cd_remaining > 0.0 or d.active_remaining > 0.0:
		return                                          # pas prêt
	d.cd_remaining = _daemon_cooldown(d)
	match d.id:
		"autopwn":
			d.active_remaining = _daemon_duration(d)
			_set_status("AUTOPWN actif : toute touche valide la commande !")
		"overclock":
			d.active_remaining = _daemon_duration(d)
			_set_status("OVERCLOCK : production x%d !" % int(OVERCLOCK_MULT))
	_flash(FX_SPECIAL, 0.25)
	_update_display()


# Un daemon "à durée" est-il actuellement actif ?
func _daemon_active(id: String) -> bool:
	for d in daemons:
		if d.id == id:
			return d.active_remaining > 0.0
	return false


# Valeurs effectives selon le niveau (cooldown baisse, durée monte).
func _daemon_cooldown(d: Dictionary) -> float:
	return maxf(15.0, d.base_cooldown * pow(0.9, maxi(0, d.level - 1)))


func _daemon_duration(d: Dictionary) -> float:
	return d.base_duration + maxi(0, d.level - 1) * d.duration_step


# Coût du prochain achat (déblocage si level 0, sinon amélioration) EN FRAGMENTS.
func daemon_cost(d: Dictionary) -> int:
	return int(ceil(d.frag_base * pow(d.frag_growth, d.level)))


# --- Onglet PROGRAMMES : déblocage / amélioration en Fragments ---

func _build_daemon_rows() -> void:
	for i in daemons.size():
		var d: Dictionary = daemons[i]
		var row := ItemRowScene.instantiate() as ItemRow
		daemon_container.add_child(row)
		row.setup(i)
		row.set_icon(load(d.icon) as Texture2D, Color(0, 0, 0.5))  # bleu DOS "programme"
		row.buy_requested.connect(_on_daemon_buy)
		# GHOST (usage payant) ne se débloque pas : pas de ligne dans l'onglet Programmes.
		row.visible = not d.get("pay_per_use", false)
		daemon_rows.append(row)


func _on_daemon_buy(index: int) -> void:
	var d: Dictionary = daemons[index]
	if d.level >= d.max_level:
		return
	var cost := daemon_cost(d)
	if fragments >= cost:
		fragments -= cost
		d.level += 1
		_play_sfx("buy", -3.0, _buy_pitch_step(d.level))
		_set_status("%s : %s (Nv %d)" % [d.name, "débloqué" if d.level == 1 else "amélioré", d.level])
	else:
		_set_status("Pas assez de Fragments pour %s." % d.name)
	_update_display()


func _daemon_desc(d: Dictionary) -> String:
	var cd := int(_daemon_cooldown(d))
	match d.id:
		"autopwn":   return "Valide toutes les touches %d s   —   recharge %d s" % [int(_daemon_duration(d)), cd]
		"ghost":     return "Efface le traçage / annule une intrusion   —   %d Fragment / usage" % int(d.use_cost)
		"overclock": return "Production x%d pendant %d s   —   recharge %d s" % [int(OVERCLOCK_MULT), int(_daemon_duration(d)), cd]
	return ""


func _refresh_daemon_row(i: int) -> void:
	var d: Dictionary = daemons[i]
	if d.get("pay_per_use", false):
		return                                          # pas de ligne d'amélioration pour GHOST
	var title := "%s   (verrouillé)" % d.name if d.level == 0 else "%s   Nv %d/%d" % [d.name, d.level, d.max_level]
	var maxed: bool = d.level >= d.max_level
	var cost := daemon_cost(d)
	var button_text := "MAX"
	if not maxed:
		button_text = "Débloquer — %d Frag" % cost if d.level == 0 else "Améliorer — %d Frag" % cost
	var buyable := (not maxed) and fragments >= cost
	daemon_rows[i].refresh(title, _daemon_desc(d), button_text, buyable)


func _setup_autosave() -> void:
	var timer := Timer.new()
	timer.wait_time = 15.0
	timer.autostart = true
	timer.timeout.connect(func() -> void: save_game())
	add_child(timer)


func _process(delta: float) -> void:
	if event_popup_active or reward_choice_active:
		return                              # jeu en pause : popup d'alerte ou choix de butin
	play_time += delta
	_earn(production_per_second() * delta)
	# Auto-clic : chaque "clic auto" vaut autant qu'un clic manuel.
	var auto_rate := item_autoclick_rate()
	if auto_rate > 0.0:
		_earn(click_value() * auto_rate * delta)
	_update_timers(delta)
	_update_display()


# Fait avancer tous les compteurs de temps de la couche "hack à risque".
func _update_timers(delta: float) -> void:
	# Le combo de frappe retombe si on arrête de taper.
	if combo > 0:
		combo_timer += delta
		if combo_timer >= COMBO_DECAY:
			combo = 0
			combo_timer = 0.0

	# Cooldown des opérations.
	if op_cooldown_remaining > 0.0:
		op_cooldown_remaining = maxf(0.0, op_cooldown_remaining - delta)

	# La jauge de traçage redescend doucement (sauf malus actif ou intrusion en cours).
	if trace > 0.0 and malus_remaining <= 0.0 and not intrusion_active:
		trace = maxf(0.0, trace - TRACE_DECAY * delta)

	# Compte à rebours de la contre-mesure : si le temps s'écoule, l'intrusion réussit.
	if intrusion_active:
		intrusion_timer -= delta
		if intrusion_timer <= 0.0:
			_fail_intrusion()

	# Cooldowns et durées d'effet des daemons.
	for d in daemons:
		if d.cd_remaining > 0.0:
			d.cd_remaining = maxf(0.0, d.cd_remaining - delta)
		if d.active_remaining > 0.0:
			d.active_remaining = maxf(0.0, d.active_remaining - delta)

	# Événements aléatoires (une fois le jeu un peu avancé : après le 1er prestige).
	if unlock_augment:
		if event_active:
			event_timer -= delta
			if event_timer <= 0.0:
				_end_event()
		elif not boss_active:
			# Pas d'événement pendant un boss : on GÈLE le timer (pas de décompte) pour
			# ne pas cumuler les pressions, ni faire pop un événement pile à la fin du boss.
			event_spawn_timer -= delta
			if event_spawn_timer <= 0.0:
				_start_random_event()

	# Boss firewall : apparition périodique, puis compte à rebours pour le briser.
	if boss_active:
		boss_timer -= delta
		if boss_timer <= 0.0:
			_fail_boss()
	elif not event_active:
		# Symétrique : on ne lance pas de boss pendant un événement (timer gelé aussi).
		boss_spawn_timer -= delta
		if boss_spawn_timer <= 0.0 and unlock_operations:
			_start_boss()

	# Malus "TRACÉ" et buff "faille" : on décompte leur durée.
	if malus_remaining > 0.0:
		malus_remaining = maxf(0.0, malus_remaining - delta)
	if zeroday_buff_remaining > 0.0:
		zeroday_buff_remaining = maxf(0.0, zeroday_buff_remaining - delta)
	if click_buff_remaining > 0.0:
		click_buff_remaining = maxf(0.0, click_buff_remaining - delta)
	if rwd_prod_remaining > 0.0:
		rwd_prod_remaining = maxf(0.0, rwd_prod_remaining - delta)

	# Gestion des failles zero-day.
	if zeroday_window_remaining > 0.0:
		# Une faille est affichée : le joueur a un temps limité pour cliquer.
		zeroday_window_remaining -= delta
		if zeroday_window_remaining <= 0.0:
			zeroday_window_remaining = 0.0
			_set_zeroday_shown(false)
			zeroday_spawn_timer = randf_range(ZERODAY_SPAWN_MIN, ZERODAY_SPAWN_MAX)
			_set_status("Faille zero-day manquée.")
	else:
		# Aucune faille : on attend la prochaine apparition (si Opérations débloquées).
		zeroday_spawn_timer -= delta
		if zeroday_spawn_timer <= 0.0 and unlock_operations:
			_spawn_zeroday()


# Multiplicateur temporaire venant des événements (faille et/ou malus de traçage).
func event_multiplier() -> float:
	var m: float = 1.0
	if zeroday_buff_remaining > 0.0:
		m *= ZERODAY_MULT
	if rwd_prod_remaining > 0.0:
		m *= rwd_prod_mult
	if malus_remaining > 0.0:
		m *= MALUS_MULT
	if _daemon_active("overclock"):
		m *= OVERCLOCK_MULT
	if event_active and event_id == "surcharge":
		m *= EVENT_SURCHARGE_MULT
	return m


func _earn(amount: float) -> void:
	data += amount
	run_earned += amount
	best_run_earned = maxf(best_run_earned, run_earned)


# Point de passage unique pour tout gain de Fragments (suit l'objectif de fin).
func _gain_fragments(n: int) -> void:
	fragments += n
	total_fragments_earned += n


# ---------------------------------------------------------------------------
# EFFETS DES ITEMS (chaque fonction agrège tous les items concernés)
# ---------------------------------------------------------------------------

func item_prod_mult() -> float:
	var m: float = 1.0
	var distinct := _distinct_generators_owned()
	for it in items:
		if it.effect == "prod_mult":
			m += it.level * it.value
		elif it.effect == "synergy":
			m += it.level * it.value * distinct   # récompense la diversité
	return m


func item_click_mult() -> float:
	var m: float = 1.0
	for it in items:
		if it.effect == "click_mult":
			m += it.level * it.value
	return m


# Facteur multiplicatif sur le coût des générateurs (jamais sous 20 %).
func item_cost_factor() -> float:
	var f: float = 1.0
	for it in items:
		if it.effect == "cost_reduc":
			f *= pow(1.0 - it.value, it.level)
	return maxf(f, 0.2)


func item_autoclick_rate() -> float:
	var r: float = 0.0
	for it in items:
		if it.effect == "autoclick":
			r += it.level * it.value
	return r


func _distinct_generators_owned() -> int:
	var n: int = 0
	for gen in generators:
		if gen.count > 0:
			n += 1
	return n


# ---------------------------------------------------------------------------
# NOMBRES DU JEU
# ---------------------------------------------------------------------------

func prestige_multiplier() -> float:
	return 1.0 + fragments * FRAGMENT_BONUS


# Valeur d'un clic (manuel ou auto), tous bonus inclus.
func click_value() -> float:
	return per_click * prestige_multiplier() * item_click_mult() * network_click_mult() * reward_click_mult()


# Multiplicateur temporaire de clic (récompense de boss FRAPPE/DÉLUGE).
func reward_click_mult() -> float:
	return click_buff_mult if click_buff_remaining > 0.0 else 1.0


func production_per_second() -> float:
	var base: float = 0.0
	for gen in generators:
		base += gen.count * gen.production
	return base * prestige_multiplier() * item_prod_mult() * event_multiplier() * network_prod_mult() * combo_prod_mult()


func cost_of(gen: Dictionary) -> float:
	return ceil(gen.base_cost * pow(gen.cost_growth, gen.count) * item_cost_factor() * network_cost_factor())


func item_cost(it: Dictionary) -> int:
	return int(ceil(it.base_cost * pow(it.cost_growth, it.level)))


func pending_fragments() -> int:
	return int(floor(sqrt(run_earned / PRESTIGE_DIV)))


# Données à accumuler dans la run pour atteindre `n` fragments.
# Inverse de la formule pending : run_earned = n² × PRESTIGE_DIV.
func fragments_threshold(n: int) -> float:
	return float(n) * n * PRESTIGE_DIV


# ---------------------------------------------------------------------------
# ACTIONS
# ---------------------------------------------------------------------------

# Tout clic gauche sur le terminal déclenche un piratage "manuel" (+1).
func _on_terminal_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_do_hack(terminal.global_position + event.position)


# --- Mini-jeu de frappe -----------------------------------------------------

# _input() reçoit TOUTES les entrées. On y capte les touches du clavier.
func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	# Plein écran : action "fenêtre système", jamais bloquée (même par une popup/un écran plein).
	if event.keycode == KEY_F11:
		var w := get_window()
		w.mode = Window.MODE_WINDOWED if w.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
		get_viewport().set_input_as_handled()
		return
	# Modale de choix de butin : 1/2/3 sélectionnent directement une carte. On ne consomme
	# QUE ces touches : Entrée/Tab/flèches restent au système de focus (navigation des cartes),
	# et le mini-jeu de frappe plus bas reste gelé (return) tant que la modale est ouverte.
	if reward_choice_active:
		if event.keycode == KEY_1 or event.keycode == KEY_KP_1:
			_pick_reward(0)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_2 or event.keycode == KEY_KP_2:
			_pick_reward(1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_3 or event.keycode == KEY_KP_3:
			_pick_reward(2)
			get_viewport().set_input_as_handled()
		return
	# Raccourcis "touches de fonction" façon DOS (annoncés dans la barre de statut).
	if event_popup_active:
		return                              # clavier en pause pendant la popup d'alerte
	if event.keycode == KEY_F1:
		if help_overlay.visible:
			_close_help()
		else:
			_open_help()
		get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_F5:
		_on_save_pressed()
		get_viewport().set_input_as_handled()
		return
	if confirm_overlay.visible or busted_overlay.visible or victory_overlay.visible or help_overlay.visible:
		return                              # clavier en pause pendant confirmation / écrans pleins
	var u: int = event.unicode
	if u < 32:                              # on ignore les touches non imprimables (Entrée, Tab...)
		return
	_type_char(String.chr(u))
	# On "consomme" la touche pour qu'elle n'active pas un bouton ayant le focus.
	get_viewport().set_input_as_handled()


func _type_char(ch: String) -> void:
	if current_command.is_empty():
		return
	var expected := current_command.substr(typed_len, 1)
	if _daemon_active("autopwn"):
		ch = expected                       # AUTOPWN : n'importe quelle touche est validée
	if ch == expected:
		typed_len += 1
		combo_timer = 0.0
		_play_sfx("key", -9.0)
		_earn(click_value())                # chaque bonne lettre vaut un clic
		_pop(data_label)
		if typed_len >= current_command.length():
			if intrusion_active:
				_escape_intrusion()         # on a tapé la commande de purge à temps
			elif final_command_active:
				_awaken_ai()                # commande d'éveil complétée : victoire !
			else:
				_complete_command()
		_update_display()
	elif intrusion_active:
		# Pendant l'alerte : une faute grignote le temps restant (pression accrue).
		_shake(command_label)
		_play_sfx("key_wrong", -5.0)
		intrusion_timer = maxf(0.0, intrusion_timer - 0.5)
		_update_display()
	else:
		# Mauvaise touche : on casse le combo et on fait monter le traçage.
		_shake(command_label)
		_play_sfx("key_wrong", -5.0)
		if boss_active and boss_type.get("gimmick", "") == "typo_heal":
			boss_hp = minf(boss_max_hp, boss_hp + BOSS_TYPO_HEAL)
		if combo > 0:
			_set_status("Frappe ratée ! Combo perdu.")
		combo = 0
		combo_timer = 0.0
		trace = minf(TRACE_MAX, trace + WRONG_KEY_TRACE)
		if trace >= TRACE_MAX:
			_start_intrusion()
		_update_display()


func _complete_command() -> void:
	# Bonus de fin : proportionnel à la longueur de la commande et au combo actuel.
	var bonus := click_value() * current_command.length() * _combo_multiplier()
	var rare := current_is_rare
	if rare:
		bonus *= RARE_BONUS_MULT
		combo += 2                          # une commande rare vaut deux paliers de combo
	else:
		combo += 1
	_earn(bonus)
	combo_timer = 0.0
	best_combo = maxi(best_combo, combo)
	total_commands_typed += 1
	if rare:
		total_rare_typed += 1

	_term_log(current_command, int(bonus), rare)

	var col := FX_SPECIAL if rare else FX_GAIN
	_spawn_floating_text("+%d o  COMBO x%d" % [int(bonus), combo], _center_of(terminal), col)
	_burst_particles(_center_of(terminal))
	_flash(col, 0.28 if rare else 0.18)
	_play_sfx("rare" if rare else "command", -3.0)

	# Dégâts au boss, modulés par son gimmick.
	if boss_active:
		var g: String = boss_type.get("gimmick", "")
		var dmg: float = float(current_command.length())
		if g == "rare_only" and not rare:
			dmg *= 0.2                       # EDR : les commandes normales pèsent peu
		elif g == "throttle":
			dmg = BOSS_THROTTLE_DMG          # AntiDDOS : dégâts fixes, le volume compte
		boss_hp = maxf(0.0, boss_hp - dmg)
		if boss_hp <= 0.0:
			_defeat_boss()

	_pick_new_command()


func _combo_multiplier() -> float:
	return 1.0 + combo * COMBO_STEP


# Bonus de PRODUCTION tant que le combo tient : taper activement dope l'économie.
func combo_prod_mult() -> float:
	return 1.0 + mini(combo, COMBO_PROD_CAP) * COMBO_PROD_STEP


# Tire la prochaine commande. Plus le combo est haut, plus une commande RARE
# (longue, très rémunératrice) a de chances d'apparaître.
func _pick_new_command() -> void:
	# Objectif atteint et pas encore gagné : on impose la commande d'ÉVEIL.
	if not has_won and total_fragments_earned >= AWAKEN_TARGET:
		current_command = AWAKEN_COMMAND
		current_is_rare = false
		final_command_active = true
		typed_len = 0
		return
	final_command_active = false
	var rare_chance := clampf(0.15 + combo * 0.04, 0.0, 0.6)
	if combo >= RARE_COMBO_THRESHOLD and randf() < rare_chance:
		current_command = COMMANDS_RARE[randi() % COMMANDS_RARE.size()]
		current_is_rare = true
	else:
		current_command = COMMANDS[randi() % COMMANDS.size()]
		current_is_rare = false
	typed_len = 0


# Affiche la commande : tapé en vert, prochain caractère surligné, reste en gris.
func _update_typing_ui() -> void:
	var done := current_command.substr(0, typed_len)
	var rest := current_command.substr(typed_len)
	var next_ch := rest.substr(0, 1)
	var after := rest.substr(1) if rest.length() > 1 else ""

	# Mode ALERTE : commande de purge en rouge/orange + compte à rebours.
	if intrusion_active:
		command_label.text = "[color=#ff3030][ALERTE] [/color][color=#ff8a3a]%s[/color][bgcolor=#ff3030][color=#0a0e14]%s[/color][/bgcolor][color=#7a4a4a]%s[/color]" % [done, next_ch, after]
		term_hint.text = "INTRUSION — échappe-toi en %.1f s" % intrusion_timer
		term_hint.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
		return

	# Mode ÉVEIL : la commande finale, en doré.
	if final_command_active:
		command_label.text = "[color=#ffcf40]// ÉVEIL // [/color][color=#5dffa0]%s[/color][bgcolor=#ffcf40][color=#0a0e14]%s[/color][/bgcolor][color=#6a6040]%s[/color]" % [done, next_ch, after]
		term_hint.text = "Tape la commande d'ÉVEIL pour atteindre la SINGULARITÉ"
		term_hint.add_theme_color_override("font_color", Color(1, 0.81, 0.25))
		return

	# Brouillage : événement INSTABILITÉ ou boss CHIFFREMENT SSL.
	if (event_active and event_id == "instabilite") or (boss_active and boss_type.get("gimmick", "") == "glitch"):
		var s := "[color=#5dffa0]%s[/color]" % done
		for j in range(typed_len, current_command.length()):
			var real := current_command.substr(j, 1)
			var glitched := _glitch_hash(j) < 4
			var shown := _glitch_char(j) if glitched else real
			if j == typed_len:
				s += "[bgcolor=#ff2a99][color=#0a0e14]%s[/color][/bgcolor]" % shown
			elif glitched:
				s += "[color=#ff5a46]%s[/color]" % shown
			else:
				s += "[color=#4d6b68]%s[/color]" % shown
		command_label.text = s
		term_hint.text = "INSTABILITÉ — signal brouillé (%.0f s)" % event_timer
		term_hint.add_theme_color_override("font_color", Color(1, 0.35, 0.3))
		return

	var prefix := "[color=#ffcf40][RARE] [/color]" if current_is_rare else ""
	command_label.text = "%s[color=#33ff33]%s[/color][bgcolor=#cccccc][color=#000000]%s[/color][/bgcolor][color=#338844]%s[/color]" % [prefix, done, next_ch, after]
	if combo > 0:
		term_hint.text = "COMBO x%d   —   PRODUCTION +%d%%" % [combo, int((combo_prod_mult() - 1.0) * 100)]
		term_hint.add_theme_color_override("font_color", Color(0, 0.85, 0.85))
	else:
		term_hint.text = "Tape la commande ci-dessus   (ou clique = +1)"
		term_hint.add_theme_color_override("font_color", Color(0, 0.7, 0.7))


# ---------------------------------------------------------------------------
# FIN DE PARTIE : éveil de l'IA (Singularité)
# ---------------------------------------------------------------------------

func _awaken_ai() -> void:
	has_won = true
	final_command_active = false
	_flash(FX_SPECIAL, 0.8)
	_play_sfx("victory")
	_burst_particles(_center_of(terminal))
	save_game()
	_show_victory()
	_pick_new_command()                 # repasse en commandes normales (mode libre)


func _show_victory() -> void:
	var mins := int(play_time / 60.0)
	victory_stats.text = "Fragments d'IA cumulés : %d\nCompilations (prestiges) : %d\nTemps de jeu : %d min" % [total_fragments_earned, prestige_count, mins]
	victory_overlay.visible = true
	victory_overlay.modulate.a = 0.0
	await get_tree().process_frame
	victory_panel.pivot_offset = victory_panel.size / 2.0
	victory_panel.scale = Vector2(0.7, 0.7)
	var t := create_tween().set_parallel(true)
	t.tween_property(victory_overlay, "modulate:a", 1.0, 0.35)
	t.tween_property(victory_panel, "scale", Vector2(1.05, 1.05), 0.45) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.set_parallel(false)
	t.tween_property(victory_panel, "scale", Vector2(1, 1), 0.15)


func _on_continue_pressed() -> void:
	var t := create_tween()
	t.tween_property(victory_overlay, "modulate:a", 0.0, 0.3)
	t.tween_callback(func() -> void: victory_overlay.visible = false)


# ---------------------------------------------------------------------------
# ÉVÉNEMENTS ALÉATOIRES (P4)
# ---------------------------------------------------------------------------

func _start_random_event() -> void:
	event_id = ["instabilite", "surcharge"][randi() % 2]
	event_active = true
	event_timer = EVENT_DURATION
	_flash(FX_EVENT, 0.3)
	match event_id:
		"instabilite":
			_play_sfx("glitch")
			_show_event_popup("INSTABILITÉ CONNEXION", "La commande est brouillée pendant %d s — tape à l'instinct !" % int(EVENT_DURATION), FX_EVENT)
		"surcharge":
			_play_sfx("overload")
			_show_event_popup("SURCHARGE RÉSEAU", "Production réduite pendant %d s." % int(EVENT_DURATION), FX_EVENT)


func _end_event() -> void:
	event_active = false
	event_id = ""
	event_spawn_timer = randf_range(EVENT_SPAWN_MIN, EVENT_SPAWN_MAX)
	_play_sfx("stable", -4.0)
	_show_toast("RÉSEAU STABILISÉ", "Retour à la normale.", TOAST_WIN, 5.0)


# Brouillage déterministe qui change ~8x/seconde (lettres qui clignotent).
func _glitch_hash(j: int) -> int:
	var slot := int(Time.get_ticks_msec() / 120)
	return abs(hash("%d_%d" % [j, slot])) % 10


func _glitch_char(j: int) -> String:
	var slot := int(Time.get_ticks_msec() / 120)
	var idx: int = abs(hash("%d x %d" % [j, slot])) % GLITCH_CHARS.length()
	return GLITCH_CHARS.substr(idx, 1)


func _do_hack(at_pos: Vector2) -> void:
	var gain := click_value()
	_earn(gain)
	_add_terminal_line(gain)
	# Feedback visuel : +X flottant, pop du compteur, jet de particules.
	_spawn_floating_text("+%d o" % int(gain), at_pos, FX_GAIN)
	_pop(data_label)
	_burst_particles(at_pos)
	_update_display()


# Journalise une ligne façon flux de commandes DOS :
#   A:\> <label> ........ OK   +N o
# Police monospace -> les points de conduite alignent la colonne OK/gain.
func _term_log(label: String, gain: int, rare := false, ok := true) -> void:
	var tag := "[color=#ffcf40][RARE] [/color]" if rare else ""
	var dots := ".".repeat(maxi(3, 40 - label.length()))
	var status := "[color=#3aaa3a]OK[/color]" if ok else "[color=#aa6a2a]…[/color]"
	var line := "[color=#4fd04f]A:\\> [/color]%s[color=#c9f2d1]%s[/color] [color=#2f5f2f]%s[/color] %s  [color=#ffe14d]+%d o[/color]" % [tag, label, dots, status, gain]
	term_lines.append(line)
	if term_lines.size() > 40:
		term_lines.pop_front()
	terminal_log.text = "\n".join(PackedStringArray(term_lines))


# Ajoute une ligne "hacker" au log du terminal quand on clique (pas une vraie commande tapée).
func _add_terminal_line(gain: float) -> void:
	var flavor: String = HACK_LINES[randi() % HACK_LINES.size()]
	_term_log(flavor, int(gain), false, false)


func _seed_terminal() -> void:
	term_lines = [
		"[color=#3aaa3a]NEXUS OS %s — 640K OK[/color]" % GAME_VERSION,
		"[color=#5c9c5c]system: nexus online[/color]",
		"[color=#5c9c5c]link: tunnel chiffré établi[/color]",
		"[color=#5c9c5c]awaiting input...[/color]",
	]
	terminal_log.text = "\n".join(PackedStringArray(term_lines))


func _on_gen_buy(index: int) -> void:
	var gen: Dictionary = generators[index]
	var cost := cost_of(gen)
	if data >= cost:
		data -= cost
		gen.count += 1
		_play_sfx("buy", -4.0, _prod_pitch())
	_update_display()


func _on_item_buy(index: int) -> void:
	var it: Dictionary = items[index]
	if it.level >= it.max_level:
		return
	var cost := item_cost(it)
	if fragments >= cost:
		fragments -= cost
		it.level += 1
		_play_sfx("buy", -3.0, _buy_pitch_step(it.level))
		_set_status("Amélioré : %s (Nv %d)" % [it.name, it.level])
	else:
		_set_status("Pas assez de Fragments pour %s." % it.name)
	_update_display()


# --- Opérations à risque ----------------------------------------------------

func _on_operation_pressed() -> void:
	if op_cooldown_remaining > 0.0:
		return
	op_cooldown_remaining = OP_COOLDOWN
	if randf() < OP_SUCCESS_CHANCE:
		# Réussite : gain = X secondes de production (ou un plancher en début de partie).
		var reward := maxf(production_per_second() * OP_REWARD_SECONDS, click_value() * OP_MIN_REWARD_CLICKS)
		_earn(reward)
		_set_status("Opération réussie : +%d o !" % int(reward))
		_spawn_floating_text("+%d o" % int(reward), _center_of(op_button), FX_GAIN)
		_pop(data_label)
		_burst_particles(_center_of(op_button))
	else:
		# Échec : la jauge de traçage monte.
		trace = minf(TRACE_MAX, trace + TRACE_PER_FAIL)
		_spawn_floating_text("ÉCHEC", _center_of(op_button), FX_ALERT)
		_shake(op_button)
		if trace >= TRACE_MAX:
			_start_intrusion()
		else:
			_set_status("Opération échouée : traçage +%d%%" % int(TRACE_PER_FAIL))
	_update_display()


# Déclenche l'alerte : le joueur doit taper la commande de purge à temps.
func _start_intrusion() -> void:
	if intrusion_active:
		return
	intrusion_active = true
	intrusion_timer = INTRUSION_TIME
	current_command = ESCAPE_COMMANDS[randi() % ESCAPE_COMMANDS.size()]  # tirée au hasard
	typed_len = 0
	current_is_rare = false
	final_command_active = false        # l'intrusion prime : on n'est plus sur la commande d'éveil
	combo = 0
	_flash(FX_ALERT, 0.45)
	_play_sfx("alert")
	_set_status("INTRUSION DÉTECTÉE ! Tape « %s » avant la fin du compte à rebours !" % current_command)


# Réussite : logs purgés, on évite complètement le malus.
func _escape_intrusion() -> void:
	intrusion_active = false
	trace = 0.0
	_flash(FX_GAIN, 0.3)
	_spawn_floating_text("ÉCHAPPÉ !", _center_of(terminal), FX_GAIN)
	_burst_particles(_center_of(terminal))
	_set_status("Logs purgés — tu t'es échappé à temps !")
	_pick_new_command()


# Échec : le traçage aboutit. Sanction lourde : on PERD tous les octets accumulés,
# en plus du ralentissement de production. Le traçage devient un vrai enjeu.
func _fail_intrusion() -> void:
	var lost := data                    # on mémorise ce qui est perdu AVANT d'effacer
	intrusion_active = false
	trace = 0.0
	malus_remaining = MALUS_DURATION
	data = 0.0                          # remise à zéro des Données (octets)
	_show_busted(lost)
	_pick_new_command()


# Écran "TRACÉ" plein écran (façon BUSTED) : montre l'impact de l'échec.
func _show_busted(lost: float) -> void:
	busted_lost.text = "Données effacées : -%d o" % int(lost)
	busted_malus.text = "Production divisée par %d pendant %d s" % [int(1.0 / MALUS_MULT), int(MALUS_DURATION)]
	busted_overlay.visible = true
	busted_overlay.modulate.a = 0.0
	_flash(FX_ALERT, 0.7)
	_play_sfx("alert", 2.0)
	_set_status("TRACÉ ! Données effacées.")

	# On attend une frame pour que le panneau ait sa taille (pivot correct).
	await get_tree().process_frame
	busted_panel.pivot_offset = busted_panel.size / 2.0
	busted_panel.scale = Vector2(0.7, 0.7)
	var t := create_tween().set_parallel(true)
	t.tween_property(busted_overlay, "modulate:a", 1.0, 0.15)
	t.tween_property(busted_panel, "scale", Vector2(1.08, 1.08), 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.set_parallel(false)
	t.tween_property(busted_panel, "scale", Vector2(1, 1), 0.12)
	t.tween_callback(func() -> void: _shake(busted_panel))

	# Auto-fermeture après quelques secondes (ou au clic).
	get_tree().create_timer(5.0).timeout.connect(_hide_busted)


func _hide_busted() -> void:
	if not busted_overlay.visible:
		return
	var t := create_tween()
	t.tween_property(busted_overlay, "modulate:a", 0.0, 0.3)
	t.tween_callback(func() -> void: busted_overlay.visible = false)


func _on_busted_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_hide_busted()


# Bandeau d'information non-bloquant (apparaît, reste ~duration s, disparaît).
const TOAST_MAX_STACK := 4              # nb max de toasts empilés simultanément

# Empile un toast newt (boîte claire à ombre, bande de titre colorée par type) en haut
# à droite. 'color' = couleur DOS de la bande (voir constantes TOAST_* ci-dessous).
func _show_toast(title: String, message: String, color: Color, duration: float = 2.6) -> void:
	var bar_col := color

	# Boîte claire à bord noir + ombre portée dure (style newt).
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", _make_flat(Color(0.851, 0.851, 0.851), Color(0, 0, 0), 1, Vector2(6, 6)))
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 0)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(vb)

	# Bande de titre colorée selon le type.
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", _make_bar_style(bar_col))
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tl := Label.new()
	tl.text = title
	tl.add_theme_color_override("font_color", Color(1, 1, 1))
	tl.add_theme_font_size_override("font_size", 16)
	bar.add_child(tl)
	vb.add_child(bar)

	# Corps du message (texte noir sur la boîte claire).
	var mm := MarginContainer.new()
	mm.add_theme_constant_override("margin_left", 11)
	mm.add_theme_constant_override("margin_right", 11)
	mm.add_theme_constant_override("margin_top", 8)
	mm.add_theme_constant_override("margin_bottom", 9)
	var ml := Label.new()
	ml.text = message
	ml.add_theme_color_override("font_color", Color(0, 0, 0))
	ml.add_theme_font_size_override("font_size", 14)
	ml.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mm.add_child(ml)
	vb.add_child(mm)

	toast_stack.add_child(box)
	# Limite la pile : on retire le plus ancien si on dépasse.
	while toast_stack.get_child_count() > TOAST_MAX_STACK:
		toast_stack.get_child(0).queue_free()

	# Apparition en fondu.
	box.modulate.a = 0.0
	create_tween().tween_property(box, "modulate:a", 1.0, 0.18)

	# Disparition automatique après 'duration'.
	get_tree().create_timer(duration).timeout.connect(func() -> void: _dismiss_toast(box))


func _dismiss_toast(box: Control) -> void:
	if not is_instance_valid(box):
		return
	var t := create_tween()
	t.tween_property(box, "modulate:a", 0.0, 0.3)
	t.tween_callback(box.queue_free)


# Teintes DOS des bandes de toast, par type sémantique.
const TOAST_ALERT := Color(0.667, 0, 0)    # rouge : boss, danger, échec
const TOAST_WIN := Color(0, 0.43, 0)       # vert : victoire, gain
const TOAST_EVENT := Color(0.7, 0.33, 0)   # orange : événement temporaire
const TOAST_SYS := Color(0, 0, 0.8)        # bleu : déblocage, système
const TOAST_FRAG := Color(0.541, 0, 0.541) # magenta : prestige / fragments


# Petit fabricant de StyleBoxFlat carré (fond + bord + ombre dure optionnelle).
func _make_flat(bg: Color, border: Color, border_w: int, shadow_off: Vector2) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_width_left = border_w
	s.border_width_top = border_w
	s.border_width_right = border_w
	s.border_width_bottom = border_w
	s.border_color = border
	if shadow_off != Vector2.ZERO:
		s.shadow_color = Color(0, 0, 0)
		s.shadow_size = 1
		s.shadow_offset = shadow_off
	return s


func _make_bar_style(col: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = col
	s.content_margin_left = 10.0
	s.content_margin_right = 10.0
	s.content_margin_top = 3.0
	s.content_margin_bottom = 3.0
	return s


# ---------------------------------------------------------------------------
# BOSS FIREWALL
# ---------------------------------------------------------------------------

func _start_boss() -> void:
	boss_type = BOSS_TYPES[randi() % BOSS_TYPES.size()]
	boss_active = true
	boss_max_hp = FIREWALL_BASE_HP * (1.0 + boss_level * FIREWALL_HP_GROWTH) * float(boss_type.hp_mult)
	boss_hp = boss_max_hp
	boss_timer = float(boss_type.time)
	boss_panel.visible = true
	boss_title.text = "/// %s ///" % boss_type.name
	_flash(FX_ALERT, 0.4)
	_play_sfx("boss")
	_show_event_popup(boss_type.name + " DÉTECTÉ", boss_type.desc, FX_ALERT)
	_set_status("%s détecté ! %s" % [boss_type.name, boss_type.desc])


func _defeat_boss() -> void:
	boss_active = false
	boss_panel.visible = false
	boss_level += 1
	boss_spawn_timer = randf_range(FIREWALL_SPAWN_MIN, FIREWALL_SPAWN_MAX)

	# Célébration immédiate de la casse du firewall (le butin, lui, se choisit ensuite).
	_flash(FX_GAIN, 0.5)
	_spawn_floating_text("FIREWALL BRISÉ !", _center_of(terminal), FX_GAIN)
	_burst_particles(_center_of(terminal))
	_play_sfx("victory")

	# Butin de base = fraction de ta production ACTUELLE (donc dépend de TOUT : générateurs,
	# prestige, items, buffs actifs) × difficulté du firewall × maîtrise au clavier (combo).
	var level_mult := 1.0 + boss_level * FIREWALL_REWARD_LEVEL_STEP
	var combo_mult := 1.0 + combo * FIREWALL_COMBO_STEP
	var base_octets := maxf(production_per_second() * FIREWALL_REWARD_SECONDS, click_value() * 150.0) * level_mult * combo_mult
	var base_frags := 1 + int(boss_level / 2)   # les firewalls plus durs donnent plus de Fragments

	# On tire 3 récompenses distinctes (tirage PONDÉRÉ par rareté), puis le joueur choisit.
	var picks := _draw_rewards(_boss_reward_pool(base_octets, base_frags), 3)
	_show_reward_choice(picks)


# Construit le pool complet des récompenses possibles, dimensionnées sur le butin de ce combat.
# Chaque entrée : rarity (commune/rare/legendaire), title (nom court), detail (effet chiffré),
# kind (type d'effet appliqué) + paramètres (value / mult / dur selon le kind).
func _boss_reward_pool(octets: float, frags: int) -> Array:
	return [
		# --- COMMUNES ---------------------------------------------------------
		{"rarity": "commune", "title": "BUTIN",  "kind": "octets", "value": octets * 1.5,
			"detail": "+%s o" % _fmt_short(octets * 1.5)},
		{"rarity": "commune", "title": "CACHE",  "kind": "frags", "value": float(maxi(2, frags * 2)),
			"detail": "+%d Frag" % maxi(2, frags * 2)},
		{"rarity": "commune", "title": "FAILLE", "kind": "prod", "mult": 3.0, "dur": 30.0,
			"detail": "prod ×3 / 30s"},
		{"rarity": "commune", "title": "PURGE",  "kind": "trace", "value": 40.0,
			"detail": "traçage −40"},
		{"rarity": "commune", "title": "FRAPPE", "kind": "clic", "mult": 4.0, "dur": 20.0,
			"detail": "clic ×4 / 20s"},
		# --- RARES ------------------------------------------------------------
		{"rarity": "rare", "title": "JACKPOT", "kind": "octets", "value": octets * 4.0,
			"detail": "+%s o" % _fmt_short(octets * 4.0)},
		{"rarity": "rare", "title": "COFFRE",  "kind": "frags", "value": float(maxi(3, frags * 5)),
			"detail": "+%d Frag" % maxi(3, frags * 5)},
		{"rarity": "rare", "title": "SURRÉGIME", "kind": "prod", "mult": 3.0, "dur": 90.0,
			"detail": "prod ×3 / 90s"},
		{"rarity": "rare", "title": "BLANCHIMENT", "kind": "trace", "value": TRACE_MAX,
			"detail": "traçage → 0"},
		# --- LÉGENDAIRES ------------------------------------------------------
		{"rarity": "legendaire", "title": "MAGOT",  "kind": "octets", "value": octets * 10.0,
			"detail": "+%s o" % _fmt_short(octets * 10.0)},
		{"rarity": "legendaire", "title": "NOYAU",  "kind": "frags", "value": float(maxi(6, frags * 12)),
			"detail": "+%d Frag" % maxi(6, frags * 12)},
		{"rarity": "legendaire", "title": "ROOTKIT", "kind": "prod", "mult": 5.0, "dur": 60.0,
			"detail": "prod ×5 / 60s"},
		{"rarity": "legendaire", "title": "DÉLUGE",  "kind": "clic", "mult": 10.0, "dur": 30.0,
			"detail": "clic ×10 / 30s"},
	]


# Tire n récompenses DISTINCTES dans le pool, chaque tirage pondéré par la rareté
# (une commune sort ~8× plus souvent qu'une rare, ~33× plus qu'une légendaire).
func _draw_rewards(pool: Array, n: int) -> Array:
	var remaining := pool.duplicate()
	var picked: Array = []
	for _i in n:
		if remaining.is_empty():
			break
		var total := 0.0
		for r in remaining:
			total += float(REWARD_RARITY_WEIGHT.get(r.rarity, 1))
		var roll := randf() * total
		var acc := 0.0
		var chosen := 0
		for j in remaining.size():
			acc += float(REWARD_RARITY_WEIGHT.get(remaining[j].rarity, 1))
			if roll <= acc:
				chosen = j
				break
		picked.append(remaining[chosen])
		remaining.remove_at(chosen)
	return picked


# Ouvre la modale : remplit/colore les 3 cartes, met le jeu en pause (sans minuteur), et
# joue le son de "reveal" si au moins une carte rare/légendaire est tombée.
func _show_reward_choice(options: Array) -> void:
	_reward_options = options
	reward_choice_active = true
	reward_title.text = "FIREWALL BRISÉ (Nv %d) — CHOISIS TON BUTIN" % boss_level
	var has_rare := false
	for i in options.size():
		var opt: Dictionary = options[i]
		var rarity: String = opt.rarity
		if rarity != "commune":
			has_rare = true
		reward_cards[i].text = "[%d]  %s\n\n%s\n\n%s" % [i + 1, RARITY_LABEL[rarity], opt.title, opt.detail]
		_style_reward_card(reward_cards[i], RARITY_BG[rarity], RARITY_FG[rarity])
	reward_overlay.visible = true
	reward_overlay.modulate.a = 0.0
	create_tween().tween_property(reward_overlay, "modulate:a", 1.0, 0.12)
	reward_cards[0].grab_focus()
	if has_rare:
		_play_sfx("rare_reveal")


# Applique les styles DOS colorés d'une carte selon sa rareté (fond + texte).
func _style_reward_card(card: Button, bg: Color, fg: Color) -> void:
	var normal := _make_flat(bg, Color(0, 0, 0), 2, Vector2(4, 4))
	var hover := _make_flat(bg.lightened(0.18), Color(0, 0, 0), 2, Vector2(4, 4))
	var pressed := _make_flat(bg.darkened(0.18), Color(0, 0, 0), 2, Vector2(1, 1))
	for s in [normal, hover, pressed]:
		s.content_margin_left = 12.0
		s.content_margin_right = 12.0
		s.content_margin_top = 10.0
		s.content_margin_bottom = 10.0
	card.add_theme_stylebox_override("normal", normal)
	card.add_theme_stylebox_override("hover", hover)
	card.add_theme_stylebox_override("focus", hover)
	card.add_theme_stylebox_override("pressed", pressed)
	for c in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
		card.add_theme_color_override(c, fg)


# Le joueur choisit la carte idx : applique l'effet, joue le son gratifiant, ferme la modale.
func _pick_reward(idx: int) -> void:
	if not reward_choice_active or idx < 0 or idx >= _reward_options.size():
		return
	var opt: Dictionary = _reward_options[idx]
	reward_choice_active = false
	_reward_options = []
	reward_overlay.visible = false
	_apply_reward(opt)
	_play_sfx("reward")
	_flash(FX_GAIN, 0.35)
	_spawn_floating_text("%s  %s" % [opt.title, opt.detail], _center_of(terminal), FX_SPECIAL)
	_burst_particles(_center_of(terminal))
	_show_toast("BUTIN %s — %s" % [RARITY_LABEL[opt.rarity], opt.title], opt.detail, TOAST_WIN, 5.0)
	_set_status("Butin de boss : %s (%s)." % [opt.title, opt.detail])


func _apply_reward(opt: Dictionary) -> void:
	match opt.kind:
		"octets": _earn(opt.value)
		"frags":  _gain_fragments(int(opt.value))
		"prod":
			rwd_prod_mult = opt.mult
			rwd_prod_remaining = opt.dur
		"clic":
			click_buff_mult = opt.mult
			click_buff_remaining = opt.dur
		"trace":  trace = maxf(0.0, trace - opt.value)


func _fail_boss() -> void:
	boss_active = false
	boss_panel.visible = false
	boss_spawn_timer = randf_range(FIREWALL_SPAWN_MIN, FIREWALL_SPAWN_MAX)
	# Échec = traçage +60% (peut déclencher directement une intrusion si déjà haut).
	trace = minf(TRACE_MAX, trace + BOSS_FAIL_TRACE)
	_flash(FX_ALERT, 0.5)
	_play_sfx("boss_fail")
	_show_toast("FIREWALL NON BRISÉ", "Traçage +%d%%" % int(BOSS_FAIL_TRACE), TOAST_ALERT, 5.0)
	_set_status("Firewall non brisé ! Traçage +%d%%." % int(BOSS_FAIL_TRACE))
	if trace >= TRACE_MAX:
		_start_intrusion()


# ---------------------------------------------------------------------------
# RÉSEAU (carte de propagation)
# ---------------------------------------------------------------------------

# Régénère une carte fraîche (nouveau seed) + reconstruit l'affichage.
func _regenerate_network() -> void:
	network_seed = randi()
	_generate_network()
	_rebuild_network_view()


# Trouve la cellule de grille libre la plus proche de 'raw' (en unités de cellule).
# Recherche en spirale : garantit l'absence de chevauchement entre nœuds tout en
# restant déterministe (aucun hasard ici, juste de la géométrie).
func _network_snap_free_cell(raw: Vector2, occupied: Dictionary) -> Vector2i:
	var base := Vector2i(roundi(raw.x), roundi(raw.y))
	if not occupied.has(base):
		return base
	for radius in range(1, 6):
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				if maxi(absi(dx), absi(dy)) != radius:
					continue
				var c := base + Vector2i(dx, dy)
				if not occupied.has(c):
					return c
	return base   # Filet de sécurité (improbable avec un graphe de cette densité).


# Génère network_nodes + network_connections de façon DÉTERMINISTE depuis le seed
# (même seed => même carte, indispensable pour la sauvegarde de la run).
# Les positions sont accrochées à une grille (schéma "circuit imprimé", cohérent
# avec le reste de l'UI DOS) : pas de placement libre, uniquement des cellules.
func _generate_network() -> void:
	network_nodes.clear()
	network_connections.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = network_seed

	var occupied := { Vector2i.ZERO: true }
	# CORE à l'origine de la grille (déjà conquis).
	network_nodes.append({ "name": "CORE", "pos": Vector2.ZERO, "type": "root", "value": 0.0, "cost": 0.0, "owned": true })

	var prev_ring: Array = [0]        # indices des nœuds de l'anneau précédent
	for ring in range(1, NETWORK_RINGS + 1):
		var count := rng.randi_range(3, 5)
		var radius := ring * 1.55     # rayon en CELLULES (pas en pixels)
		var base_angle := rng.randf() * TAU
		var this_ring: Array = []
		for k in count:
			var angle := base_angle + k * (TAU / count) + rng.randf_range(-0.15, 0.15)
			var r := radius + rng.randf_range(-0.12, 0.12)
			var raw_cell := Vector2(cos(angle) * r, sin(angle) * r)
			var gc := _network_snap_free_cell(raw_cell, occupied)
			occupied[gc] = true
			var pos := Vector2(gc.x, gc.y) * NETWORK_CELL
			var t := _random_node_type(rng)
			var idx := network_nodes.size()
			network_nodes.append({
				"name": _type_short(t),
				"pos": pos,
				"type": t,
				"value": _node_value(t, ring),
				"cost": _node_cost(ring, rng),
				"owned": false,
			})
			this_ring.append(idx)
			# On relie au nœud le plus proche de l'anneau précédent (garantit l'accès).
			network_connections.append([idx, _nearest_index(pos, prev_ring)])
			# Parfois un 2e lien pour enrichir le graphe.
			if rng.randf() < 0.3 and prev_ring.size() > 1:
				var second := _nearest_index(pos, prev_ring, _nearest_index(pos, prev_ring))
				if second >= 0:
					network_connections.append([idx, second])
		prev_ring = this_ring


func _rebuild_network_view() -> void:
	for c in network_content.get_children():
		network_content.remove_child(c)
		c.queue_free()
	network_lines.clear()
	network_buttons.clear()
	network_labels.clear()
	# Liens (Line2D) d'abord -> dessinés SOUS les nœuds. Tracé à angle droit
	# (façon piste de circuit imprimé) : horizontal puis vertical, jamais en diagonale.
	for c in network_connections:
		var pa: Vector2 = network_nodes[c[0]].pos
		var pb: Vector2 = network_nodes[c[1]].pos
		var line := Line2D.new()
		line.width = 2.0
		line.antialiased = false
		line.joint_mode = Line2D.LINE_JOINT_SHARP
		line.begin_cap_mode = Line2D.LINE_CAP_BOX
		line.end_cap_mode = Line2D.LINE_CAP_BOX
		if pa.x == pb.x or pa.y == pb.y:
			line.points = PackedVector2Array([pa, pb])           # déjà alignés
		else:
			line.points = PackedVector2Array([pa, Vector2(pb.x, pa.y), pb])
		network_content.add_child(line)
		network_lines.append({ "a": c[0], "b": c[1], "line": line })
	# Chaque nœud = une pastille CARRÉE (bouton + icône) + un label de coût.
	var half := NETWORK_NODE_SIZE / 2.0
	for i in network_nodes.size():
		var n: Dictionary = network_nodes[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(NETWORK_NODE_SIZE, NETWORK_NODE_SIZE)
		btn.size = Vector2(NETWORK_NODE_SIZE, NETWORK_NODE_SIZE)
		btn.position = n.pos - Vector2(half, half)
		btn.focus_mode = Control.FOCUS_NONE
		btn.expand_icon = true
		btn.icon = load(_type_icon(n.type)) as Texture2D
		btn.pressed.connect(_on_network_node.bind(i))
		network_content.add_child(btn)
		network_buttons.append(btn)

		var lbl := Label.new()
		lbl.position = n.pos + Vector2(-32, half + 3)
		lbl.custom_minimum_size = Vector2(64, 0)
		lbl.size = Vector2(64, 14)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.add_theme_font_size_override("font_size", 12)
		network_content.add_child(lbl)
		network_labels.append(lbl)
	_network_fitted = false          # recadrage auto au prochain affichage


func _type_icon(t: String) -> String:
	match t:
		"prod":  return "res://assets/icons/processor.svg"
		"click": return "res://assets/icons/syringe.svg"
		"cost":  return "res://assets/icons/gears.svg"
		"data":  return "res://assets/icons/server-rack.svg"
		"frag":  return "res://assets/icons/fragment.svg"
	return "res://assets/icons/ai-logo.svg"


func _random_node_type(rng: RandomNumberGenerator) -> String:
	var r := rng.randf()
	if r < 0.40: return "prod"
	elif r < 0.60: return "click"
	elif r < 0.75: return "cost"
	elif r < 0.90: return "data"
	return "frag"


func _type_short(t: String) -> String:
	match t:
		"prod":  return "PROD"
		"click": return "CLIC"
		"cost":  return "COUT"
		"data":  return "DATA"
		"frag":  return "FRAG"
	return "CORE"


# Valeur du bonus selon type + profondeur (plus profond = plus fort).
func _node_value(t: String, ring: int) -> float:
	match t:
		"prod":  return 0.10 + 0.05 * ring
		"click": return 0.30 + 0.20 * ring
		"cost":  return 0.04 + 0.02 * ring
		"data":  return 150.0 + 120.0 * ring   # secondes de production (one-shot)
		"frag":  return float(ring)
	return 0.0


func _node_cost(ring: int, rng: RandomNumberGenerator) -> float:
	return ceil(NETWORK_COST_BASE * pow(NETWORK_COST_GROWTH, ring - 1) * rng.randf_range(0.85, 1.15))


# Indice (dans `indices`) du nœud le plus proche de `pos`, en excluant `exclude`.
func _nearest_index(pos: Vector2, indices: Array, exclude: int = -1) -> int:
	var best := -1
	var best_dist := INF
	for i in indices:
		if i == exclude:
			continue
		var d: float = network_nodes[i].pos.distance_to(pos)
		if d < best_dist:
			best_dist = d
			best = i
	return best


# --- Zoom / déplacement (pan) de la carte -----------------------------------

func _on_network_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_network_zoom(1.12, event.position)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_network_zoom(1.0 / 1.12, event.position)
	elif event is InputEventMouseMotion:
		# Glisser (bouton gauche maintenu) sur le vide = déplacer la carte.
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			network_content.position += event.relative


func _network_zoom(factor: float, pivot: Vector2) -> void:
	var old_s := network_content.scale.x
	var new_s := clampf(old_s * factor, NET_MIN_ZOOM, NET_MAX_ZOOM)
	if is_equal_approx(new_s, old_s):
		return
	var f := new_s / old_s
	# On zoome vers le curseur : le point sous la souris reste fixe.
	network_content.position = pivot - (pivot - network_content.position) * f
	network_content.scale = Vector2(new_s, new_s)


# Cadre toute la carte dans la vue (centrée), appelé une fois après (re)génération.
func _fit_network_view() -> void:
	if network_nodes.is_empty():
		return
	var minp: Vector2 = network_nodes[0].pos
	var maxp: Vector2 = network_nodes[0].pos
	for n in network_nodes:
		minp = Vector2(minf(minp.x, n.pos.x), minf(minp.y, n.pos.y))
		maxp = Vector2(maxf(maxp.x, n.pos.x), maxf(maxp.y, n.pos.y))
	var pad := 50.0
	var content_size := (maxp - minp) + Vector2(pad * 2, pad * 2)
	var view_size := network_view.size
	if view_size.x <= 1.0 or view_size.y <= 1.0:
		view_size = Vector2(460, 400)
	var s := clampf(minf(view_size.x / content_size.x, view_size.y / content_size.y), NET_MIN_ZOOM, NET_MAX_ZOOM)
	network_content.scale = Vector2(s, s)
	network_content.position = view_size * 0.5 - ((minp + maxp) * 0.5) * s


# Un nœud est piratable s'il n'est pas conquis mais touche un nœud conquis.
func _node_hackable(index: int) -> bool:
	if network_nodes[index].owned:
		return false
	for c in network_connections:
		if c[0] == index and network_nodes[c[1]].owned:
			return true
		if c[1] == index and network_nodes[c[0]].owned:
			return true
	return false


func _on_network_node(index: int) -> void:
	var n: Dictionary = network_nodes[index]
	if n.owned or not _node_hackable(index):
		return
	if data < n.cost:
		_set_status("Pas assez de Données pour ce nœud (%d o)." % int(n.cost))
		return
	data -= n.cost
	n.owned = true
	_apply_network_node(n)
	_play_sfx("buy", -3.0, _buy_pitch_step(_network_owned_count()))
	_flash(FX_GAIN, 0.3)
	_show_toast("NŒUD PIRATÉ", _network_node_desc(n), TOAST_WIN, 5.0)
	_update_display()


# Effet immédiat pour les nœuds "one-shot" (les autres sont lus en continu).
func _apply_network_node(n: Dictionary) -> void:
	match n.type:
		"data":
			_earn(maxf(production_per_second() * n.value, 5000.0))
		"frag":
			_gain_fragments(int(n.value))


func _network_node_desc(n: Dictionary) -> String:
	match n.type:
		"prod":  return "Relais : +%d%% production (permanent)" % int(n.value * 100)
		"click": return "Nœud de calcul : +%d%% par frappe (permanent)" % int(n.value * 100)
		"cost":  return "Optimiseur : -%d%% coût des générateurs (permanent)" % int(n.value * 100)
		"data":  return "Cache : ~%d s de production récupérées" % int(n.value)
		"frag":  return "Coffre : +%d Fragment(s) d'IA" % int(n.value)
		"root":  return "Cœur du réseau (point de départ)"
	return ""


# Bonus PERMANENTS agrégés depuis les nœuds conquis.
func network_prod_mult() -> float:
	var m: float = 1.0
	for n in network_nodes:
		if n.owned and n.type == "prod":
			m += n.value
	return m


func network_click_mult() -> float:
	var m: float = 1.0
	for n in network_nodes:
		if n.owned and n.type == "click":
			m += n.value
	return m


func network_cost_factor() -> float:
	var f: float = 1.0
	for n in network_nodes:
		if n.owned and n.type == "cost":
			f *= (1.0 - n.value)
	return maxf(f, 0.2)


func _update_network() -> void:
	# Couleur des liens (pistes de circuit) selon l'état (conquis / frontière / inconnu).
	for entry in network_lines:
		var oa: bool = network_nodes[entry.a].owned
		var ob: bool = network_nodes[entry.b].owned
		var col: Color
		if oa and ob:
			col = Color(0.15, 0.15, 0.15, 0.9)       # piste alimentée (conquise des deux côtés)
		elif oa or ob:
			col = Color(0, 0.667, 0.667, 1)          # frontière piratable -> cyan (comme un bouton actif)
		else:
			col = Color(0.55, 0.55, 0.55, 0.5)       # piste non alimentée, à peine visible
		entry.line.default_color = col
	# Boutons de nœuds.
	for i in network_nodes.size():
		var n: Dictionary = network_nodes[i]
		var btn: Button = network_buttons[i]
		var lbl: Label = network_labels[i]
		var style: StyleBoxFlat
		var icon_col: Color
		var lbl_text := ""
		if n.owned:
			style = _node_style_owned
			icon_col = Color(0, 0, 0.5)              # bleu DOS, comme les icônes de générateurs
			btn.modulate = Color(1, 1, 1)
			btn.tooltip_text = _network_node_desc(n)
		elif _node_hackable(i):
			style = _node_style_hack
			icon_col = Color(0.667, 0, 0)             # rouge, comme le texte des boutons cyan
			btn.modulate = Color(1, 1, 1) if data >= n.cost else Color(0.6, 0.6, 0.6)
			lbl_text = "%s o" % _fmt_short(n.cost)
			btn.tooltip_text = _network_node_desc(n) + "   —   coût %d o" % int(n.cost)
		else:
			style = _node_style_locked
			icon_col = Color(0.35, 0.35, 0.35)
			btn.modulate = Color(1, 1, 1)
			btn.tooltip_text = "Nœud hors de portée"
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)
		btn.add_theme_color_override("icon_normal_color", icon_col)
		btn.add_theme_color_override("icon_hover_color", icon_col)
		btn.add_theme_color_override("icon_pressed_color", icon_col)
		lbl.text = lbl_text
		lbl.add_theme_color_override("font_color", Color(0, 0, 0))


# Formate un grand nombre en court (500, 1.5K, 40K, 2.3M).
func _fmt_short(v: float) -> String:
	if v >= 1000000.0:
		return "%.1fM" % (v / 1000000.0)
	if v >= 1000.0:
		return "%.1fK" % (v / 1000.0)
	return "%d" % int(v)


# --- Failles zero-day --------------------------------------------------------

# Affiche/masque le bouton de faille SANS le retirer de la mise en page : il garde
# toujours sa place (transparent + désactivé quand aucune faille n'est active), pour que
# l'apparition d'une faille ne fasse plus rétrécir le terminal en plein combat de boss.
func _set_zeroday_shown(shown: bool) -> void:
	zeroday_button.modulate.a = 1.0 if shown else 0.0
	zeroday_button.disabled = not shown


func _spawn_zeroday() -> void:
	zeroday_window_remaining = ZERODAY_WINDOW
	_set_zeroday_shown(true)
	_set_status("Faille zero-day détectée ! Exploite-la vite.")


func _on_zeroday_pressed() -> void:
	if zeroday_window_remaining <= 0.0:
		return
	zeroday_window_remaining = 0.0
	_set_zeroday_shown(false)
	zeroday_buff_remaining = ZERODAY_BUFF_DURATION
	zeroday_spawn_timer = randf_range(ZERODAY_SPAWN_MIN, ZERODAY_SPAWN_MAX)
	_flash(FX_SPECIAL, 0.4)   # flash ambre : boost faille
	_spawn_floating_text("FAILLE !", _center_of(zeroday_button), FX_SPECIAL)
	_set_status("Faille exploitée : production x%d pendant %d s !" % [int(ZERODAY_MULT), int(ZERODAY_BUFF_DURATION)])
	_update_display()


# ---------------------------------------------------------------------------

func _on_prestige_pressed() -> void:
	if pending_fragments() < 1:
		_set_status("Pas encore assez accumulé pour compiler.")
		return
	var gained := pending_fragments()
	var msg := "Compiler l'IA remet à zéro tes [color=#000080]Données[/color] et tes générateurs, mais te rapporte [color=#000080]+%d Fragment(s) d'IA[/color] permanents.\n\nConfirmer la compilation ?" % gained
	_show_confirm("Compilation de l'IA", msg, "Compiler", false, _do_prestige)


func _do_prestige() -> void:
	var gained := pending_fragments()
	if gained < 1:
		return
	_gain_fragments(gained)
	prestige_count += 1
	# P1 : le tout premier Fragment révèle la boutique d'Augmentations.
	if not unlock_augment:
		unlock_augment = true
		_apply_gating()
		_show_toast("NOUVELLE SECTION", "Augmentations débloquées — dépense tes Fragments d'IA (onglet Augmentations).", TOAST_FRAG, 5.0)
	# Reset de la RUN uniquement. Les items (payés en fragments) restent.
	data = 0.0
	run_earned = 0.0
	for gen in generators:
		gen.count = 0
	# On repart d'une run "propre" côté risque aussi.
	trace = 0.0
	op_cooldown_remaining = 0.0
	malus_remaining = 0.0
	combo = 0
	intrusion_active = false
	boss_active = false
	boss_spawn_timer = randf_range(FIREWALL_SPAWN_MIN, FIREWALL_SPAWN_MAX)
	_regenerate_network()               # roguelike : une nouvelle carte à chaque prestige
	_pick_new_command()
	save_game()
	_play_sfx("prestige")
	_set_status("IA compilée : +%d fragment(s). Production x%.2f" % [gained, prestige_multiplier()])
	_update_display()


# ---------------------------------------------------------------------------
# SAUVEGARDE / CHARGEMENT
# ---------------------------------------------------------------------------

# Passe à true si on détecte au chargement une sauvegarde d'une build PLUS RÉCENTE : on cesse
# alors d'écrire pour ne pas écraser (et corrompre) cette sauvegarde avec notre état par défaut.
var _save_blocked: bool = false


func save_game() -> void:
	if _save_blocked:
		return
	var counts := {}
	for gen in generators:
		counts[gen.name] = gen.count
	var item_levels := {}
	for it in items:
		item_levels[it.id] = it.level
	var daemon_levels := {}
	for d in daemons:
		daemon_levels[d.id] = d.level
	var network_owned := []
	for i in network_nodes.size():
		if network_nodes[i].owned:
			network_owned.append(i)
	var unlocked_state := {}
	for f in UNLOCK_FEATURES:
		unlocked_state[f] = _is_unlocked(f)

	var payload := {
		"version": SAVE_VERSION,
		"data": data,
		"run_earned": run_earned,
		"fragments": fragments,
		"generators": counts,
		"items": item_levels,
		"daemons": daemon_levels,
		"network_seed": network_seed,
		"network_owned": network_owned,
		"total_fragments_earned": total_fragments_earned,
		"has_won": has_won,
		"prestige_count": prestige_count,
		"play_time": play_time,
		"best_combo": best_combo,
		"total_commands_typed": total_commands_typed,
		"total_rare_typed": total_rare_typed,
		"best_run_earned": best_run_earned,
		"unlocked": unlocked_state,
		"unlocks_owned": _owned_unlock_ids(),
		"muted": muted,
		"sfx_volume": sfx_volume,
		"timestamp": Time.get_unix_time_from_system(),
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		_set_status("Échec de la sauvegarde !")
		return
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	_set_status("Sauvegardé à %s" % Time.get_time_string_from_system())


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var text := file.get_as_text()
	file.close()

	var payload = JSON.parse_string(text)
	if typeof(payload) != TYPE_DICTIONARY:
		_set_status("Sauvegarde illisible, ignorée.")
		return

	# Garde de compatibilité : une sauvegarde écrite par une build PLUS RÉCENTE (version
	# supérieure) peut contenir des champs/formats qu'on ne sait pas interpréter. On ne la charge
	# pas ET on bloque l'écriture pour ne pas l'écraser (voir _save_blocked). Les versions
	# antérieures ou égales restent gérées par les valeurs par défaut de chaque .get().
	var saved_version := int(payload.get("version", 0))
	if saved_version > SAVE_VERSION:
		_save_blocked = true
		_set_status("Sauvegarde d'une version plus récente (v%d) — non chargée (protégée)." % saved_version)
		return

	data = float(payload.get("data", 0.0))
	run_earned = float(payload.get("run_earned", 0.0))
	fragments = int(payload.get("fragments", 0))
	total_fragments_earned = int(payload.get("total_fragments_earned", fragments))
	has_won = bool(payload.get("has_won", false))
	prestige_count = int(payload.get("prestige_count", 0))
	play_time = float(payload.get("play_time", 0.0))
	best_combo = int(payload.get("best_combo", 0))
	total_commands_typed = int(payload.get("total_commands_typed", 0))
	total_rare_typed = int(payload.get("total_rare_typed", 0))
	best_run_earned = float(payload.get("best_run_earned", 0.0))
	muted = bool(payload.get("muted", false))
	sfx_volume = float(payload.get("sfx_volume", 0.8))

	if payload.has("unlocked"):
		var saved_unlocked: Dictionary = payload.get("unlocked", {})
		for f in UNLOCK_FEATURES:
			_set_unlocked(f, bool(saved_unlocked.get(f, false)))
		var owned_ids: Array = payload.get("unlocks_owned", [])
		for u in unlocks:
			u.owned = u.id in owned_ids
	else:
		# Sauvegarde d'avant le système de déblocage : on débloque tout (pas de régression).
		for f in UNLOCK_FEATURES:
			_set_unlocked(f, true)
		for u in unlocks:
			u.owned = true

	var counts: Dictionary = payload.get("generators", {})
	for gen in generators:
		gen.count = int(counts.get(gen.name, 0))

	var item_levels: Dictionary = payload.get("items", {})
	for it in items:
		it.level = int(item_levels.get(it.id, 0))

	var daemon_levels: Dictionary = payload.get("daemons", {})
	for d in daemons:
		d.level = int(daemon_levels.get(d.id, 0))

	# On régénère la carte de la run à partir du seed sauvegardé, puis on restaure
	# les nœuds déjà conquis (indices valides car la génération est déterministe).
	network_seed = int(payload.get("network_seed", network_seed))
	_generate_network()
	var network_owned: Array = payload.get("network_owned", [])
	for idx in network_owned:
		var ii := int(idx)
		if ii >= 0 and ii < network_nodes.size():
			network_nodes[ii].owned = true
	_rebuild_network_view()


func _on_save_pressed() -> void:
	save_game()


func _on_reset_pressed() -> void:
	# Action destructive : on demande confirmation via le modal (focus par défaut sur Annuler).
	var msg := "[color=#aa0000]ATTENTION.[/color] Cette action efface [color=#aa0000]TOUTE ta progression[/color] — Données, Fragments, générateurs, augmentations, réseau et déblocages.\n\nElle est [color=#aa0000]IRRÉVERSIBLE.[/color]"
	_show_confirm("Réinitialiser la partie", msg, "Tout effacer", true, _do_reset)


func _do_reset() -> void:
	# Reset TOTAL (Données, générateurs, fragments ET items).
	data = 0.0
	run_earned = 0.0
	fragments = 0
	for gen in generators:
		gen.count = 0
	for it in items:
		it.level = 0
	trace = 0.0
	op_cooldown_remaining = 0.0
	malus_remaining = 0.0
	zeroday_buff_remaining = 0.0
	click_buff_remaining = 0.0
	rwd_prod_remaining = 0.0
	zeroday_window_remaining = 0.0
	_set_zeroday_shown(false)
	zeroday_spawn_timer = randf_range(ZERODAY_SPAWN_MIN, ZERODAY_SPAWN_MAX)
	combo = 0
	intrusion_active = false
	final_command_active = false
	total_fragments_earned = 0
	has_won = false
	prestige_count = 0
	play_time = 0.0
	best_combo = 0
	total_commands_typed = 0
	total_rare_typed = 0
	best_run_earned = 0.0
	for f in UNLOCK_FEATURES:
		_set_unlocked(f, false)
	for u in unlocks:
		u.owned = false
	event_active = false
	event_id = ""
	event_spawn_timer = randf_range(EVENT_SPAWN_MIN, EVENT_SPAWN_MAX)
	_apply_gating()
	boss_active = false
	boss_level = 0
	boss_spawn_timer = randf_range(FIREWALL_SPAWN_MIN, FIREWALL_SPAWN_MAX)
	for d in daemons:
		d.level = 0
		d.cd_remaining = 0.0
		d.active_remaining = 0.0
	_regenerate_network()
	_pick_new_command()
	var dir := DirAccess.open("user://")
	if dir != null and dir.file_exists("save.json"):
		dir.remove("save.json")
	_set_status("Partie réinitialisée.")
	_update_display()


func _set_status(msg: String) -> void:
	status_label.text = msg


# ---------------------------------------------------------------------------
# EFFETS VISUELS ("juice") — tout est asset-free, à base de Tween/particules.
# ---------------------------------------------------------------------------

# Fait apparaître un texte qui monte et s'efface (ex : "+42 o") à une position.
func _spawn_floating_text(text: String, at_pos: Vector2, color: Color) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.z_index = 10
	fx_layer.add_child(lbl)
	# Position (avec un léger décalage aléatoire pour éviter la superposition).
	lbl.position = at_pos + Vector2(randf_range(-14.0, 14.0), -10.0)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(lbl, "position:y", lbl.position.y - 64.0, 0.8) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.8)
	tween.set_parallel(false)
	tween.tween_callback(lbl.queue_free)   # se nettoie tout seul à la fin


# Petit "pop" d'agrandissement, typiquement sur le compteur de Données.
func _pop(node: Control) -> void:
	if _pop_tween != null and _pop_tween.is_valid():
		_pop_tween.kill()          # on annule le pop précédent pour éviter les conflits
	node.pivot_offset = node.size / 2.0   # pivot au centre pour agrandir "sur place"
	node.scale = Vector2.ONE
	_pop_tween = create_tween()
	_pop_tween.tween_property(node, "scale", Vector2(1.18, 1.18), 0.08) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_pop_tween.tween_property(node, "scale", Vector2.ONE, 0.14) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


# Flash coloré plein écran qui s'estompe (feedback d'événement fort).
func _flash(color: Color, strength: float = 0.35) -> void:
	flash_rect.color = Color(color.r, color.g, color.b, strength)
	create_tween().tween_property(flash_rect, "color:a", 0.0, 0.5)


# Secousse par rotation (transform indépendant du layout, donc sans conflit).
func _shake(node: Control) -> void:
	node.pivot_offset = node.size / 2.0
	var tween := create_tween()
	tween.tween_property(node, "rotation", deg_to_rad(2.5), 0.04)
	tween.tween_property(node, "rotation", deg_to_rad(-2.5), 0.08)
	tween.tween_property(node, "rotation", 0.0, 0.05)


# Jet de particules ponctuel à une position donnée.
func _burst_particles(at_pos: Vector2) -> void:
	click_particles.global_position = at_pos
	click_particles.restart()   # relance l'émission (one_shot)


# Centre global d'un contrôle (pratique pour viser une position d'effet).
func _center_of(control: Control) -> Vector2:
	return control.global_position + control.size / 2.0


# ---------------------------------------------------------------------------
# AFFICHAGE
# ---------------------------------------------------------------------------

# Rafraîchissement de l'UI, appelé chaque frame (et à la demande après une action).
# Simple ORCHESTRATEUR : chaque sous-fonction est responsable d'une zone de l'écran.
# Les zones toujours visibles sont mises à jour à chaque appel ; le contenu des onglets
# (lignes, carte réseau) n'est rafraîchi que pour l'onglet affiché (voir _update_visible_tab).
func _update_display() -> void:
	_update_resource_labels()
	_update_typing_ui()
	_update_prestige_ui()
	_update_ops_ui()
	_update_trace_bar()
	# Bouton de faille (compte à rebours pendant qu'il est visible).
	if zeroday_window_remaining > 0.0:
		zeroday_button.text = "EXPLOITER LA FAILLE (%d s)" % int(ceil(zeroday_window_remaining))
	_update_effects_status()
	_update_boss_ui()
	_update_daemon_buttons()
	_update_visible_tab()


# Bande ressources (haut) + horloge de la barre de statut.
func _update_resource_labels() -> void:
	data_label.text = "%s o" % _fmt_short(data)
	prod_label.text = "%s o/s" % _fmt_short(production_per_second())
	fragment_label.text = "%d" % fragments
	var t := Time.get_time_dict_from_system()
	clock_label.text = "%02d:%02d:%02d" % [t.hour, t.minute, t.second]


# Ligne de prestige (bonus / accumulé / seuil), libellé d'objectif, bouton Compiler.
func _update_prestige_ui() -> void:
	var pending := pending_fragments()
	var next_threshold := fragments_threshold(pending + 1)
	var remaining := maxf(0.0, next_threshold - run_earned)
	prestige_info.text = "+%d%% prod   |   accumulé %d o   |   prochain fragment dans %d o" % [int(fragments * FRAGMENT_BONUS * 100), int(run_earned), int(remaining)]

	# Objectif de fin.
	if has_won:
		objective_label.text = "OBJECTIF ATTEINT — IA ÉVEILLÉE (mode libre)"
		objective_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	elif total_fragments_earned >= AWAKEN_TARGET:
		objective_label.text = "IA PRÊTE — tape la COMMANDE D'ÉVEIL dans le terminal !"
		objective_label.add_theme_color_override("font_color", Color(1, 0.81, 0.25))
	else:
		objective_label.text = "OBJECTIF — Éveil de l'IA : %d / %d Fragments cumulés" % [total_fragments_earned, AWAKEN_TARGET]
		objective_label.add_theme_color_override("font_color", Color(0.25, 0.25, 0.25))

	# Bouton explicite, même quand on ne peut pas encore compiler.
	if pending >= 1:
		prestige_button.text = "COMPILER L'IA (+%d fragment%s)" % [pending, "s" if pending > 1 else ""]
	else:
		prestige_button.text = "COMPILER L'IA — accumule encore %d o" % int(remaining)
	prestige_button.disabled = pending < 1


# Bouton PIRATER : le cooldown se lit directement dessus, façon jauge (fond gris = vide,
# couche cyan OpFill qui se remplit de gauche à droite, décompte OpLabel par-dessus). Une
# fois rechargé, jauge + libellé masqués et le bouton redevient cliquable.
func _update_ops_ui() -> void:
	if op_cooldown_remaining > 0.0:
		var recharge_txt := "Rechargement... %d s" % int(ceil(op_cooldown_remaining))
		op_button.disabled = true
		# Texte gardé (mais invisible via font désactivé transparente) UNIQUEMENT pour conserver
		# la hauteur du bouton : un bouton vide se réduirait à ses marges.
		op_button.text = recharge_txt
		var ratio: float = clampf((OP_COOLDOWN - op_cooldown_remaining) / OP_COOLDOWN, 0.0, 1.0)
		op_fill.visible = true
		op_fill.offset_right = op_button.size.x * ratio
		op_label.visible = true
		op_label.text = recharge_txt
	else:
		op_button.disabled = false
		op_fill.visible = false
		op_label.visible = false
		# On montre le gain potentiel (même formule que la récompense réelle).
		var potential := int(maxf(production_per_second() * OP_REWARD_SECONDS, click_value() * OP_MIN_REWARD_CLICKS))
		op_button.text = "PIRATER LA CIBLE : +%d o  (%d%% de réussite)" % [potential, int(OP_SUCCESS_CHANCE * 100)]


# Ligne d'état des effets temporaires actifs (faille, surrégime, frappe, tracé, événement).
func _update_effects_status() -> void:
	var status_txt := ""
	if zeroday_buff_remaining > 0.0:
		status_txt += "FAILLE ACTIVE : prod x%d (%d s)" % [int(ZERODAY_MULT), int(ceil(zeroday_buff_remaining))]
	if rwd_prod_remaining > 0.0:
		if status_txt != "":
			status_txt += "     "
		status_txt += "SURRÉGIME : prod x%d (%d s)" % [int(rwd_prod_mult), int(ceil(rwd_prod_remaining))]
	if click_buff_remaining > 0.0:
		if status_txt != "":
			status_txt += "     "
		status_txt += "FRAPPE : clic x%d (%d s)" % [int(click_buff_mult), int(ceil(click_buff_remaining))]
	if malus_remaining > 0.0:
		if status_txt != "":
			status_txt += "     "
		status_txt += "TRACÉ : prod /%d (%d s)" % [int(1.0 / MALUS_MULT), int(ceil(malus_remaining))]
	if event_active:
		if status_txt != "":
			status_txt += "     "
		status_txt += "%s (%d s)" % ["INSTABILITÉ" if event_id == "instabilite" else "SURCHARGE", int(ceil(event_timer))]
	event_status.text = status_txt if status_txt != "" else " "


# Panneau de vie du firewall (visible seulement pendant un combat).
func _update_boss_ui() -> void:
	boss_panel.visible = boss_active
	if boss_active:
		boss_hp_bar.max_value = boss_max_hp
		boss_hp_bar.value = boss_hp
		boss_info.text = "PV %d/%d   —   %d s" % [int(ceil(boss_hp)), int(boss_max_hp), int(ceil(boss_timer))]


# Boutons daemons de la barre de gauche (TOUJOURS visibles) : nom + état (actif / recharge).
func _update_daemon_buttons() -> void:
	for i in daemons.size():
		var d: Dictionary = daemons[i]
		var btn := daemon_buttons[i]
		if d.get("pay_per_use", false):
			# GHOST : toujours dispo, grisé si on n'a pas les Fragments.
			var use_cost := int(d.use_cost)
			btn.visible = true
			btn.text = "%s (%d Frag)" % [d.name, use_cost]
			btn.disabled = fragments < use_cost
		else:
			btn.visible = d.level >= 1          # la barre ne montre que les daemons débloqués
			if d.level >= 1:
				if d.active_remaining > 0.0:
					btn.text = "%s [%ds]" % [d.name, int(ceil(d.active_remaining))]
					btn.disabled = true
				elif d.cd_remaining > 0.0:
					btn.text = "%s %ds" % [d.name, int(ceil(d.cd_remaining))]
					btn.disabled = true
				else:
					btn.text = d.name
					btn.disabled = false


# Rafraîchit UNIQUEMENT le contenu de l'onglet affiché (les autres seront mis à jour à leur
# réouverture, via _process ou le signal tab_changed). Onglets : 0=Générateurs 1=Augmentations
# 2=Programmes 3=Réseau. C'est le plus coûteux, d'où le gating sur la visibilité.
func _update_visible_tab() -> void:
	match tabs.current_tab:
		0:
			for i in generators.size():
				var gen: Dictionary = generators[i]
				var cost := cost_of(gen)
				gen_rows[i].refresh(gen.name, gen.count, _fmt_short(gen.production), _fmt_short(cost), data >= cost)
		1:
			for i in unlocks.size():
				_refresh_unlock_row(i)
			for i in items.size():
				_refresh_item_row(i)
		2:
			for i in daemons.size():
				_refresh_daemon_row(i)
		3:
			_update_network()
			# Recadrage auto dès que la vue a une taille réelle (après la 1re mise en page).
			if not _network_fitted and network_view.size.x > 1.0:
				_fit_network_view()
				_network_fitted = true


func _refresh_item_row(i: int) -> void:
	var it: Dictionary = items[i]
	var title := "[%s] %s  (Nv %d/%d)" % [it.category, it.name, it.level, it.max_level]
	var desc := _item_desc(it)
	var maxed: bool = it.level >= it.max_level
	var cost := item_cost(it)
	var button_text := "MAX" if maxed else "Améliorer — %d Frag" % cost
	var buyable := (not maxed) and fragments >= cost
	item_rows[i].refresh(title, desc, button_text, buyable)


func _item_desc(it: Dictionary) -> String:
	match it.effect:
		"prod_mult":  return "Production globale +%d%% par niveau" % int(it.value * 100)
		"click_mult": return "Gain au clic +%d%% par niveau" % int(it.value * 100)
		"cost_reduc": return "Coût des générateurs -%d%% par niveau" % int(it.value * 100)
		"autoclick":  return "+%.0f clic auto / seconde par niveau" % it.value
		"synergy":    return "+%d%% production par type de générateur possédé, par niveau" % int(it.value * 100)
	return ""
