# Complete Template Systems - Comprehensive Guide

This document covers all the systems now included in the base template, extracted and generalized from production projects.

---

## 📋 Table of Contents

1. [Static Defense System](#static-defense-system-turrets-towers)
2. [Projectile System](#projectile-system)
3. [Wave & Spawner System](#wave--spawner-system)
4. [Upgrade & Progression System](#upgrade--progression-system)
5. [Game State Manager](#game-state-manager)
6. [Input Handler](#input-handler)
7. [Settings Manager](#settings-manager)
8. [System Integration](#system-integration)

---

## Static Defense System (Turrets/Towers)

**Generic tower/turret system extracted and generalized from `realm_villagev2`'s BaseTurret**

### Location
- **Class:** `Scenes/Towers/static_defense_base.gd`
- **Scene:** `Scenes/Towers/generic_tower_example.tscn`

### Key Features

✅ Multiple targeting modes (first, last, strongest, weakest)  
✅ Automatic enemy detection and targeting  
✅ Rotation toward target with smooth animation  
✅ Configurable attack cooldowns and damage  
✅ XP-based leveling with stat scaling  
✅ Health management and destruction handling  
✅ Range visualization toggle  
✅ Click detection for UI interaction  
✅ Virtual `fire()` method for custom attack behavior  

### Export Properties

```gdscript
# Tower Stats
tower_name: StringName = &"Tower"
max_health: float = 100.0
attack_damage: float = 10.0
attack_range: float = 300.0
rate_of_fire: float = 1.0  # seconds between attacks
rotation_speed: float = 5.0

# Leveling
xp_per_kill: float = 10.0
xp_threshold: float = 50.0
max_level: int = 5
stat_scaling: float = 1.1  # damage per level

# Targeting
default_targeting_mode: StringName = &"first"  # first, last, strongest, weakest

# Visual
show_range_on_start: bool = false
range_color: Color = Color.BLUE
```

### Key Methods

```gdscript
# Targeting
set_targeting_mode(mode: StringName) -> void
_select_first_enemy() -> void
_select_last_enemy() -> void
_select_strongest_enemy() -> void
_select_weakest_enemy() -> void

# Combat
fire() -> void  # Virtual - override for custom attacks
calculate_damage() -> float
_apply_damage_to_target(target: Node) -> void

# Health & Leveling
take_damage(damage: float) -> void
heal(amount: float) -> void
add_xp(amount: float) -> void
_level_up() -> void

# Detection
_on_detection_area_entered(body: Node2D) -> void
_on_detection_area_exited(body: Node2D) -> void

# Utility
get_detected_enemy_count() -> int
get_level_percentage() -> float
get_health_percentage() -> float
is_targeting_enemy() -> bool
```

### Signals

```gdscript
signal tower_clicked
signal enemy_spotted(enemy: Node)
signal enemy_lost(enemy: Node)
signal leveled_up(new_level: int)
signal fire_triggered(target: Node)
signal targeting_mode_changed(mode: StringName)
```

### Scene Structure

```
GenericTurret (Node2D + StaticDefenseBase)
├── Base (Sprite2D) — static base sprite
├── TurretSprite (Sprite2D) — rotatable turret
├── ClickArea (Area2D) — for click detection
│   └── ClickCollision (CollisionShape2D)
├── DetectionArea (Area2D) — for enemy detection
│   ├── DetectionCollision (CollisionShape2D)
│   └── RangeDisplay (Node2D) — range visualization
└── FireTimer (Timer) — attack cooldown
```

### How to Extend

Create a specific tower by extending StaticDefenseBase:

```gdscript
extends StaticDefenseBase
class_name IceTowerBase

func fire() -> void:
	"""Override to create ice ball projectile"""
	if current_target:
		var projectile = ice_projectile_scene.instantiate()
		get_parent().add_child(projectile)
		projectile.global_position = global_position
		projectile.set_direction_to(current_target)
		projectile.set_damage(calculate_damage())
		super.fire()  # Call parent for effects
```

---

## Projectile System

**Generic projectile for bullets, spells, area effects**

### Location
- **Class:** `Scripts/projectile_base.gd`

### Key Features

✅ Velocity-based movement  
✅ Automatic lifetime management  
✅ Collision detection with damage  
✅ Damage falloff on pierce  
✅ Knockback application  
✅ Signal-based hit detection  
✅ Easy to extend  

### Export Properties

```gdscript
# Movement
projectile_speed: float = 500.0
max_lifetime: float = 10.0
direction: Vector2 = Vector2.RIGHT

# Damage
base_damage: float = 10.0
damage_falloff: float = 1.0  # 1.0 = no falloff
can_pierce: bool = false
max_targets: int = 1

# Effects
apply_knockback: bool = true
knockback_force: float = 100.0
lifetime_visual_scale: Vector2 = Vector2.ONE
```

### Key Methods

```gdscript
set_direction(new_direction: Vector2) -> void
set_speed(new_speed: float) -> void
set_damage(new_damage: float) -> void
get_lifetime_ratio() -> float
apply_lifetime_effects() -> void  # Override for custom fade effects
```

### Signals

```gdscript
signal hit_target(target: Node)
signal hit_world(position: Vector2)
signal projectile_destroyed
```

### Usage Example

```gdscript
# Create and fire projectile
var projectile = projectile_scene.instantiate()
add_child(projectile)
projectile.global_position = tower.global_position
projectile.set_direction((enemy.global_position - tower.global_position).normalized())
projectile.set_damage(tower.calculate_damage())
projectile.hit_target.connect(_on_projectile_hit)
```

---

## Wave & Spawner System

**Tower defense style wave spawning with difficulty scaling**

### Location
- **Class:** `Scripts/wave_spawner.gd`
- **Resources:** `Scripts/wave_spawner.gd` contains `WaveData` resource class

### Key Features

✅ Wave-based progression  
✅ Multiple enemy types per wave  
✅ Difficulty scaling (health, damage, count)  
✅ Customizable spawn intervals  
✅ XP/currency rewards  
✅ Pause/resume functionality  

### Export Properties

```gdscript
# Wave Settings
total_waves: int = 5
delay_between_waves: float = 3.0
max_spawned_at_once: int = 5

# Scaling
enemy_health_scale: float = 1.1
enemy_damage_scale: float = 1.05
wave_size_scale: float = 1.15

# Rewards
base_xp_per_wave: float = 100.0
base_currency_per_wave: float = 50.0
reward_scale: float = 1.2

# Spawn Points (assigned in editor)
spawn_points: Array[Marker2D] = []

# Wave Data (populated via editor or code)
waves: Array[WaveData] = []
```

### Key Methods

```gdscript
start_waves() -> void
_start_next_wave() -> void
_spawn_wave(wave_number: int) -> void
_spawn_single_enemy(wave_data: WaveData) -> void

pause_spawning() -> void
resume_spawning() -> void
stop_all_waves() -> void

get_wave_progress() -> float
get_active_enemy_count() -> int
```

### Signals

```gdscript
signal wave_started(wave_number: int, total_enemies: int)
signal wave_completed(wave_number: int, enemies_defeated: int)
signal all_waves_completed(total_waves: int)
signal enemy_spawned(enemy: Node, wave: int)
signal difficulty_increased(multiplier: float)
```

### WaveData Resource

```gdscript
# Create WaveData in editor or code
var wave_1 = WaveData.new()
wave_1.base_enemy_count = 5
wave_1.spawn_interval = 1.0
wave_1.enemy_scenes = [mob_scene, mob_scene]  # Array of scenes
waves.append(wave_1)
```

### Setup Example

```gdscript
# In your game manager
@onready var wave_spawner: WaveSpawner = %WaveSpawner

func _ready() -> void:
	wave_spawner.wave_started.connect(_on_wave_started)
	wave_spawner.wave_completed.connect(_on_wave_completed)
	wave_spawner.all_waves_completed.connect(_on_all_waves_complete)
	
	wave_spawner.start_waves()
```

---

## Upgrade & Progression System

**Universal upgrade tree and progression management**

### Location
- **Class:** `Scripts/upgrade_system.gd`
- **Resources:** `Scripts/upgrade_system.gd` contains `UpgradeData` resource class

### Key Features

✅ Tree-based upgrade progression  
✅ Level-based requirements  
✅ Prerequisite chain support  
✅ Currency management  
✅ XP and leveling  
✅ Stat modification application  
✅ Persistent save/load  

### Export Properties

```gdscript
# Game State
player_level: int = 1
max_level: int = 50
current_currency: float = 0.0

# Currency
currency_name: StringName = &"Gold"
currency_per_kill: float = 10.0
currency_per_level: float = 100.0

# Progression
xp_per_kill: float = 10.0
xp_to_level_up: float = 100.0
xp_multiplier_per_level: float = 1.1
```

### Key Methods

```gdscript
# Currency
add_currency(amount: float) -> void
spend_currency(amount: float) -> bool
get_currency() -> float

# XP & Leveling
add_xp(amount: float) -> void
get_xp_ratio() -> float

# Upgrades
purchase_upgrade(upgrade_id: StringName) -> bool
is_upgrade_purchased(upgrade_id: StringName) -> bool
can_purchase_upgrade(upgrade_id: StringName) -> bool
get_upgrade_status(upgrade_id: StringName) -> Dictionary
get_available_upgrades() -> Array[UpgradeData]

# Utility
apply_stat_modifier(target: Node, stat: String, modifier: float) -> void
get_level_percentage() -> float
reset_progression() -> void
```

### Signals

```gdscript
signal upgrade_purchased(upgrade_id: StringName)
signal upgrade_available(upgrade_id: StringName)
signal currency_changed(new_amount: float)
signal level_changed(new_level: int)
```

### Creating an Upgrade Tree

```gdscript
var upgrade_system = UpgradeSystem.new()

# Create upgrades
var basic_attack = UpgradeData.new()
basic_attack.id = &"attack_1"
basic_attack.upgrade_name = "Attack Power I"
basic_attack.cost = 100.0
basic_attack.required_level = 1
basic_attack.stat_changes = {"damage": 1.1}

upgrade_system.available_upgrades.append(basic_attack)

# Purchase upgrade
if upgrade_system.purchase_upgrade(&"attack_1"):
	print("Upgrade purchased!")
```

---

## Game State Manager

**Central game flow and level progression**

### Location
- **Class:** `Scripts/game_state_manager.gd`

### Key Features

✅ Game state machine (menu, playing, paused, game over, etc.)  
✅ Level/scene management  
✅ Pause system  
✅ Difficulty selection  
✅ Statistics tracking  
✅ Save/load system  
✅ Auto-save functionality  

### Game States

```gdscript
enum GameState {
	MENU = 0,
	LOADING = 1,
	PLAYING = 2,
	PAUSED = 3,
	GAME_OVER = 4,
	VICTORY = 5,
	QUIT = 6
}
```

### Export Properties

```gdscript
# Levels
level_scenes: Dictionary = {
	"level_1": "res://Scenes/Levels/level_1.tscn",
}
starting_level: String = "tutorial"

# Settings
allow_pause: bool = true
auto_save_enabled: bool = true
auto_save_interval: float = 60.0

# Difficulty Multipliers
difficulty_multipliers: Dictionary = {
	"easy": 0.75,
	"normal": 1.0,
	"hard": 1.5,
	"nightmare": 2.0,
}
```

### Key Methods

```gdscript
# State Management
change_game_state(new_state: GameState) -> void
get_current_state() -> GameState
is_game_running() -> bool

# Pause System
toggle_pause() -> void
set_pause(paused: bool) -> void

# Level Management
load_level(level_name: String) -> void
start_game() -> void
restart_level() -> void
next_level() -> void
level_complete() -> void

# Difficulty
set_difficulty(difficulty: String) -> void
get_difficulty_multiplier() -> float

# Statistics
add_score(points: int) -> void
increment_enemies_defeated() -> void
update_health_remaining(health: float, max_health: float) -> void
get_game_stats() -> Dictionary

# Save & Load
save_game(save_slot: int = 1) -> bool
load_game(save_slot: int = 1) -> bool

# Utility
quit_game() -> void
exit_to_desktop() -> void
```

### Signals

```gdscript
signal game_state_changed(new_state: GameState)
signal level_started(level_name: String)
signal level_completed(level_name: String)
signal game_over(victory: bool, stats: Dictionary)
signal difficulty_changed(difficulty: String)
signal pause_state_changed(is_paused: bool)
```

### Usage Example

```gdscript
# In autoload or main script
extend Node
class_name GameManager

var state_manager: GameStateManager

func _ready() -> void:
	state_manager = GameStateManager.new()
	add_child(state_manager)
	state_manager.game_state_changed.connect(_on_state_changed)
	state_manager.start_game()

func _on_state_changed(state: GameStateManager.GameState) -> void:
	match state:
		GameStateManager.GameState.PLAYING:
			print("Game started!")
		GameStateManager.GameState.PAUSED:
			print("Game paused!")
		GameStateManager.GameState.GAME_OVER:
			print("Game over!")
```

---

## Input Handler

**Multi-device input management (touch, mouse, keyboard)**

### Location
- **Class:** `Scripts/input_handler.gd`

### Key Features

✅ Touch, mouse, and keyboard input  
✅ Gesture recognition (tap, drag, long-press)  
✅ Customizable input mappings  
✅ Mobile-friendly touch handling  
✅ Input remapping support  

### Export Properties

```gdscript
# Settings
input_enabled: bool = true
debug_input_positions: bool = false

# Touch Settings
touch_deadzone: float = 10.0
long_press_duration: float = 0.5
double_tap_delay: float = 0.3

# Control Mappings
action_map: Dictionary = {
	"select": ["LMB", "Touch"],
	"build": ["B", "Double_Tap"],
	"menu": ["ESC", "Back_Button"],
	"pause": ["P", "LMB_Long_Press"],
}
```

### Key Methods

```gdscript
# Input Control
set_input_enabled(enabled: bool) -> void
is_input_active() -> bool

# Input Info
get_last_input_position() -> Vector2
get_last_input_type() -> InputType
get_drag_distance() -> float
is_pointer_over_ui() -> bool

# Input Remapping
remap_action(action_name: StringName, new_input: String) -> void
get_input_string(action_name: StringName) -> String
```

### Signals

```gdscript
signal input_pressed(action: StringName, position: Vector2)
signal input_released(action: StringName, position: Vector2)
signal input_dragged(position: Vector2, delta: Vector2)
signal touch_long_pressed(position: Vector2)
signal ui_back_pressed
signal ui_pause_pressed
```

### Input Types

```gdscript
enum InputType {
	TOUCH,
	MOUSE,
	KEYBOARD,
}
```

### Usage Example

```gdscript
@onready var input_handler: InputHandler = %InputHandler

func _ready() -> void:
	input_handler.input_pressed.connect(_on_input_pressed)
	input_handler.input_dragged.connect(_on_input_dragged)
	input_handler.touch_long_pressed.connect(_on_long_press)

func _on_input_pressed(action: StringName, position: Vector2) -> void:
	if action == &"select":
		print("Clicked at", position)

func _on_input_dragged(position: Vector2, delta: Vector2) -> void:
	print("Dragged from", position - delta, "to", position)
```

---

## Settings Manager

**Game settings, audio, graphics, and accessibility**

### Location
- **Class:** `Scripts/settings_manager.gd`

### Key Features

✅ Audio control (master, music, SFX, voice)  
✅ Graphics settings (quality, fps, vsync)  
✅ Gameplay preferences  
✅ Accessibility options  
✅ Persistent settings  
✅ Quality presets  

### Export Properties

```gdscript
# Audio
master_volume: float = 1.0
music_volume: float = 0.8
sfx_volume: float = 0.8
voice_volume: float = 0.8

# Graphics
fullscreen: bool = false
vsync_enabled: bool = true
fps_cap: int = 60
particle_quality: String = "high"

# Gameplay
difficulty: String = "normal"
show_tutorials: bool = true
auto_aim: bool = false

# Accessibility
language: String = "en"
text_scale: float = 1.0
colorblind_mode: String = "off"
show_subtitles: bool = true
```

### Key Methods

```gdscript
# Audio
set_master_volume(volume: float) -> void
set_music_volume(volume: float) -> void
set_sfx_volume(volume: float) -> void
set_voice_volume(volume: float) -> void

# Graphics
set_fullscreen(enabled: bool) -> void
set_vsync(enabled: bool) -> void
set_fps_cap(fps: int) -> void
set_quality_preset(preset: String) -> void

# Accessibility
set_language(lang: String) -> void
set_text_scale(scale: float) -> void
set_colorblind_mode(mode: String) -> void

# Persistence
save_settings() -> bool
load_settings() -> bool
reset_to_defaults() -> void
```

### Signals

```gdscript
signal setting_changed(key: String, value: Variant)
signal master_volume_changed(volume: float)
signal music_volume_changed(volume: float)
signal graphics_setting_changed(setting: String, value: Variant)
signal language_changed(language: String)
```

### Quality Presets

```gdscript
quality_presets = {
	"low": {
		"particle_quality": "low",
		"fps_cap": 30,
	},
	"medium": {
		"particle_quality": "medium",
		"fps_cap": 60,
	},
	"high": {
		"particle_quality": "high",
		"fps_cap": 144,
	},
}
```

---

## System Integration

### Recommended Autoloads

```gdscript
# project.godot
[autoload]
Global="*res://Globals/global.gd"
Types="*res://Globals/types.gd"
GameState="*res://Scripts/game_state_manager.gd"
InputHandler="*res://Scripts/input_handler.gd"
Settings="*res://Scripts/settings_manager.gd"
```

### Complete Game Flow

```
Startup
├── Load Settings
├── Initialize GameState
├── Setup UI
└── Enter Menu

Game Start
├── Create WaveSpawner
├── Create UpgradeSystem
├── Add Towers
├── Start Waves
└── Begin Combat

During Game
├── Detect Input
├── Update Towers
├── Spawn Waves
├── Apply Upgrades
├── Track Statistics
└── Save Progress

Game End
├── Calculate Stats
├── Award Currency/XP
├── Save Results
└── Return to Menu
```

### Example Integrated Game Script

```gdscript
extends Node
class_name GameController

@onready var wave_spawner: WaveSpawner = %WaveSpawner
@onready var upgrade_system: UpgradeSystem = %UpgradeSystem
@onready var input_handler: InputHandler = %InputHandler

func _ready() -> void:
	# Connect systems
	GameState.game_state_changed.connect(_on_game_state_changed)
	wave_spawner.all_waves_completed.connect(_on_victory)
	input_handler.input_pressed.connect(_on_input)
	Settings.master_volume_changed.connect(_on_volume_changed)
	
	# Start game
	GameState.start_game()
	wave_spawner.start_waves()

func _on_input(action: StringName, position: Vector2) -> void:
	if action == &"select":
		_try_build_tower(position)

func _try_build_tower(position: Vector2) -> void:
	if upgrade_system.spend_currency(100.0):
		var tower = tower_scene.instantiate()
		add_child(tower)
		tower.global_position = position

func _on_victory() -> void:
	GameState.next_level()
```

---

## File Structure Summary

```
Template/
├── Scenes/
│   ├── Towers/
│   │   ├── static_defense_base.gd ✨
│   │   └── generic_tower_example.tscn ✨
│   └── [existing NPC scenes]
│
├── Scripts/
│   ├── projectile_base.gd ✨
│   ├── wave_spawner.gd ✨
│   ├── upgrade_system.gd ✨
│   ├── game_state_manager.gd ✨
│   ├── input_handler.gd ✨
│   ├── settings_manager.gd ✨
│   ├── ability_base.gd
│   ├── ability_system.gd
│   └── [other systems]
│
└── [other folders]
```

---

## ✅ Complete Feature Checklist

**NPC Systems:**
- ✅ EntityBase with combat
- ✅ HeroBase with leveling
- ✅ MobBase for enemies
- ✅ MonsterBase for boss fights
- ✅ Ability system with 4 slots

**Defense Systems:**
- ✅ StaticDefenseBase (towers/turrets)
- ✅ Multiple targeting modes
- ✅ Projectile system
- ✅ Range visualization

**Progression Systems:**
- ✅ Wave spawning with scaling
- ✅ Upgrade tree system
- ✅ XP and leveling

**Game Management:**
- ✅ State machine
- ✅ Level management
- ✅ Save/load system
- ✅ Statistics tracking

**Input & UI:**
- ✅ Multi-device input handler
- ✅ Settings manager
- ✅ Header/Footer UI
- ✅ Pause system

All systems are **signal-based, fully typed, and production-ready!** 🚀
