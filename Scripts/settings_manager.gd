## Universal settings and configuration system
## Manages game settings, preferences, and audio
##
## Features:
##   - Persistent settings storage
##   - Audio control (master, sfx, music)
##   - Graphics settings
##   - Gameplay preferences
##   - Signal-based updates
##   - Easy integration with UI
##
## Dependencies:
##   - Global autoload

extends Resource
class_name SettingsManager

# ============================================
# SIGNALS
# ============================================

signal setting_changed(key: String, value: Variant)
signal master_volume_changed(volume: float)
signal music_volume_changed(volume: float)
signal sfx_volume_changed(volume: float)
signal graphics_setting_changed(setting: String, value: Variant)
signal language_changed(language: String)

# ============================================
# EXPORT PROPERTIES - AUDIO
# ============================================

@export_group("Audio")
@export var master_volume: float = 1.0
@export var music_volume: float = 0.8
@export var sfx_volume: float = 0.8
@export var voice_volume: float = 0.8
@export var mute_on_pause: bool = true

@export_group("Graphics")
@export var fullscreen: bool = false
@export var vsync_enabled: bool = true
@export var fps_cap: int = 60
@export var particle_quality: String = "high" # low, medium, high
@export var shadow_quality: String = "medium"
@export var screen_shake_enabled: bool = true
@export var camera_smoothing: float = 0.8

@export_group("Gameplay")
@export var difficulty: String = "normal"
@export var show_tutorials: bool = true
@export var auto_aim: bool = false
@export var camera_lock: bool = false
@export var haptic_feedback: bool = true # Mobile vibration

@export_group("Accessibility")
@export var language: String = "en"
@export var colorblind_mode: String = "off" # off, deuteranopia, protanopia, tritanopia
@export var text_scale: float = 1.0
@export var screen_reader_enabled: bool = false
@export var high_contrast_ui: bool = false
@export var show_subtitles: bool = true

# ============================================
# INTERNAL STATE
# ============================================

var audio_buses: Dictionary = {}
var quality_presets: Dictionary = {
	"low": {
		"particle_quality": "low",
		"shadow_quality": "low",
		"fps_cap": 30,
	},
	"medium": {
		"particle_quality": "medium",
		"shadow_quality": "medium",
		"fps_cap": 60,
	},
	"high": {
		"particle_quality": "high",
		"shadow_quality": "high",
		"fps_cap": 144,
	},
}

# ============================================
# LIFECYCLE
# ============================================

func _init() -> void:
	_setup_audio_buses()
	_apply_settings()

# ============================================
# AUDIO SETTINGS
# ============================================

func set_master_volume(volume: float) -> void:
	"""Set master volume (0-1)"""
	master_volume = clamp(volume, 0.0, 1.0)
	_update_audio_bus_volume("Master", master_volume)
	master_volume_changed.emit(master_volume)
	setting_changed.emit("master_volume", master_volume)

func set_music_volume(volume: float) -> void:
	"""Set music volume (0-1)"""
	music_volume = clamp(volume, 0.0, 1.0)
	_update_audio_bus_volume("Music", music_volume * master_volume)
	music_volume_changed.emit(music_volume)
	setting_changed.emit("music_volume", music_volume)

func set_sfx_volume(volume: float) -> void:
	"""Set SFX volume (0-1)"""
	sfx_volume = clamp(volume, 0.0, 1.0)
	_update_audio_bus_volume("SFX", sfx_volume * master_volume)
	sfx_volume_changed.emit(sfx_volume)
	setting_changed.emit("sfx_volume", sfx_volume)

func set_voice_volume(volume: float) -> void:
	"""Set voice volume (0-1)"""
	voice_volume = clamp(volume, 0.0, 1.0)
	_update_audio_bus_volume("Voice", voice_volume * master_volume)
	setting_changed.emit("voice_volume", voice_volume)

func _setup_audio_buses() -> void:
	"""Setup audio bus references"""
	audio_buses = {
		"Master": AudioServer.get_bus_index("Master"),
		"Music": AudioServer.get_bus_index("Music"),
		"SFX": AudioServer.get_bus_index("SFX"),
		"Voice": AudioServer.get_bus_index("Voice"),
	}

func _update_audio_bus_volume(bus_name: String, volume: float) -> void:
	"""Update audio bus volume"""
	if bus_name in audio_buses:
		var bus_idx = audio_buses[bus_name]
		if bus_idx >= 0:
			AudioServer.set_bus_volume_db(bus_idx, linear2db(volume))

# ============================================
# GRAPHICS SETTINGS
# ============================================

func set_fullscreen(enabled: bool) -> void:
	"""Set fullscreen mode"""
	fullscreen = enabled
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	graphics_setting_changed.emit("fullscreen", enabled)
	setting_changed.emit("fullscreen", enabled)

func set_vsync(enabled: bool) -> void:
	"""Set vsync"""
	vsync_enabled = enabled
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if enabled else DisplayServer.VSYNC_DISABLED)
	graphics_setting_changed.emit("vsync", enabled)
	setting_changed.emit("vsync_enabled", enabled)

func set_fps_cap(fps: int) -> void:
	"""Set FPS cap"""
	fps_cap = max(30, fps)
	Engine.max_fps = fps_cap
	graphics_setting_changed.emit("fps_cap", fps_cap)
	setting_changed.emit("fps_cap", fps_cap)

func set_quality_preset(preset: String) -> void:
	"""Apply quality preset"""
	if preset in quality_presets:
		var settings = quality_presets[preset]
		for key in settings:
			if key == "particle_quality":
				particle_quality = settings[key]
			elif key == "shadow_quality":
				shadow_quality = settings[key]
			elif key == "fps_cap":
				set_fps_cap(settings[key])
		graphics_setting_changed.emit("quality_preset", preset)

