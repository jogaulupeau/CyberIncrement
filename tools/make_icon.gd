extends SceneTree
## Outil hors-jeu : génère icon.ico (œil cyber cyan sur fond sombre), MULTI-TAILLES.
## Lancé via : godot --headless --path . --script res://tools/make_icon.gd
## Godot rasterise le SVG ; on écrit le conteneur .ico à la main (plusieurs images
## PNG : 16/32/48/64/128/256) pour un rendu net à toutes les tailles Windows.

func _initialize() -> void:
	var sizes: Array[int] = [16, 32, 48, 64, 128, 256]
	var tex := load("res://assets/icons/ai-logo.svg") as Texture2D
	var base := tex.get_image()
	base.convert(Image.FORMAT_RGBA8)
	var tint := Color(0.0, 0.9, 0.82)

	var pngs: Array = []
	for s in sizes:
		var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.03, 0.06, 0.08, 1.0))       # fond cyber sombre
		var inner := int(round(s * 0.78))
		var eye := base.duplicate() as Image
		eye.resize(inner, inner, Image.INTERPOLATE_LANCZOS)
		for y in inner:
			for x in inner:
				var a := eye.get_pixel(x, y).a
				eye.set_pixel(x, y, Color(tint.r, tint.g, tint.b, a))
		var off := (s - inner) / 2
		img.blend_rect(eye, Rect2i(0, 0, inner, inner), Vector2i(off, off))
		if s == 256:
			img.save_png("res://icon.png")   # icône de FENÊTRE (barre des tâches en jeu)
		pngs.append(img.save_png_to_buffer())

	var n := sizes.size()
	var f := FileAccess.open("res://icon.ico", FileAccess.WRITE)
	f.store_16(0)            # réservé
	f.store_16(1)            # type = icône
	f.store_16(n)            # nombre d'images
	var offset := 6 + 16 * n
	for i in n:
		var s: int = sizes[i]
		f.store_8(0 if s >= 256 else s)   # largeur (0 = 256)
		f.store_8(0 if s >= 256 else s)   # hauteur (0 = 256)
		f.store_8(0)                       # palette
		f.store_8(0)                       # réservé
		f.store_16(1)                      # plans
		f.store_16(32)                     # bits/pixel
		f.store_32(pngs[i].size())         # taille des données
		f.store_32(offset)                 # décalage
		offset += pngs[i].size()
	for i in n:
		f.store_buffer(pngs[i])
	f.close()
	print("ICON_DONE images=", n)
	quit()
