extends Node
## Combat role enumeration for entity combat behavior
enum CombatRole {
	MELEE = 0,
	RANGED = 1,
	SUPPORT = 2
}

# ============================================
# STATE CHART EVENT NAME CONSTANTS
# ============================================

const EVENT_ENEMY_SPOTTED: StringName = &"enemie_entered"
const EVENT_ENEMY_LOST: StringName = &"enemie_exited"
const EVENT_ATTACK_TRIGGERED: StringName = &"enemy_fight"
const EVENT_TARGET_LOST: StringName = &"target_lost"
const EVENT_REAPPROACH: StringName = &"re_approach"

# ============================================
# GAME STATE ENUMS
# ============================================

enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	GAME_OVER
}