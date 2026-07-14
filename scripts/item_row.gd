extends PanelContainer
## Une LIGNE d'interface réutilisable pour UN item de la boutique.
## Même principe que GeneratorRow : elle affiche et émet un signal d'achat,
## mais ne connaît pas les règles (c'est main.gd qui décide).

class_name ItemRow

signal buy_requested(index: int)

var index: int = -1

@onready var icon_rect: TextureRect = %IconRect
@onready var title_label: Label = %TitleLabel
@onready var desc_label: Label = %DescLabel
@onready var buy_button: Button = %BuyButton


func setup(idx: int) -> void:
	index = idx
	buy_button.pressed.connect(_on_buy_pressed)


# Icône teintée (les SVG sont blancs, donc modulate les colore en néon).
func set_icon(texture: Texture2D, tint: Color) -> void:
	icon_rect.texture = texture
	icon_rect.modulate = tint


func _on_buy_pressed() -> void:
	buy_requested.emit(index)


# main.gd prépare les textes ; la ligne se contente de les afficher.
func refresh(title: String, desc: String, button_text: String, buyable: bool) -> void:
	title_label.text = title
	desc_label.text = desc
	buy_button.text = button_text
	buy_button.disabled = not buyable
