# Agent Instructor — Godot Mobile Game Base Template

## Project Overview

This is a **Godot 4.5** reusable base template targeting **mobile games exclusively**. The rendering method is `mobile` (GL Compatibility). The viewport is `720×1280` (portrait-first). Every architectural decision must reflect that this will run on low-to-mid-range Android and iOS devices.

This is not a prototype. This is a production-quality, scalable, and maintainable template. There are no shortcuts, no quick hacks, no throwaway variables. Every system must be designed to be extended cleanly by future developers.

---

## Project Structure

```
res://
├── Assets/          # Textures, audio, fonts, animations (read-only at runtime)
├── Globals/         # Autoloads only — Types and Global
├── Ressources/      # .tres / .res custom resources (data containers)
├── Scenes/          # Scene tree (.tscn) organized by domain
│   ├── NPCs/
│   │   ├── Hero/
│   │   ├── Mobs/
│   │   └── Monster/
│   └── World/
├── Scripts/         # Standalone .gd scripts not attached to a scene node
└── addons/
    └── godot_state_charts/   # State chart library — always use this for state management
```

Respect the folder color-coding enforced in `project.godot`. Never place files in the wrong directory.

---

## Core Principles — Non-Negotiable

### 1. Mobile First, Mobile Only
- Target 60 FPS on mid-range devices (Snapdragon 7xx equivalent).
- Never use heavy 3D techniques, complex shaders, or CPU-heavy algorithms.
- All UI must be designed for **touch input** — minimum touch target size is 48×48 dp.
- Use `CanvasLayer` for all HUD and UI elements so they are independent from the game camera.
- UI must use **anchors and containers** (`VBoxContainer`, `HBoxContainer`, `MarginContainer`, `AspectRatioContainer`) — never hardcoded pixel positions.
- Test and design layouts for both tall (19:9) and short (16:9) aspect ratios using `AspectRatioContainer` where necessary.

### 2. Signals over Direct References
- Nodes must communicate through **signals**, not direct `get_node()` calls or `$` shortcuts.
- Every signal must have an explicit type annotation in its declaration:
  ```gdscript
  signal health_changed(new_health: int, max_health: int)
  signal enemy_died(enemy_id: StringName)
  ```
- Use `connect()` in code only when the connection must be dynamic. For static connections, use the Godot editor signal dock.
- Never use `call_group()` as a fire-and-forget — prefer typed signals with explicit receivers.

### 3. State Management via godot_state_charts
- **All entity state** (NPCs, Hero, UI screens, game flow) must be managed through the `godot_state_charts` addon. No hand-rolled state machines.
- Every entity that has behavior states must have a `StateChart` node as a child.
- Use `CompoundState` for hierarchical state nesting (e.g., `Alive > { Idle, Moving, Attacking }`).
- Use `ParallelState` when two independent state dimensions must coexist (e.g., `Movement` and `Combat` running simultaneously).
- Use `AtomicState` for leaf states that contain the actual behavior logic.
- Use `Transition` nodes with guards and events — never call `send_event()` with magic strings scattered across the codebase. Define all event names as `StringName` constants in the relevant class or in `Types`.
- Connect state signals (`state_entered`, `state_exited`, `state_processing`, `state_physics_processing`) to the owning script's methods. Use `state_physics_processing` for movement/physics, `state_processing` only for non-physics logic.

### 4. Typed GDScript — No Exceptions
- Every variable, parameter, and return type must be **explicitly typed**:
  ```gdscript
  # Correct
  var movement_speed: float = 300.0
  func apply_damage(damage_amount: int) -> void:

  # Wrong — never do this
  var speed = 300
  func apply_damage(dmg):
  ```
- Never use `var x`, `var i`, `var n`, or any single-letter or abbreviated variable names.
- Names must be descriptive and self-documenting. A future developer must understand the purpose of a variable without a comment:
  ```gdscript
  # Wrong
  var hp := 100
  var spd := 5.0

  # Correct
  var current_health: int = 100
  var base_movement_speed: float = 5.0
  ```
- Use `@export` annotations for all designer-facing values with meaningful groupings using `@export_group` and `@export_subgroup`.
- Use `const` for compile-time constants and `static var` for class-level shared state when truly needed.

