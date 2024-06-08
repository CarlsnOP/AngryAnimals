extends RigidBody2D

#Different states for the animal. If frozen and ready for input, if it is being dragged or is released.
enum ANIMAL_STATE { READY, DRAG, RELEASE }

#sets boundries of where and how far you can drag the bird
const DRAG_LIM_MAX: Vector2 = Vector2(0, 60)
const DRAG_LIM_MIN: Vector2 = Vector2(-60, 0)

@onready var label = $Label
@onready var stretch_sound = $StretchSound
@onready var arrow = $Arrow

#sets parameters for 3 states to 0
var _start: Vector2 = Vector2.ZERO
var _drag_start: Vector2 = Vector2.ZERO
var _dragged_vector: Vector2 = Vector2.ZERO
var _last_dragged_vector: Vector2 = Vector2.ZERO

#Set the state as ready
var _state: ANIMAL_STATE = ANIMAL_STATE.READY

# Called when the node enters the scene tree for the first time.
func _ready():
	arrow.hide()
	_start = position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	update(delta)
	label.text = "%s\n" % ANIMAL_STATE.keys()[_state]
	label.text += "%.1f,%.1f" % [_dragged_vector.x, _dragged_vector.y]

#If animal is in RELEASE state, we unfreeze it - if it is in DRAG state we set _drag_start to mouse position
#shows arrow when animal state is in drage, hides it when released
func set_new_state(new_state: ANIMAL_STATE) -> void:
	_state = new_state
	if _state == ANIMAL_STATE.RELEASE:
		arrow.hide()
		freeze = false
	elif _state == ANIMAL_STATE.DRAG:
		_drag_start = get_global_mouse_position()
		arrow.show()

#rotates arrow arround the animal
func scale_arrow() -> void:
	arrow.rotation = (_start - position).angle()

#plays sound when mouse is moved and if sound is not already playing
func play_stretch_sound() -> void:
	if(_last_dragged_vector - _dragged_vector).length() > 0:
		if stretch_sound.playing == false:
			stretch_sound.play()

#we calculate how far we dragged the animal based on mouse position minus where we clicked to begin with
func get_dragged_vector(gmp: Vector2) -> Vector2:
	return gmp - _drag_start

#Setting the limit for where and how far we can drag the animal
func drag_in_limits() -> void:
	_last_dragged_vector = _dragged_vector
	_dragged_vector.x = clampf(
		_dragged_vector.x,
		DRAG_LIM_MIN.x,
		DRAG_LIM_MAX.x
	)
	_dragged_vector.y = clampf(
		_dragged_vector.y,
		DRAG_LIM_MIN.y,
		DRAG_LIM_MAX.y
	)
	position = _start + _dragged_vector

#When animal leaves screen, start function die()
func _on_visible_on_screen_notifier_2d_screen_exited():
	die()

#Emits a signal to Signal manager that our animal died and then removes it from the game with queue_free()
func die() -> void:
	SignalManager.on_animal_died.emit()
	queue_free()

#When clicked, animal state changes from READY to DRAG
func _on_input_event(viewport, event: InputEvent, shape_idx):
	if _state == ANIMAL_STATE.READY and event.is_action_pressed("drag"):
		set_new_state(ANIMAL_STATE.DRAG)

#If Animal state is DRAG we do activate funtion update_drag()
func update(delta: float) -> void:
	match _state:
		ANIMAL_STATE.DRAG:
			update_drag()

#We detect if mouse button has been released, we then change state to RELEASE
func detect_release() -> bool:
	if _state == ANIMAL_STATE.DRAG:
		if Input.is_action_just_released("drag") == true:
			set_new_state(ANIMAL_STATE.RELEASE)
			return true
	return false

#We set GMP to global mouse position when mouse button is released
func update_drag() -> void:
	if detect_release() == true:
		return
	var gmp = get_global_mouse_position()
	_dragged_vector = get_dragged_vector(gmp)
	play_stretch_sound()
	drag_in_limits()
	scale_arrow()
