# Base Template - Complete Features Guide

This document is a comprehensive guide to your production-ready Godot 4.5 mobile game base template with all systems for combat, movement, abilities, and UI.

---

## 📚 What's Included

✅ **EntityBase** - Flexible NPC system with combat, movement, targeting  
✅ **Concrete Classes** - Hero, Mob, Monster implementations  
✅ **Ability System** - Cooldown management, energy system, modular abilities  
✅ **UI Framework** - Responsive header/footer with signal-based integration  
✅ **Main Game Manager** - Orchestrates game flow, spawning, scoring  
✅ **State Management** - godot_state_charts for all AI logic  
✅ **Example Scenes** - Ready-to-use hero/mob/monster templates

---

## 🎮 NPC CLASS HIERARCHY

```
EntityBase (abstract)
├── HeroBase (player character or ally)
├── MobBase (generic enemy minion)
└── MonsterBase (boss/special enemy with stages)
```

### HeroBase (`Scenes/NPCs/Hero/hero_base_class.gd`)

**Purpose:** Player character or AI-controlled hero

**Key Features:**

- Health system with damage/heal
- XP & leveling system (automatic stat scaling)
- Combat role support (MELEE, RANGED, SUPPORT)
- Attack timer cooldown
- Signals: `health_changed`, `leveled_up`, `died`

**Example Usage:**

```gdscript
var hero: HeroBase = hero_scene.instantiate()
hero.take_damage(10.0)
hero.heal(5.0)
hero.gain_xp(50.0)  # Auto-level when reaching threshold
```

**Export Properties:**

- `max_health` — Starting health (default 100)
- `base_movement_speed` — Movement speed (default 120)
- `base_attack_range` — Attack range (default 50)
- `base_attack_damage` — Attack damage (default 15)
- `attack_cooldown` — Attack cooldown in seconds (default 1.0)
- `hero_level` — Current level (default 1)
- `xp_to_level_up` — XP required for level (default 100, scales 1.2x per level)

---

### MobBase (`Scenes/NPCs/Mobs/mob_base_class.gd`)

**Purpose:** Generic minion/enemy

**Key Features:**

- Simple health system
- Configurable combat behavior
- Idle wandering with boundaries
- Combat state tracking
- Spawn point memory for reset mechanics
- Signals: `health_changed`, `died`

**Example Usage:**

```gdscript
var mob: MobBase = mob_scene.instantiate()
mob.take_damage(5.0)
mob.apply_damage_to_target(target, 8.0)
mob.reset_to_spawn()  # Return to spawn location
```

**Export Properties:**

- `max_health` — Health pool (default 50)
- `base_movement_speed` — Move speed (default 80)
- `base_attack_range` — Attack range (default 40)
- `base_attack_damage` — Damage per attack (default 8)
- `attack_cooldown` — Cooldown (default 1.5)
- `base_idle_retarget_time` — Idle retarget interval (default 1.2)
- `base_idle_wander_radius` — Idle wander distance (default 150)

---

### MonsterBase (`Scenes/NPCs/Monster/monster_base_class.gd`)

**Purpose:** Boss/special enemy with multi-stage progression

**Key Features:**

- Stage system (1-3 stages by default)
- Automatic stat scaling per stage
- Health pool increases with stages
- Damage multiplier scales with difficulty
- Stage transition signals
- XP rewards scale by stage
- Signals: `health_changed`, `stage_changed`, `died`

**Example Usage:**

```gdscript
var monster: MonsterBase = monster_scene.instantiate()
# Monster automatically transitions to new stage at 50% health
# Damage and speed increase each stage
```

**Export Properties:**

- `max_health` — Stage 1 base health (default 200)
- `max_stages` — Number of progression stages (default 3)
- `health_per_stage` — Health added per stage (default 200)
- `damage_multiplier_per_stage` — Damage scaling (default 1.2x)

**Stage Mechanics:**

- Stage 1: 0-33% of max health
- Stage 2: 33-67% of max health
- Stage 3: 67-100% of max health
- Each stage increases damage by multiplier
- Signals `stage_changed` on transition

---

## ⚙️ ABILITY SYSTEM

### Overview

A modular, extensible ability system featuring:

- Cooldown management
- Energy cost system
- Slot-based ability selection
- Easy ability creation

### Core Classes

#### AbilityBase (`Scripts/ability_base.gd`)

Base class for all abilities. Override these methods in child classes:

