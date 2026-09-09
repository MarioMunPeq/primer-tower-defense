# Primer Tower Defense

Un tower defense 2D construido con [Godot Engine](https://godotengine.org/) (v4.7, motor de renderizado *GL Compatibility*).

Defiende tu base de las oleadas de enemigos que recorren el camino del mapa. Coloca torres en los islotes de arena disponibles, mejóralas para aumentar su daño, alcance y cadencia, y quédate sin vidas y pierde (o sobrevive a las 5 oleadas y gana).

## Características

- **3 tipos de torre**, cada una con su rol:
  - **Básica** – equilibrada, todo terreno.
  - **Rápida** – dispara a gran cadencia, con daño por disparo más bajo.
  - **Francotirador (Sniper)** – mucho daño y alcance, pero cadencia lenta.

- **3 tipos de enemigo**:
  - **Básico** – el estándar.
  - **Rápido** – más velocidad, menos vida.
  - **Tanque** – mucha vida y reducción de daño.

- **5 oleadas** progresivas; victoria al superarlas todas y derrota cuando se agotan las 100 vidas de la base.

- **Sistema de construcción táctico**: pre-visualización de rango y fantasma de la torre mientras mueves el cursor, torres solo colocables en terreno válido.

- **Selección de torre** con panel de información y estadísticas actuales.

- **Mejoras por nivel** (daño / alcance / cadencia) y **venta** de torres (con diálogo de confirmación opcional configurable).

- **HUD completo**: dinero, vidas, contador de oleadas, control de velocidad (pausa, normal, rápido), menú de opciones y menú de pausa (volver al menú principal o salir).

- **Efectos visuales**: partículas de impacto y de muerte, números de daño (pool con objeto reutilizable), tooltips con iconos en tarjetas de la tienda y torres del mapa.

- **Sistema de settings persistente** (`user://settings.cfg`): pantalla completa, calidad de escalado, velocidad por defecto y confirmación de venta.

## Requisitos

- **Godot 4.7** (o compatible con `features = "4.7"`, `GL Compatibility`).
- Windows / Linux / macOS. También exportable a web (HTML5).
- Una tarjeta gráfica compatible con OpenGL 3.3 (renderer de compatibilidad).

## Cómo ejecutar

1. Clona o descarga este repositorio.
2. Abre el proyecto con Godot: *Import* → selecciona `project.godot` (o ejecuta el editor y abre la carpeta).
3. Presiona **F5** o *Run Project*.

La primera vez, Godot importará los assets automáticamente. Por línea de comandos:

```
godot --path .
```

> Nota: si vienes de una versión anterior, renombra/borra la caché en `.godot/` si el editor no detecta bien los assets.

## Cómo jugar

| Acción | Control |
| --- | --- |
| Seleccionar torre para colocar | Clic en las tarjetas de la tienda (Básica, Rápida, Francotirador) |
| Colocar torre | Clic izquierdo sobre un islote de arena |
| Seleccionar torre colocada | Clic izquierdo sobre la torre |
| Mejorar torre | Clic en **Mejorar** (botón del panel de la torre) |
| Vender torre | Clic en **Vender** (con confirmación opcional) |
| Pausar / reanudar | Botón de pausa del HUD (o menú de pausa) |
| Control de velocidad | Botones pausa / normal / rápido del HUD |
| Actualizar stats | El panel y los tooltips muestran daño, alcance, cadencia y coste en vivo |

## Estructura del proyecto

```
├── assets/
│   ├── fonts/          # Kenney Future
│   ├── game-icons/     # Iconos de stats (rayo, etc.)
│   ├── particles/      # Materiales de partículas
│   ├── sprites/        # Tiles de torres y terreno (kenney_towerDefense, 256 tiles)
│   ├── tilesets/       # Atlas del mapa
│   └── ui/             # Packs de UI e iconos Kenney (ui-pack, game-icons, board-game-icons)
├── scenes/
│   ├── effects/        # Números de daño, impacto, muerte
│   ├── enemies/        # basic_enemy, fast_enemy, tank_enemy
│   ├── projectiles/    # Proyectil básico
│   ├── tests/          # Harnesses de test en modo headless
│   ├── towers/         # basic_tower, rapid_tower, sniper_tower
│   └── ui/             # Menús, tooltip, confirmación de venta
├── scripts/
│   ├── effects/
│   ├── enemies/        # enemy_base.gd + variantes
│   ├── projectiles/
│   ├── tests/          # stress_test.gd, hud_polish_test.gd
│   ├── towers/         # tower_base.gd + variantes
│   ├── ui/
│   ├── waves/          # wave_spawner.gd
│   ├── main.gd         # Lógica principal de la partida
│   └── settings.gd     # Autoload Settings (persistencia user://settings.cfg)
├── tileset_main.tres   # TileSet del mapa
├── ui_theme.tres       # Tema con variaciones de color para paneles y tarjetas
├── icon.svg
└── project.godot
```

## Tests

El proyecto incluye harnesses de verificación ejecutables en **modo headless**, útiles como prueba de humo para CI o desarrollo local:

```bash
godot --headless --path . res://scenes/tests/stress_test.tscn
godot --headless --path . res://scenes/tests/hud_polish_test.tscn
```

- `stress_test` – carga la partida y simula rondas para detectar errores de runtime.
- `hud_polish_test` – comprueba variaciones del tema, iconos de stats, estados de las tarjetas de la tienda y estructura del tooltip.

Ambos salen con código `0` si todo va bien.

## Assets y créditos

- **Kenney Tower Defense** (sprites de torres, terreno y enemigos) — [Kenney.nl](https://kenney.nl/), licencia **CC0**.
- **Kenney UI Pack** (paneles, botones, estrellas) — licencia **CC0**.
- **Kenney Game Icons** (iconos de iconos/UI) — licencia **CC0**.
- **Kenney Board Game Icons** (icons: espada, reloj de arena) — licencia **CC0**.
- **Kenney Future** (fuente) — por Kennney, **CC0**.

Todo el arte está bajo licencia CC0 (dominio público), tomado de los packs gratuitos de Kenney.