### 5. Resource-Driven Data (No Hardcoding)
- Game data (stats, configuration, tuning) must live in **custom Resource classes** (`.tres` files under `res://Ressources/`).
- Define resource schemas in `Scripts/` as `class_name SomeDataResource extends Resource`.
- The Hero, Mobs, and Monsters must each have a corresponding data resource that can be swapped in the editor — not constants baked into scripts.
- Use `@export` on resource properties so designers can tune values in the Godot editor without touching code.

### 6. Autoloads — Minimal and Purposeful
Two autoloads exist and their scope must remain tightly controlled:

**`Global` (`res://Globals/global.gd`)** — Runtime utility singleton.
- Allowed: scene-tree traversal helpers, group queries, geometry utilities.
- Not allowed: game state, player data, or anything that could be a signal or a resource.
- All functions must be stateless helpers. Global must not hold mutable game state.

**`Types` (`res://Globals/types.gd`)** — Enums, constants, and `StringName` event name definitions.
- Define all game-wide enums here (entity types, damage types, game states, etc.).
- Define all `StateChart` event name constants here as `StringName`:
  ```gdscript
  const EVENT_ENEMY_SPOTTED: StringName = &"enemy_spotted"
  const EVENT_PLAYER_DIED: StringName = &"player_died"
  const EVENT_ATTACK_TRIGGERED: StringName = &"attack_triggered"
  ```
- Never define magic string events inline in scenes or scripts.

Do not add new autoloads without a documented architectural reason.

---

## Scene and Script Architecture

### Base Class Pattern
Each entity category has a base class scene and script. Concrete entities extend these.

```
Scenes/NPCs/NPCBaseClass.tscn          ← Abstract base (not instantiated directly)
Scenes/NPCs/Hero/HeroBaseClass.tscn    ← Extends NPC base for the player
Scenes/NPCs/Mobs/MobsBaseClass.tscn   ← Extends NPC base for generic mobs
Scenes/NPCs/Monster/MonsterBaseClass.tscn ← Extends NPC base for boss/special enemies
```

- Base class scripts define the **interface** (signals, virtual methods, exported properties).
- Concrete class scripts override virtual methods and fill in specific behavior.
- Use `## @virtual` doc comments on methods intended to be overridden.
- Virtual methods in GDScript must call `super()` explicitly where appropriate.

### Node Composition Rules
- Prefer **composition over inheritance** when adding features to an entity.
- A complex entity (e.g., Hero) is composed of sub-nodes, each responsible for one system: movement, combat, animation, input.
- Each sub-node component communicates with the parent via **signals upward** and **method calls downward**.
- Never let a child node reach up to its parent via `get_parent()` — emit a signal and let the parent connect.

### StateChart Integration per Entity

Every `NPCBaseClass`, `HeroBaseClass`, `MobsBaseClass`, and `MonsterBaseClass` scene **must** include:
```
EntityRoot (Node2D)
├── AnimatedSprite2D
├── CollisionShape2D (inside Area2D or CharacterBody2D as appropriate)
└── StateChart
    └── RootCompoundState
        ├── AliveState (CompoundState)
        │   ├── IdleState (AtomicState)
        │   ├── MovingState (AtomicState)
        │   └── AttackingState (AtomicState)
        └── DeadState (AtomicState)
```

Transitions between states must be defined as child `Transition` nodes with `event` set to a constant from `Types`.

---

## Performance Rules

### Physics and Processing
- All physics logic (movement, collision response) must live in `state_physics_processing` callbacks — **never** in `_process()`.
- Use `state_processing` only for non-physics state logic (timers, UI updates, animation triggers).
- Prefer `CharacterBody2D` over `RigidBody2D` for player-controlled and AI-controlled entities.
- Use `Area2D` for trigger detection (aggro ranges, item pickups, damage zones) — not `CharacterBody2D` overlap callbacks.

### Object Pooling
- Frequently spawned objects (projectiles, particle bursts, damage numbers) **must** use an object pool.
- Implement a generic `ObjectPool` class in `Scripts/` that manages pre-allocation and recycling.
- Never instantiate and `queue_free()` in a hot path (per-frame or per-shot).

### Draw Calls and Batching
- Sprites belonging to the same entity should share a texture atlas (SpriteFrames referencing an atlas).
- UI elements in the same `CanvasLayer` should use the same `Theme` resource to enable batching.
- Avoid `SubViewport` unless strictly necessary — they are expensive on mobile.