```gdscript
extends AbilityBase

func get_ability_name() -> StringName:
    return &"MyAbility"

func can_cast_ability(caster: Node2D = null) -> bool:
    # Add custom cast conditions
    return is_ability_ready() and super.can_cast_ability(caster)

func execute_ability(caster: Node2D, target: Node2D = null) -> void:
    # Implement ability effect
    start_cooldown()
    ability_triggered.emit(ability_name)
```

**Signals:**

- `ability_triggered(ability_name)` — fired when ability executes
- `ability_cooldown_started(ability_name, duration)` — cooldown begins
- `ability_ready(ability_name)` — ability comes off cooldown

**API:**

```gdscript
ability.is_ability_ready()          # bool
ability.can_cast_ability(caster)    # bool
ability.execute_ability(caster, target)
ability.start_cooldown()
ability.reset_cooldown()
ability.get_remaining_cooldown()    # float
```

#### BasicAttackAbility (`Scripts/basic_attack_ability.gd`)

Built-in basic attack—use as template for other abilities.

```gdscript
@export var attack_damage: float = 10.0
@export var attack_range: float = 50.0
@export var attack_knockback: float = 200.0
```

#### AbilitySystem (`Scripts/ability_system.gd`)

Manages ability slots, cooldowns, and casting.

**Usage:**

```gdscript
var ability_system: AbilitySystem = AbilitySystem.new()
ability_system.owner_entity = hero
add_child(ability_system)

# Add ability to slot
var fireball = FireballAbility.new()
ability_system.add_ability(fireball, 1)  # Slot 1

# Cast ability
ability_system.try_cast_ability(0)  # Slot 0
ability_system.try_cast_ability_by_name(&"Fireball", target)

# Manage energy
ability_system.add_energy(50.0)
ability_system.consume_energy(20.0)
ability_system.get_energy()  # Current energy
```

**Ability Slots:** 0-3 (4 slots total)

**Energy System:**

- Max energy: 100 (configurable)
- Regen: 10/second (configurable)
- Costs deducted on cast

---

## 🎨 UI FRAMEWORK

### HeaderUI (`Scenes/UI/Header/`)

Display game info at top of screen.

**API:**

```gdscript
header.set_title("Level 1: Forest")
header.set_score(1250)
header.show_header()
header.hide_header()
header.button_pressed.connect(on_header_button)
```

**Default Elements:**

- Title/level label
- Score display

### FooterUI (`Scenes/UI/Footer/`)

Display status and health at bottom.

**API:**

```gdscript
footer.set_status("Ready - Select target")
footer.update_health_display(current_hp, max_hp)
footer.show_footer()
footer.hide_footer()
footer.button_pressed.connect(on_footer_button)
```

**Default Elements:**

- Status text
- Health progress bar

---

## 🎮 GAME MANAGER (`main.gd`)

Central game orchestrator with signal-based architecture.

**Key Methods:**

```gdscript
# Spawning
spawn_hero(scene, position) -> HeroBase
spawn_mob(scene, position) -> MobBase
spawn_monster(scene, position) -> MonsterBase

# Scoring
add_score(points)

# UI Updates
update_status(text)
update_health_display(current, max)

# Game State
end_game(victory: bool)
```

**Signals:**

- `game_started` — game begins
- `game_ended(victory: bool)` — game ends
- (entity signals automatically connected)

**Entity Event Handling:**

- Hero health changes → UI updates
- Hero dies → `game_ended(false)`
- Mob dies → +10 score
- Monster dies → +500 score, `game_ended(true)`
- Monster stage change → +100 score

---

## 📋 EXAMPLE SCENES

Three ready-to-use example scenes:

1. **hero_example.tscn** — Green hero (MELEE)
2. **mob_example.tscn** — Red mob (generic enemy)
3. **monster_example.tscn** — Purple boss (multi-stage)

All include:

- StateChart for AI
- Detection area for targeting
- Health bar
- Sprite (placeholder)

### Quick Setup

```gdscript
# In main.gd
func _ready():
    var hero = spawn_hero(load("res://Scenes/NPCs/Hero/hero_example.tscn"), Vector2(100, 100))
    var mob = spawn_mob(load("res://Scenes/NPCs/Mobs/mob_example.tscn"), Vector2(300, 300))
    var boss = spawn_monster(load("res://Scenes/NPCs/Monster/monster_example.tscn"), Vector2(500, 500))
```

---

## 🏗️ ARCHITECTURE

### State Chart Structure

```
StateChart
├── Root
    ├── Alive (compound state)
    │   ├── Idle (atomic - wander, check for enemies)
    │   ├── Approach (atomic - chase target)
    │   └── Fight (atomic - attack target)
    └── Dead (atomic - cleanup/respawn)

Events:
- enemie_entered → Idle → Approach
- enemy_fight → Approach → Fight
- enemie_exited → Fight/Approach → Idle
- re_approach → Fight → Approach
- death → Alive → Dead
```

