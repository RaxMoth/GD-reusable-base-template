## Universal game state and level manager
## Handles game progression, level loading, state transitions
##
## Features:
##   - Level/scene management
##   - Game state tracking (menu, playing, paused, game over)
##   - Save/load system integration
##   - Difficulty settings
##   - Signal-based game events
##   - Easy configuration
##
## Dependencies:
##   - Global autoload
##   - Types autoload
##   - UpgradeSystem (optional)
##   - WaveSpawner (optional)

extends Node
class_name GameStateManager

# ============================================
# ENUMS
# ============================================

enum GameState {
	MENU = 0,
	LOADING = 1,
	PLAYING = 2,
	PAUSED = 3,
	GAME_OVER = 4,
	VICTORY = 5,
	QUIT = 6
}

# ============================================
# SIGNALS
# ============================================

signal game_state_changed(new_state: GameState)
signal level_started(level_name: String)
signal level_completed(level_name: String)
signal game_over(victory: bool, stats: Dictionary)
signal difficulty_changed(difficulty: String)
signal pause_state_changed(is_paused: bool)

# ============================================
# EXPORT PROPERTIES
# ============================================

@export_group("Levels")
@export var level_scenes: Dictionary = {
	"level_1": "res://Scenes/Levels/level_1.tscn",
	"tutorial": "res://Scenes/Levels/tutorial.tscn",
}
@export var starting_level: String = "tutorial"

@export_group("Game Settings")
@export var difficulty: String = "normal"
@export var allow_pause: bool = true
@export var auto_save_enabled: bool = true
@export var auto_save_interval: float = 60.0

@export_group("Difficulty Settings")
@export var difficulty_multipliers: Dictionary = {
	"easy": 0.75,
	"normal": 1.0,
	"hard": 1.5,
	"nightmare": 2.0,
}

# ============================================
# INTERNAL STATE
# ============================================

var current_state: GameState = GameState.MENU
var current_level: String = ""
var is_paused: bool = false

var game_stats: Dictionary = {
	"score": 0,
	"enemies_defeated": 0,
	"waves_completed": 0,
	"towers_built": 0,
	"time_played": 0.0,
	"health_remaining": 100.0,
}

var auto_save_timer: Timer = null

# ============================================
# LIFECYCLE
# ============================================

func _ready() -> void:
	set_process_mode(PROCESS_MODE_ALWAYS) # Continue processing during pause
	
	# Setup auto-save timer
	if auto_save_enabled:
		auto_save_timer = Timer.new()
		add_child(auto_save_timer)
		auto_save_timer.timeout.connect(_on_autosave_timer)
		auto_save_timer.start(auto_save_interval)

func _process(delta: float) -> void:
	# Update game stats
	if current_state == GameState.PLAYING:
		game_stats["time_played"] += delta

func _input(event: InputEvent) -> void:
	"""Handle global input (pause, etc.)"""
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE and allow_pause:
			toggle_pause()

# ============================================
# STATE MANAGEMENT
# ============================================

func change_game_state(new_state: GameState) -> void:
	"""Change the current game state"""
	if current_state == new_state:
		return
	
	current_state = new_state
	game_state_changed.emit(new_state)
	
	match new_state:
		GameState.MENU:
			_on_menu_state()
		GameState.PLAYING:
			_on_playing_state()
		GameState.PAUSED:
			_on_paused_state()
		GameState.GAME_OVER:
			_on_gameover_state()
		GameState.VICTORY:
			_on_victory_state()

func _on_menu_state() -> void:
	"""Enter menu state"""
	get_tree().paused = false

func _on_playing_state() -> void:
	"""Enter playing state"""
	get_tree().paused = false
	is_paused = false

func _on_paused_state() -> void:
	"""Enter paused state"""
	get_tree().paused = true
	is_paused = true

func _on_gameover_state() -> void:
	"""Enter game over state"""
	game_over.emit(false, game_stats)

func _on_victory_state() -> void:
	"""Enter victory state"""
	game_over.emit(true, game_stats)

# ============================================
# PAUSE SYSTEM
# ============================================