### Memory
- Use `Resource` caching: load resources once with `preload()` at script load time for assets guaranteed to exist.
- Use `load()` only for optional or runtime-determined assets. Always check for `null`.
- Release unused resources explicitly when transitioning between major game states (levels, menus).

---

## UI and HUD Architecture

### Responsiveness
- All UI scenes must use `Control` nodes with anchors configured for the full-screen safe area.
- Use `%PercentageContainer` patterns or `AspectRatioContainer` to keep UI proportional across screen sizes.
- Font sizes must be defined in a shared `Theme` resource — never hardcoded in individual nodes.
- Never use pixel-perfect layouts that assume a fixed resolution.

### Touch Input
- All interactive UI elements must have touch-appropriate hit areas.
- Use `BaseButton` subclasses (`Button`, `TextureButton`) — never roll custom input detection on non-button nodes for UI interactions.
- Mobile-specific: respond to `_input()` touch events for game-world interactions (tap to move, drag gestures). Do not rely on mouse events.

### Separation of Concerns
- Game HUD lives in `Scenes/UI/HUD/`.
- Menus (main menu, pause, settings) live in `Scenes/UI/Menus/`.
- HUD components emit signals when the player interacts — they never directly call game logic.

---

## Code Style and Documentation

### File Header
Every `.gd` script must begin with a doc comment describing purpose, signals, and dependencies:
```gdscript
## NPC base class providing shared state chart integration, animation bindings,
## and signal interface for all non-player characters.
##
## Signals:
##   died(entity_id: StringName) — emitted when the entity reaches zero health
##   state_changed(new_state_name: StringName) — emitted on every state transition
##
## Dependencies:
##   - Types autoload (event name constants)
##   - godot_state_charts addon
```

### Naming Conventions
| Element | Convention | Example |
|---|---|---|
| Script class | PascalCase | `class_name EnemyBaseController` |
| Variables | snake_case, descriptive | `current_movement_direction` |
| Constants | SCREAMING_SNAKE_CASE | `MAX_ENEMY_AGGRO_RANGE` |
| Signals | snake_case, past tense | `health_depleted`, `target_acquired` |
| Functions | snake_case, verb-first | `calculate_damage_reduction()` |
| State event names | StringName, SCREAMING_SNAKE | `&"ATTACK_TRIGGERED"` defined in Types |
| Scene files | PascalCase | `HeroBaseClass.tscn` |
| Script files | snake_case | `hero_base_class.gd` |

### Comments
- Public API (signals, exported vars, public methods) must have `##` doc comments.
- Non-obvious logic must have `#` inline comments explaining **why**, not what.
- Never leave `TODO` comments without an associated issue or a name.

---

## What the Agent Must Never Do

- **Never** use `$NodeName` shorthand in scripts — use `@onready var node_reference: NodeType = %UniqueNodeName` with unique names enabled in the scene.
- **Never** use `get_node("/root/SomeSingleton")` — use the registered autoload names (`Global`, `Types`) directly.
- **Never** hardcode strings for state event names — always reference `Types.EVENT_*` constants.
- **Never** put game logic inside the `Global` autoload.
- **Never** skip static typing, even for loop variables: `for enemy: EnemyBaseController in active_enemies:`.
- **Never** use `set_process(true/false)` manually — `godot_state_charts` handles processing toggling automatically based on state activity.
- **Never** create new autoloads for systems that could be a `Resource`, a `Node` in the scene tree, or a signal chain.
- **Never** place `.gd` files in `Scenes/` that aren't directly attached to a `.tscn` in the same subfolder.
- **Never** build a hand-rolled state machine when `godot_state_charts` can and should be used.
- **Never** design for mouse/keyboard first — touch is the primary input device.

---

## Checklist Before Committing Any Change

- [ ] All new variables have explicit types and descriptive names
- [ ] All new signals have typed parameters
- [ ] Entity state transitions go through the StateChart with event constants from `Types`
- [ ] No direct node references that bypass the signal pattern
- [ ] UI layouts use anchors/containers — no hardcoded positions
- [ ] New assets are referenced via `preload()` at the top of the script
- [ ] Physics logic is in `state_physics_processing`, not `_process()`
- [ ] Frequently spawned objects go through an object pool
- [ ] New data/configuration lives in a `.tres` resource, not in script constants
- [ ] Doc comments are written for all public API
