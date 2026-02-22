# Godot 4.5 Reusable Base Template

A **production-ready** mobile game template with complete systems for building 2D games in Godot 4.5.

**🎯 [Quick Start](Docs/QUICK_START.md) • 📚 [Full Documentation](Docs/) • 💻 [View Source](#file-structure)**

---

## ✨ What's Included

13 complete systems for game development:

**Core** • NPC Framework | Ability System | State Machine | Game Manager  
**Defense** • Towers/Turrets | Projectiles  
**Progression** • Wave Spawner | Upgrade System  
**Gameplay** • Game State Manager | Input Handler | Settings Manager  
**UI** • Header/Footer Framework

[See all systems →](Docs/TEMPLATE_SYSTEMS_INDEX.md)

---

## 🎮 Build Any Game Type

- ⚔️ **Action RPG** - Entity system with abilities
- 🃏 **Tower Defense** - Towers, waves, and projectiles
- 🎲 **Roguelike** - Procedural progression
- 🖱️ **Clicker/Idle** - Upgrade system
- 🧩 **Puzzle** - State management
- 🎯 **Shooter** - Projectile system

---

## 📖 Documentation

All docs are in the `Docs/` folder. Start here:

| Document                                                        | Purpose                 | Time   |
| --------------------------------------------------------------- | ----------------------- | ------ |
| **[QUICK_START.md](Docs/QUICK_START.md)**                       | 5-minute setup guide    | 5 min  |
| **[BASE_TEMPLATE_FEATURES.md](Docs/BASE_TEMPLATE_FEATURES.md)** | Complete NPC reference  | 30 min |
| **[TEMPLATE_SYSTEMS_GUIDE.md](Docs/TEMPLATE_SYSTEMS_GUIDE.md)** | All 13 systems          | 1 hour |
| **[TEMPLATE_SYSTEMS_INDEX.md](Docs/TEMPLATE_SYSTEMS_INDEX.md)** | Quick navigation        | 15 min |
| **[instructor.md](Docs/instructor.md)**                         | Architecture principles | 20 min |

[View all docs →](Docs/)

---

## 🚀 Get Started

1. **Open the project** - `reusable-base-template/project.godot`
2. **Register autoloads** - Project → Settings → Autoload:
    ```
    Global    → res://Globals/global.gd
    Types     → res://Globals/types.gd
    GameState → res://Scripts/game_state_manager.gd
    Input     → res://Scripts/input_handler.gd
    Settings  → res://Scripts/settings_manager.gd
    ```
3. **Run example** - Press `F5` to see the game in action
4. **Read guide** - Start with [QUICK_START.md](Docs/QUICK_START.md)

---

## 📁 File Structure

```
reusable-base-template/
├── Docs/                          ← All documentation
│   ├── QUICK_START.md
│   ├── BASE_TEMPLATE_FEATURES.md
│   ├── TEMPLATE_SYSTEMS_GUIDE.md
│   └── [more guides...]
│
├── Scenes/
│   ├── NPCs/
│   │   ├── Hero/, Mobs/, Monster/
│   │   └── example scenes
│   ├── Towers/
│   │   └── Tower system
│   └── UI/
│       └── Header & Footer
│
├── Scripts/
│   ├── *_base.gd              ← Base classes
│   ├── *_system.gd            ← Manager systems
│   ├── ability_*.gd           ← Ability system
│   ├── projectile_base.gd     ← Projectiles
│   ├── wave_spawner.gd        ← Wave system
│   ├── upgrade_system.gd      ← Progression
│   ├── game_state_manager.gd  ← Game flow
│   ├── input_handler.gd       ← Controls
│   ├── settings_manager.gd    ← Options
│   └── [utilities]
│
├── Globals/
│   ├── global.gd              ← Helper utilities
│   └── types.gd               ← Enums & constants
│
└── Assets/
    ├── Icons/
    ├── MainAssets/
    └── Themes/
```

---

## ✅ What You Can Do

- ✅ Run immediately with example scenes
- ✅ Create custom NPCs by extending base classes
- ✅ Build complete games in days not weeks
- ✅ Use same foundation across projects
- ✅ Ship to mobile/web/desktop
- ✅ Scale to 50+ entities smoothly

---

## 🛠️ Requirements

- **Godot** 4.5+ (GL Compatibility)
- **GDScript** 2.0 (typed)
- **Addon** godot_state_charts (included)

---

## 📊 Stats

- **Production Code** - 10,000+ lines
- **Full Type Safety** - 100% typed code
- **Documentation** - 7,000+ lines
- **Systems** - 13 complete
- **Example Scenes** - 10+ ready to use
- **Export Properties** - 100+ tunable

---

## 📜 License

MIT - Use freely in any project!

---

**[→ Start with QUICK_START.md](Docs/QUICK_START.md)**
