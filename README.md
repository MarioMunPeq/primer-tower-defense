# Primer Tower Defense

A polished tower defense game built with **Godot 4.7** (GDScript).  
Designed for web (GitHub Pages) and desktop.

---

## Play

**Web:** https://mariomunpeq.github.io/primer-tower-defense/  
**Desktop:** Download from [Releases](https://github.com/MarioMunPeq/primer-tower-defense/releases)

---

## Overview

| | |
|---|---|
| **Genre** | Tower Defense |
| **Engine** | Godot 4.7.2 (GDScript) |
| **Platform** | Web (HTML5), Windows, Linux |
| **Resolution** | Responsive (desktop + mobile-ready layout) |
| **Waves** | 10 |

![Gameplay screenshot](docs/screenshot-gameplay.png)

---

## How to Play

### Objective
Defend your base through 10 waves. Enemies follow the road from left to right. If they reach the exit, you lose base HP. Game over at 0 HP.

### Controls
| Action | Mouse | Keyboard |
|--------|-------|----------|
| Select tower | Click card | 1–4 (quick select) |
| Place tower | Click valid tile (sand) | — |
| Upgrade / Specialize | Click tower → choose | — |
| Sell tower | Click tower → Sell | — |
| Speed | 1x / 2x / 3x buttons | Space (cycle) |
| Pause | ❚❚ button | P / Escape |

### Economy
- **Money** — Earned by killing enemies. Spend on towers/upgrades.
- **Base HP** — Starts at 100. Each leak reduces it.
- **Refund** — Selling returns 70% of invested cost.

---

## Towers

| Tower | Cost | Damage | Range | Attack | Special |
|-------|------|--------|-------|--------|---------|
| **Basic** | $50 | 1 | 260 | 1.25/s | Splash 46px |
| **Rapid** | $75 | 1 | 150 | 3.0/s | Slow 16% / 1s |
| **Sniper** | $120 | 4 | 480 | 0.5/s | Armor Pierce |
| **Cryo** | $100 | 1 | 200 | 0.71/s | Freeze 70px / 30% |

> **Branching:** At Level 1, choose **Damage** or **Speed** branch. Each branch has 2 upgrades with different stat progression.

---

## Quick Start (Development)

### Requirements
- Godot 4.7.2 (standard or .NET)

### Run Locally
```bash
git clone https://github.com/MarioMunPeq/primer-tower-defense.git
cd primer-tower-defense
# Open in Godot → Run (F5)
# Or CLI:
godot --path .
```

### Export Web
```bash
# Requires Godot 4.7.2 export templates installed
godot --headless --export-release "Web" builds/web/index.html
```

### Project Structure
```
scenes/
  game.tscn          # Main gameplay scene
  ui/                # HUD, tooltips, menus
  towers/            # 4 tower types
  enemies/           # 7 enemy types
scripts/
  main.gd            # Game controller, HUD, waves
  towers/            # Tower logic + branching
  enemies/           # Enemy types + spawner
  ui/                # Tooltip, pause, menus
  effects/           # VFX pools, damage numbers
ui_theme.tres        # Complete theme (plates, cards, tooltips)
```

---

## Credits

- **Art:** [Kenney.nl](https://kenney.nl) — Tower sprites, UI icons, tilemap
- **Font:** Kenney Future (included)
- **Engine:** Godot Engine 4.7.2

---

## License

MIT — see [LICENSE](LICENSE)