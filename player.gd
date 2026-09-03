extends CharacterBody2D


signal lives_changed(current_lives: int)
signal player_died


@export_group("Premikanje")

@export var speed: float = 300.0
@export var jump_velocity: float = -600.0


@export_group("Življenja")

@export_range(1, 20, 1) var maximum_lives: int = 3
@export_range(0.1, 3.0, 0.1) var death_time: float = 0.5


var gravity: float = ProjectSettings.get_setting(
	"physics/2d/default_gravity"
)

var current_lives: int
var dead: bool = false

const GOLD_COIN: int = 0
const SILVER_COIN: int = 1


var gold_coins: int = 0
var silver_coins: int = 0

var respawn_position: Vector2
var starting_scale: Vector2
var starting_rotation: float

func _ready() -> void:
	add_to_group("player")

	current_lives = maximum_lives

	respawn_position = global_position
	starting_scale = scale
	starting_rotation = rotation

	_update_lives_display.call_deferred()
	
func _physics_process(delta: float) -> void:
	if dead:
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	if (
		Input.is_action_just_pressed("jump")
		and is_on_floor()
	):
		velocity.y = jump_velocity

	if (
		Input.is_action_just_released("jump")
		and velocity.y < 0
	):
		velocity.y *= 0.45

	var direction := Input.get_axis(
		"move_left",
		"move_right"
	)

	if direction != 0:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(
			velocity.x,
			0,
			speed * 5.0 * delta
		)

	move_and_slide()


func take_damage(amount: int = 1) -> void:
	if dead:
		return

	current_lives = maxi(
		current_lives - amount,
		0
	)

	lives_changed.emit(current_lives)
	_update_lives_display()

	# Kratek rdeč utrip ob poškodbi.
	var tween := create_tween()

	tween.tween_property(
		self,
		"modulate",
		Color("ff6666"),
		0.1
	)

	tween.tween_property(
		self,
		"modulate",
		Color.WHITE,
		0.1
	)

	if current_lives <= 0:
		die()


func die_instantly() -> void:
	if dead:
		return

	current_lives = 0
	lives_changed.emit(current_lives)
	_update_lives_display()
	die()


func die() -> void:
	if dead:
		return

	dead = true
	velocity = Vector2.ZERO
	player_died.emit()

	set_physics_process(false)

	var player_collision := get_node_or_null(
		"CollisionShape2D"
	) as CollisionShape2D

	if player_collision != null:
		player_collision.set_deferred(
			"disabled",
			true
		)

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		self,
		"scale",
		Vector2.ZERO,
		death_time
	)

	tween.tween_property(
		self,
		"rotation",
		rotation + PI,
		death_time
	)

	await tween.finished

	_respawn()	
func _update_lives_display() -> void:
	var label := get_tree().get_first_node_in_group(
		"hearts_display"
	) as Label

	if label == null:
		return

	var hearts_text := ""

	for i in range(maximum_lives):
		if i < current_lives:
			# Poln srček pomeni preostalo življenje.
			hearts_text += "♥"
		else:
			# Prazen srček pomeni izgubljeno življenje.
			hearts_text += "♡"

		if i < maximum_lives - 1:
			hearts_text += " "

	label.text = hearts_text 

func collect_coin(coin_type: int) -> void:
	match coin_type:
		GOLD_COIN:
			gold_coins += 1

		SILVER_COIN:
			silver_coins += 1


func get_gold_coins() -> int:
	return gold_coins


func get_silver_coins() -> int:
	return silver_coins


func get_total_coins() -> int:
	return gold_coins + silver_coins

func set_checkpoint(
	new_position: Vector2
) -> void:
	respawn_position = new_position
	
func _respawn() -> void:
	global_position = respawn_position

	velocity = Vector2.ZERO
	scale = starting_scale
	rotation = starting_rotation
	modulate = Color.WHITE

	current_lives = maximum_lives
	dead = false

	var player_collision := get_node_or_null(
		"CollisionShape2D"
	) as CollisionShape2D

	if player_collision != null:
		player_collision.set_deferred(
			"disabled",
			false
		)

	set_physics_process(true)
	_update_lives_display()	