func toggle_pause() -> void:
	"""Toggle pause state"""
	if not allow_pause or current_state not in [GameState.PLAYING]:
		return
	
	set_pause(!is_paused)

func set_pause(paused: bool) -> void:
	"""Set pause state"""
	is_paused = paused
	get_tree().paused = paused
	pause_state_changed.emit(paused)

# ============================================
# LEVEL MANAGEMENT
# ============================================

func load_level(level_name: String) -> void:
	"""Load a level by name"""
	if not level_scenes.has(level_name):
		push_error("Level not found: %s" % level_name)
		return
	
	current_level = level_name
	change_game_state(GameState.LOADING)
	
	# Load the scene
	var scene_path = level_scenes[level_name]
	await get_tree().process_frame
	
	get_tree().change_scene_to_file(scene_path)
	change_game_state(GameState.PLAYING)
	level_started.emit(level_name)

func start_game() -> void:
	"""Start the game from menu"""
	load_level(starting_level)

func restart_level() -> void:
	"""Restart current level"""
	if current_level.is_empty():
		start_game()
	else:
		load_level(current_level)

func next_level() -> void:
	"""Load next level in sequence"""
	var level_keys = level_scenes.keys()
	var current_index = level_keys.find(current_level)
	
	if current_index >= 0 and current_index < level_keys.size() - 1:
		load_level(level_keys[current_index + 1])
	else:
		# Last level complete
		change_game_state(GameState.VICTORY)

func level_complete() -> void:
	"""Mark current level as complete"""
	level_completed.emit(current_level)
	game_stats["waves_completed"] += 1

# ============================================
# DIFFICULTY SYSTEM
# ============================================

func set_difficulty(new_difficulty: String) -> void:
	"""Set game difficulty"""
	if new_difficulty in difficulty_multipliers:
		difficulty = new_difficulty
		difficulty_changed.emit(new_difficulty)

func get_difficulty_multiplier() -> float:
	"""Get stat multiplier for current difficulty"""
	return difficulty_multipliers.get(difficulty, 1.0)

# ============================================
# STATS & SCORING
# ============================================

func add_score(points: int) -> void:
	"""Add score"""
	game_stats["score"] += points

func increment_enemies_defeated() -> void:
	"""Increment enemy defeat counter"""
	game_stats["enemies_defeated"] += 1

func update_health_remaining(health: float, max_health: float) -> void:
	"""Update remaining health display"""
	game_stats["health_remaining"] = (health / max_health) * 100.0

func get_game_stats() -> Dictionary:
	"""Get current game statistics"""
	return game_stats.duplicate()

# ============================================
# SAVE & LOAD
# ============================================

func save_game(save_slot: int = 1) -> bool:
	"""Save game to slot"""
	var save_data = {
		"level": current_level,
		"stats": game_stats,
		"difficulty": difficulty,
		"timestamp": Time.get_ticks_msec(),
	}
	
	var save_path = "user://save_%d.json" % save_slot
	var json_str = JSON.stringify(save_data)
	
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		return true
	return false

func load_game(save_slot: int = 1) -> bool:
	"""Load game from slot"""
	var save_path = "user://save_%d.json" % save_slot
	
	if not FileAccess.file_exists(save_path):
		return false
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file:
		var json_str = file.get_as_text()
		var json = JSON.new()
		if json.parse(json_str) == OK:
			var save_data = json.data
			current_level = save_data.get("level", "")
			game_stats = save_data.get("stats", {})
			difficulty = save_data.get("difficulty", "normal")
			return true
	return false

func _on_autosave_timer() -> void:
	"""Auto-save periodically"""
	if current_state == GameState.PLAYING:
		save_game(0) # Slot 0 for auto-save

# ============================================
# HELPER METHODS
# ============================================

func quit_game() -> void:
	"""Quit to main menu"""
	change_game_state(GameState.QUIT)
	get_tree().change_scene_to_file("res://Scenes/UI/main_menu.tscn")

func exit_to_desktop() -> void:
	"""Exit application"""
	get_tree().quit()

func get_current_state() -> GameState:
	"""Get current game state"""
	return current_state

func is_game_running() -> bool:
	"""Check if game is actively running"""
	return current_state == GameState.PLAYING and not is_paused
