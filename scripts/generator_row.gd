extends PanelContainer
## Une LIGNE d'interface réutilisable, pour UN générateur.
##
## Rôle : afficher (nom, quantité, prod, coût) en COLONNES alignées et proposer un
## bouton "Acheter". Elle ne connaît PAS les règles du jeu (combien de Données on a, etc.).
## Quand on clique "Acheter", elle se contente d'ÉMETTRE UN SIGNAL ;
## c'est main.gd (le cerveau) qui décidera si l'achat est possible.
## Ce découpage "affichage ≠ logique" est une bonne habitude d'architecture.

class_name GeneratorRow

# Signal personnalisé : notre propre événement. main.gd s'y abonnera.
# On transmet l'index du générateur concerné, pour que le cerveau sache lequel.
signal buy_requested(index: int)

var index: int = -1   # position de ce générateur dans la liste de main.gd

@onready var icon_rect: TextureRect = %IconRect
@onready var name_label: Label = %NameLabel
@onready var mult_label: Label = %MultLabel
@onready var bonus_label: Label = %BonusLabel
@onready var buy_button: Button = %BuyButton


# Appelée par main.gd juste après avoir ajouté la ligne à la scène.
func setup(idx: int) -> void:
	index = idx
	buy_button.pressed.connect(_on_buy_pressed)
	# Pas de focus clavier : sinon le style "focus" reste affiché par-dessus
	# l'état désactivé après un clic (le bouton a l'air "actif" alors qu'il ne l'est plus).
	buy_button.focus_mode = Control.FOCUS_NONE


# Icône teintée (les SVG sont blancs, donc modulate les colore en néon).
func set_icon(texture: Texture2D, tint: Color) -> void:
	icon_rect.texture = texture
	icon_rect.modulate = tint


func _on_buy_pressed() -> void:
	buy_requested.emit(index)   # "quelqu'un veut acheter le générateur n°index"


# main.gd prépare les chaînes (déjà formatées) ; la ligne les répartit dans ses colonnes.
# Le prix est intégré au bouton d'achat (plus lisible qu'une colonne "coût" isolée).
func refresh(gen_name: String, count: int, bonus_str: String, cost_str: String, affordable: bool) -> void:
	name_label.text = gen_name
	mult_label.text = "x%d" % count
	bonus_label.text = "+%s o/s" % bonus_str
	buy_button.text = "Acheter — %s o" % cost_str
	buy_button.disabled = not affordable
