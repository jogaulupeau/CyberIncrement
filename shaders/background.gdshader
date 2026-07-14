shader_type canvas_item;
// Fond animé "cyber" : grille défilante + pluie de code + scanlines + vignette.
// Un shader canvas_item s'exécute pour CHAQUE pixel du ColorRect, sur le GPU.
// TIME (temps écoulé) et FRAGCOORD (coordonnées en pixels) sont fournis par Godot.

// Les "uniform" sont des réglages exposés dans l'inspecteur (modifiables à chaud).
uniform vec4 bg_color : source_color = vec4(0.035, 0.045, 0.06, 1.0);
uniform vec4 grid_color : source_color = vec4(0.0, 0.9, 0.82, 1.0);
uniform vec4 rain_color : source_color = vec4(0.2, 1.0, 0.6, 1.0);
uniform float cell_size = 44.0;       // taille d'une case de grille (pixels)
uniform float grid_speed = 16.0;      // vitesse de défilement de la grille
uniform float line_width = 1.3;       // épaisseur des lignes
uniform float grid_intensity = 0.16;
uniform float rain_intensity = 0.22;
uniform float scan_intensity = 0.05;

// Petit générateur pseudo-aléatoire déterministe (par colonne).
float hash(float x) {
	return fract(sin(x * 127.1) * 43758.5453);
}

void fragment() {
	vec2 px = FRAGCOORD.xy;

	// --- Grille qui défile vers le bas ---
	vec2 scrolled = px + vec2(0.0, TIME * grid_speed);
	vec2 cell = mod(scrolled, cell_size);
	float dist = min(min(cell.x, cell_size - cell.x), min(cell.y, cell_size - cell.y));
	float grid = (1.0 - smoothstep(0.0, line_width, dist)) * grid_intensity;

	// --- Pluie numérique (têtes lumineuses qui tombent, traînée derrière) ---
	float col = floor(px.x / cell_size);
	float speed = mix(60.0, 170.0, hash(col));       // chaque colonne a sa vitesse
	float head = mod(TIME * speed + hash(col + 7.0) * 1000.0, 720.0);
	float d = head - px.y;                             // distance au-dessus de la tête
	float trail = clamp(1.0 - d / 170.0, 0.0, 1.0) * step(0.0, d);
	trail *= step(0.62, hash(col + 3.0));             // ~38% des colonnes seulement
	float rain = trail * rain_intensity;

	// --- Scanlines (fines lignes sombres horizontales) ---
	float scanline = (sin(px.y * 3.14159) * 0.5 + 0.5) * scan_intensity;

	// --- Composition ---
	vec3 color = bg_color.rgb;
	color += grid_color.rgb * grid;
	color += rain_color.rgb * rain;
	color -= scanline;

	// --- Vignette (assombrit les bords) ---
	vec2 uvc = UV - 0.5;
	color *= clamp(1.0 - dot(uvc, uvc) * 0.9, 0.0, 1.0);

	COLOR = vec4(color, 1.0);
}
