extends PanelContainer
## Une LIGNE d'interface réutilisable, pour UN générateur.
##
## Rôle : afficher (nom, quantité, prod, coût) et proposer un bouton "Acheter".
## Elle ne connaît PAS les règles du jeu (combien de Données on a, etc.).
## Quand on clique "Acheter", elle se contente d'ÉMETTRE UN SIGNAL ;
## c'est main.gd (le cerveau) qui décidera si l'achat est possible.
## Ce découpage "affichage ≠ logique" est une bonne habitude d'architecture.

class_name GeneratorRow

# Signal personnalisé : notre propre événement. main.gd s'y abonnera.
# On transmet l'index du générateur concerné, pour que le cerveau sache lequel.
signal buy_requested(index: int)

var index: int = -1   # position de ce générateur dans la liste de main.gd

@onready var icon_rect: TextureRect = %IconRect
@onready var info_label: Label = %InfoLabel
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


# main.gd appelle ceci pour rafraîchir l'affichage de la ligne.
func refresh(gen_name: String, count: int, production: float, cost: float, affordable: bool) -> void:
	info_label.text = "%s  (x%d)   —   +%.0f o/s" % [gen_name, count, production]
	buy_button.text = "Acheter — %d o" % cost
	buy_button.disabled = not affordable