### Virtual Methods Pattern

EntityBase uses virtual methods for polymorphism:

```gdscript
# Override in child classes:
func _get_move_speed() -> float
func _get_attack_range() -> float
func _get_idle_retarget_time() -> float
func _get_idle_wander_radius() -> float
func _get_keep_distance() -> float
```

### Signal-Based Communication

No direct `get_node()` calls. Everything uses signals:

```gdscript
hero.health_changed.connect(on_health_changed)
hero.died.connect(on_hero_died)
header.button_pressed.connect(on_button_pressed)
```

---

## 🚀 QUICK START CHECKLIST

- [ ] Create custom hero scene extending `hero_example.tscn`
- [ ] Create custom mob scenes
- [ ] Create custom monster boss scene
- [ ] Implement ability classes (extend `AbilityBase`)
- [ ] Add custom abilities to `AbilitySystem._setup_initial_abilities()`
- [ ] Set group affiliations ("Hero", "Monster", "Enemy")
- [ ] Configure export properties per entity
- [ ] Test targeting system (should auto-engage nearby enemies)
- [ ] Add animations to sprites
- [ ] Implement sound effects in ability execute
- [ ] Test on target device

---

## 🎯 COMMON CUSTOMIZATIONS

### Create Custom Ability

```gdscript
# res://Scripts/fireball_ability.gd
extends AbilityBase
class_name FireballAbility

@export var fireball_damage: float = 25.0
@export var explosion_radius: float = 100.0

func _ready() -> void:
    ability_name = &"Fireball"
    cooldown_duration = 3.0
    energy_cost = 30.0

func execute_ability(caster: Node2D, target: Node2D = null) -> void:
    if not is_instance_valid(target):
        return

    # Damage all enemies in radius
    var space = caster.get_world_2d().direct_space_state
    var query = PhysicsShapeQueryParameters2D.create(
        CircleShape2D.new(),
        Transform2D(0, target.global_position)
    )

    # Deal damage, show particles, etc.
    start_cooldown()
    ability_triggered.emit(ability_name)
```

### Implement XP Drops

```gdscript
# In MobBase._on_mob_died()
func _on_mob_died() -> void:
    # Spawn XP orb
    var xp_orb = XPOrbScene.instantiate()
    xp_orb.global_position = global_position
    xp_orb.xp_amount = 50
    get_parent().add_child(xp_orb)
```

### Add Loot Drops

```gdscript
# In MonsterBase._on_monster_died()
func _on_monster_died() -> void:
    # Spawn loot chest
    var chest = LootChestScene.instantiate()
    chest.global_position = global_position
    chest.add_loot("weapon", {"rarity": "rare"})
```

---

## ✅ TESTING GUIDE

### Basic Functionality

1. Hero spawns and is controllable
2. Mobs detect and attack hero
3. Hero can attack mobs (damage is visible)
4. Mobs die and grant XP/score
5. Hero levels up automatically

### Combat

1. Targeting system prioritizes correct enemies
2. Heroes chase enemies that come into range
3. Combat roles (melee/ranged) behave differently
4. Monster stages increase difficulty

### UI

1. Header displays score and title
2. Footer shows health bar
3. Buttons trigger correct actions
4. Status text updates appropriately

### Performance

1. 60 FPS with 10+ entities
2. No memory leaks on entity death
3. Navigation pathfinding smooth

---

## 📖 SYSTEM DEPENDENCIES

- **godot_state_charts** addon (installed in addons/)
- **Types autoload** (Globals/types.gd)
- **Global autoload** (Globals/global.gd)
- **Mobile viewport** (720×1280 portrait)

---

## 🔧 TROUBLESHOOTING

**Entities don't move:**

- Check StateChart exists and is unique-named `%StateChart`
- Verify Navigation2D setup
- Check `collision_mask` on physics nodes

**Enemies don't detect player:**

- Verify `%DetectionArea` exists
- Check group affiliations ("Hero", "Monster", "Enemy")
- Confirm `can_entity_target()` logic in Global

**Abilities not working:**

- Confirm `AbilitySystem` instance on entity
- Check ability `is_ability_ready()`
- Verify `energy_cost` is available

**UI not showing:**

- Check HeaderUI/FooterUI scenes added to main
- Verify CanvasLayer layer is 10
- Check unique names match `%HeaderUI`, `%FooterUI`

---

**Your template is now production-ready!** 🎉
