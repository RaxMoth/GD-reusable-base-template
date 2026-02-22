# ⚡ Quick Start Guide - 5 Minute Setup

Get a working game running in minutes using the base template example scenes.

---

## Step 1: Open the Project

```
1. Open Godot 4.5
2. Open: reusable-base-template/project.godot
3. Wait for import to complete
```

---

## Step 2: Create a Simple Main Script

You already have `main.gd` — it's ready to use!

Just verify it exists: `res://main.gd`

---

## Step 3: Setup the Main Scene

The main scene is already configured: `res://main.tscn`

It includes:

- ✅ GameWorld with NavigationRegion2D
- ✅ UI CanvasLayer with Header/Footer
- ✅ Entities container for spawning NPCs

**You just need to add to `Types` in `project.godot` autoloads if not already added:**

_Project → Project Settings → Autoload Tab → Add:_

- `Global` → `res://Globals/global.gd`
- `Types` → `res://Globals/types.gd`

---

## Step 4: Create a Simple Game Script

Add this to `main.gd` in the `_start_game()` function:

```gdscript
func _start_game() -> void:
    is_game_active = true
    current_score = 0

    if footer:
        footer.set_status("Game Started - Ready!")

    game_started.emit()

    # SPAWN EXAMPLE ENTITIES
    var hero = spawn_hero(
        load("res://Scenes/NPCs/Hero/hero_example.tscn"),
        Vector2(360, 300)  # Center-left
    )

    var mob1 = spawn_mob(
        load("res://Scenes/NPCs/Mobs/mob_example.tscn"),
        Vector2(600, 300)  # Right side
    )

    var mob2 = spawn_mob(
        load("res://Scenes/NPCs/Mobs/mob_example.tscn"),
        Vector2(650, 400)
    )

    var boss = spawn_monster(
        load("res://Scenes/NPCs/Monster/monster_example.tscn"),
        Vector2(900, 350)  # Far right - boss
    )

    if enable_debug_mode:
        print("GameManager: Game started with entities spawned")
```

---

## Step 5: Add a Simple TileMap

1. Right-click `Ground` node in main.tscn
2. Create new TileSet → Save as `res://Assets/tileset.tres`
3. Add a simple tile (16x16 or 32x32)
4. Set tileset on Ground node

_Or skip this — combat still works without a tilemap!_

---

## Step 6: Run the Game

```
Press Play (F5)
```

You should see:

- ✅ Header showing "Base Game" and score
- ✅ Footer showing "Game Started - Ready!" and health bar
- ✅ Three red mobs and one purple boss on screen
- ✅ Green hero on the left

---

## Step 7: Test Interactions

**What should happen:**

1. Hero should detect nearby enemies (check detection radius)
2. Mobs should attack hero if hero gets close
3. Combat between entities
4. When an entity dies, score increases
5. Status updates in footer

**If nothing is happening:**

- Check console for errors (F8)
- Verify `%StateChart` exists on each NPC
- Verify `%DetectionArea` has CollisionShape2D
- Check that `Types` and `Global` autoloads are registered

---

## Step 8: Play with Settings

Edit exported properties on the spawned entities:

**Hero (green):**

- `base_attack_damage` - increase to 20 for more damage
- `attack_cooldown` - reduce to 0.5 for faster attacks
- `base_movement_speed` - increase to 150 for faster movement

**Mobs (red):**

- `max_health` - reduce to 20 for easier kills
- `base_attack_damage` - reduce to 5 for less damage taken
- `combat_role` - switch to RANGED (1) to see different behavior

**Monster (purple):**

- `max_stages` - reduce to 2 for shorter boss fight
- `health_per_stage` - reduce to 100 for easier defeat
- `damage_multiplier_per_stage` - increase to 1.5 for harder scaling

---

## Step 9: Add Your First Ability

Create `res://Scripts/slash_ability.gd`:

```gdscript
extends BasicAttackAbility
class_name SlashAbility

func _ready() -> void:
    ability_name = &"Slash"
    cooldown_duration = 0.8
    attack_damage = 25.0
    attack_range = 60.0
```

Modify `hero_base_class.gd` to use it:

```gdscript
var slash_ability = SlashAbility.new()
slash_ability.caster = self
your_ability_system.add_ability(slash_ability, 0)
```

---

## Step 10: Next Steps

Now that the base is working:

1. **Add animations** - Replace placeholder sprites
2. **Add particles** - Death, hit effects
3. **Add sound** - Combat, UI feedback
4. **Create levels** - Multiple waves of enemies
5. **Add UI menus** - Pause, settings, game over
6. **Implement progression** - Weapons, upgrades, stats

---

## 🐛 Troubleshooting

**Game runs but nothing appears:**

- Check console for errors
- Verify camera zoom level
- Check Main scene isn't paused

**Entities don't move:**

- Check Navigation2D setup
- Verify Ground TileMapLayer exists
- Set navigation baking region

**Entities don't detect each other:**

- Verify %DetectionArea exists on each NPC
- Check group affiliations ("Hero", "Monster", "Enemy")
- Verify physics layers/masks in project settings

**Can't see health bar:**

- Check ProgressBar exists on each NPC (%HealthBar)
- Check if UI is being rendered (CanvasLayer)

**Ability not triggering:**

- Verify AbilitySystem exists on entity
- Check ability can_cast_ability() returns true
- Verify cooldown is finished

---

## 📚 Files You're Working With

Key files to understand:

```
main.gd                          # Game orchestrator
main.tscn                        # Main scene with UI

Scenes/NPCs/
├── npc_base_class.gd           # Base class (EntityBase)
├── npc_state_chart.tscn        # State machine template
├── Hero/hero_base_class.gd      # Player class
├── Mobs/mob_base_class.gd       # Enemy class
└── Monster/monster_base_class.gd # Boss class

Scenes/UI/
├── Header/header.gd            # Top UI
└── Footer/footer.gd            # Bottom UI

Scripts/
├── ability_base.gd             # Ability interface
├── ability_system.gd           # Ability manager
└── basic_attack_ability.gd     # Default attack

Globals/
├── types.gd                    # Constants & enums
└── global.gd                   # Utility functions
```

---

## 🎉 You're Ready!

Your template is now running a complete small game with:

- ✅ 3 entity types (Hero, Mob, Monster)
- ✅ Combat with melee/ranged roles
- ✅ Smart AI and targeting
- ✅ Health system
- ✅ Ability system
- ✅ Scoring system
- ✅ UI framework

Build on it! 🚀