func set_particle_quality(quality: String) -> void:
	"""Set particle effect quality"""
	if quality in ["low", "medium", "high"]:
		particle_quality = quality
		graphics_setting_changed.emit("particle_quality", quality)
		setting_changed.emit("particle_quality", quality)

func set_screen_shake(enabled: bool) -> void:
	"""Enable/disable screen shake"""
	screen_shake_enabled = enabled
	graphics_setting_changed.emit("screen_shake", enabled)
	setting_changed.emit("screen_shake_enabled", enabled)

# ============================================
# GAMEPLAY SETTINGS
# ============================================

func set_difficulty(difficulty_level: String) -> void:
	"""Set game difficulty"""
	if difficulty_level in ["easy", "normal", "hard", "nightmare"]:
		difficulty = difficulty_level
		setting_changed.emit("difficulty", difficulty_level)

func set_show_tutorials(show: bool) -> void:
	"""Toggle tutorial display"""
	show_tutorials = show
	setting_changed.emit("show_tutorials", show)

func set_auto_aim(enabled: bool) -> void:
	"""Enable/disable auto-aim"""
	auto_aim = enabled
	setting_changed.emit("auto_aim", enabled)

# ============================================
# ACCESSIBILITY SETTINGS
# ============================================

func set_language(lang: String) -> void:
	"""Set language"""
	language = lang
	language_changed.emit(lang)
	setting_changed.emit("language", lang)

func set_text_scale(scale: float) -> void:
	"""Set UI text scale"""
	text_scale = clamp(scale, 0.5, 2.0)
	setting_changed.emit("text_scale", text_scale)

func set_colorblind_mode(mode: String) -> void:
	"""Set colorblind filter mode"""
	if mode in ["off", "deuteranopia", "protanopia", "tritanopia"]:
		colorblind_mode = mode
		setting_changed.emit("colorblind_mode", mode)

func set_high_contrast(enabled: bool) -> void:
	"""Toggle high contrast UI"""
	high_contrast_ui = enabled
	setting_changed.emit("high_contrast_ui", enabled)

func set_subtitles(enabled: bool) -> void:
	"""Toggle subtitle display"""
	show_subtitles = enabled
	setting_changed.emit("show_subtitles", enabled)

# ============================================
# PERSISTENCE
# ============================================

func save_settings() -> bool:
	"""Save settings to file"""
	var save_data = {
		"audio": {
			"master_volume": master_volume,
			"music_volume": music_volume,
			"sfx_volume": sfx_volume,
			"voice_volume": voice_volume,
		},
		"graphics": {
			"fullscreen": fullscreen,
			"vsync_enabled": vsync_enabled,
			"fps_cap": fps_cap,
			"particle_quality": particle_quality,
		},
		"gameplay": {
			"difficulty": difficulty,
			"show_tutorials": show_tutorials,
			"auto_aim": auto_aim,
		},
		"accessibility": {
			"language": language,
			"text_scale": text_scale,
			"colorblind_mode": colorblind_mode,
		},
	}
	
	var settings_path = "user://settings.json"
	var json_str = JSON.stringify(save_data)
	
	var file = FileAccess.open(settings_path, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		return true
	return false

func load_settings() -> bool:
	"""Load settings from file"""
	var settings_path = "user://settings.json"
	
	if not FileAccess.file_exists(settings_path):
		return false
	
	var file = FileAccess.open(settings_path, FileAccess.READ)
	if file:
		var json_str = file.get_as_text()
		var json = JSON.new()
		if json.parse(json_str) == OK:
			var save_data = json.data
			
			# Load audio settings
			if "audio" in save_data:
				var audio = save_data["audio"]
				if "master_volume" in audio:
					set_master_volume(audio["master_volume"])
				if "music_volume" in audio:
					set_music_volume(audio["music_volume"])
				if "sfx_volume" in audio:
					set_sfx_volume(audio["sfx_volume"])
			
			# Load graphics settings
			if "graphics" in save_data:
				var graphics = save_data["graphics"]
				if "fullscreen" in graphics:
					set_fullscreen(graphics["fullscreen"])
				if "fps_cap" in graphics:
					set_fps_cap(graphics["fps_cap"])
			
			# Load gameplay settings
			if "gameplay" in save_data:
				var gameplay = save_data["gameplay"]
				if "difficulty" in gameplay:
					set_difficulty(gameplay["difficulty"])
			
			return true
	return false

# ============================================
# APPLICATION OF SETTINGS
# ============================================

func _apply_settings() -> void:
	"""Apply all current settings to engine"""
	set_master_volume(master_volume)
	set_music_volume(music_volume)
	set_sfx_volume(sfx_volume)
	set_fps_cap(fps_cap)
	set_vsync(vsync_enabled)
	
	# Load saved settings
	load_settings()

# ============================================
# RESET & DEFAULTS
# ============================================

func reset_to_defaults() -> void:
	"""Reset all settings to defaults"""
	set_master_volume(1.0)
	set_music_volume(0.8)
	set_sfx_volume(0.8)
	set_voice_volume(0.8)
	set_fullscreen(false)
	set_fps_cap(60)
	set_difficulty("normal")
	language = "en"
	text_scale = 1.0
	colorblind_mode = "off"

# ============================================
# HELPER METHODS
# ============================================

func get_setting(key: String) -> Variant:
	"""Get setting value by key"""
	if key in self:
		return self [key]
	return null

func get_effective_volume(bus: String) -> float:
	"""Get effective volume for audio bus"""
	match bus:
		"Music":
			return music_volume * master_volume
		"SFX":
			return sfx_volume * master_volume
		"Voice":
			return voice_volume * master_volume
		_:
			return master_volume
