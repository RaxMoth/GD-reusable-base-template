## Main game controller - orchestrates game flow, UI, and scene management
##
## Responsibilities:
##   - Initialize game world and UI
##   - Connect UI signals
##   - Manage game state
##   - Handle entity spawning
##
## Signals:
##   game_started() — emitted when game begins
##   game_ended(victory: bool) — emitted when game ends

extends Node2D
class_name GameManager

signal game_started
signal game_ended(victory: bool)

@export_group("Game Settings")
@export var game_title: String = "Base Game"
@export var enable_debug_mode: bool = false

@onready var header: HeaderUI = %HeaderUI
@onready var footer: FooterUI = %FooterUI
@onready var game_world: Node2D = %GameWorld
@onready var entities_container: Node = %Entities

var current_score: int = 0
var is_game_active: bool = false

func _ready() -> void:
	"""Initialize game on startup"""
	_setup_ui()
	_setup_world()
	_start_game()

func _setup_ui() -> void:
	"""Initialize UI components"""
	if header:
		header.set_title(game_title)
		header.button_pressed.connect(_on_header_button_pressed)
	
	if footer:
		footer.set_status("Initializing...")
		footer.button_pressed.connect(_on_footer_button_pressed)

func _setup_world() -> void:
	"""Initialize game world"""
	if enable_debug_mode:
		print("GameManager: Setting up world")

func _start_game() -> void:
	"""Start the game"""
	is_game_active = true
	current_score = 0
	
	if footer:
		footer.set_status("Game Started - Ready!")
	
	game_started.emit()
	
	if enable_debug_mode:
		print("GameManager: Game started")

# ============================================
# SCORE & UI UPDATES
# ============================================

func add_score(points: int) -> void:
	"""Add points to score"""
	current_score += points
	
	if header:
		header.set_score(current_score)
	
	if enable_debug_mode:
		print("Score: " + str(current_score))

func update_status(status_text: String) -> void:
	"""Update footer status text"""
	if footer:
		footer.set_status(status_text)

func update_health_display(current_health: float, max_health: float) -> void:
	"""Update footer health bar"""
	if footer:
		footer.update_health_display(current_health, max_health)

# ============================================
# GAME STATE MANAGEMENT
# ============================================

func end_game(victory: bool) -> void:
	"""End game with win or loss"""
	is_game_active = false
	
	if victory:
		update_status("Victory! Final Score: " + str(current_score))
		if enable_debug_mode:
			print("GameManager: Game won!")
	else:
		update_status("Defeat! Final Score: " + str(current_score))
		if enable_debug_mode:
			print("GameManager: Game lost!")
	
	game_ended.emit(victory)
	
	# Wait before allowing restart
	await get_tree().create_timer(3.0).timeout
	_start_game()

# ============================================
# UI SIGNAL HANDLERS
# ============================================

func _on_header_button_pressed(button_name: StringName) -> void:
	"""Handle header button presses"""
	match button_name:
		&"menu":
			_pause_game()
		&"settings":
			_open_settings()
		_:
			if enable_debug_mode:
				print("Header button pressed: " + button_name)

func _on_footer_button_pressed(button_name: StringName) -> void:
	"""Handle footer button presses"""
	match button_name:
		&"action":
			_perform_action()
		&"secondary":
			_perform_secondary_action()
		_:
			if enable_debug_mode:
				print("Footer button pressed: " + button_name)

# ============================================
# GAME ACTIONS
# ============================================

func _pause_game() -> void:
	"""Pause the game"""
	get_tree().paused = true
	update_status("Game Paused")

func _resume_game() -> void:
	"""Resume the game"""
	get_tree().paused = false
	update_status("Game Resumed")

func _open_settings() -> void:
	"""Open settings menu"""
	if enable_debug_mode:
		print("Opening settings...")

func _perform_action() -> void:
	"""Perform primary action"""
	if enable_debug_mode:
		print("Primary action performed")

func _perform_secondary_action() -> void:
	"""Perform secondary action"""
	if enable_debug_mode:
		print("Secondary action performed")

# ============================================
# ENTITY & SPAWN MANAGEMENT
# ============================================

func spawn_hero(hero_scene: PackedScene, position: Vector2, group: String = "Hero") -> Node:
	"""Spawn a hero at specified position"""
	if not hero_scene:
		push_error("Hero scene is null!")
		return null
	
	var hero = hero_scene.instantiate()
	hero.global_position = position
	hero.add_to_group(group)
	entities_container.add_child(hero)
	
	# Connect hero signals
	if hero.has_signal("health_changed"):
		hero.health_changed.connect(_on_hero_health_changed)
	if hero.has_signal("died"):
		hero.died.connect(_on_hero_died)
	if hero.has_signal("leveled_up"):
		hero.leveled_up.connect(_on_hero_leveled_up)
	
	if enable_debug_mode:
		print("Spawned hero: " + hero.name + " at " + str(position))
	
	return hero

func spawn_mob(mob_scene: PackedScene, position: Vector2, group: String = "Enemy") -> Node:
	"""Spawn a mob at specified position"""
	if not mob_scene:
		push_error("Mob scene is null!")
		return null
	
	var mob = mob_scene.instantiate()
	mob.global_position = position
	mob.add_to_group(group)
	entities_container.add_child(mob)
	
	# Connect mob signals
	if mob.has_signal("died"):
		mob.died.connect(_on_mob_died)
	
	if enable_debug_mode:
		print("Spawned mob: " + mob.name + " at " + str(position))
	
	return mob

func spawn_monster(monster_scene: PackedScene, position: Vector2, group: String = "Monster") -> Node:
	"""Spawn a monster at specified position"""
	if not monster_scene:
		push_error("Monster scene is null!")
		return null
	
	var monster = monster_scene.instantiate()
	monster.global_position = position
	monster.add_to_group(group)
	entities_container.add_child(monster)
	
	# Connect monster signals
	if monster.has_signal("health_changed"):
		monster.health_changed.connect(_on_monster_health_changed)
	if monster.has_signal("died"):
		monster.died.connect(_on_monster_died)
	if monster.has_signal("stage_changed"):
		monster.stage_changed.connect(_on_monster_stage_changed)
	
	if enable_debug_mode:
		print("Spawned monster: " + monster.name + " at " + str(position))
	
	return monster

# ============================================
# ENTITY SIGNAL HANDLERS
# ============================================

func _on_hero_health_changed(current: float, max_health: float) -> void:
	"""Update UI when hero health changes"""
	update_health_display(current, max_health)

func _on_hero_died() -> void:
	"""Handle hero death - lose condition"""
	update_status("Hero defeated!")
	await get_tree().create_timer(1.0).timeout
	end_game(false)

func _on_hero_leveled_up(level: int, xp: float) -> void:
	"""Handle hero level up"""
	add_score(50) # Bonus points for leveling
	update_status("Leveled up to " + str(level) + "!")

func _on_mob_died() -> void:
	"""Handle mob death"""
	add_score(10)

func _on_monster_health_changed(current: float, max_health: float) -> void:
	"""Update UI when monster health changes"""
	update_health_display(current, max_health)

func _on_monster_died() -> void:
	"""Handle monster death - win condition"""
	add_score(500) # Large bonus for defeating boss
	update_status("Victory! Defeated the monster!")
	await get_tree().create_timer(1.0).timeout
	end_game(true)

func _on_monster_stage_changed(new_stage: int, old_stage: int) -> void:
	"""Handle monster stage transition"""
	add_score(100)
	update_status("Monster advanced to Stage " + str(new_stage) + "!")
