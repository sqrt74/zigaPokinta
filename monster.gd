@tool
extends CharacterBody2D


@export_group("Videz")

@export_range(20.0, 99150.0, 1.0) var monster_width: float = 55.0:
	set(value):
		monster_width = value
		_update_monster()

@export_range(20.0, 99150.0, 1.0) var monster_height: float = 50.0:
	set(value):
		monster_height = value
		_update_monster()

@export var monster_color: Color = Color("63b84f"):
	set(value):
		monster_color = value
		queue_redraw()


@export_group("Premikanje")

@export_range(10.0, 500.0, 1.0) var movement_speed: float = 100.0

# Oddaljenost od začetnega položaja v obe smeri.
@export_range(20.0, 1000.0, 1.0) var patrol_distance: float = 200.0


@export_group("Skok na glavo")

@export_range(50.0, 1000.0, 1.0) var player_bounce: float = 450.0

@export_range(0.1, 3.0, 0.1) var death_time: float = 0.35

@export_range(0.0, 5.0, 0.1) var restart_delay: float = 0.5


var gravity: float = ProjectSettings.get_setting(
	"physics/2d/default_gravity"
)

var direction: float = 1.0
var start_x: float
var monster_dead: bool = false
var player_dead: bool = false


func _ready() -> void:
	_update_monster()
	queue_redraw()
	

	if Engine.is_editor_hint():
		return

	start_x = global_position.x

	$StompArea.body_entered.connect(
		_on_stomp_area_entered
	)

	$DangerArea.body_entered.connect(
		_on_danger_area_entered
	)

	$GroundCheck.enabled = true
	
func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or monster_dead:
		return

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	velocity.x = direction * movement_speed

	_update_ground_check()

	move_and_slide()

	# Obrne se ob steni.
	if is_on_wall():
		_change_direction()

	# Obrne se pred robom platforme.
	if is_on_floor() and not $GroundCheck.is_colliding():
		_change_direction()

	# Ne gre dlje od določene razdalje.
	if global_position.x >= start_x + patrol_distance:
		direction = -1.0

	if global_position.x <= start_x - patrol_distance:
		direction = 1.0

	queue_redraw()


func _update_ground_check() -> void:
	var ground_check := get_node_or_null(
		"GroundCheck"
	) as RayCast2D

	if ground_check == null:
		return

	ground_check.position = Vector2(
		direction * (monster_width / 2.0 + 6.0),
		0
	)

	ground_check.target_position = Vector2(
		0,
		monster_height / 2.0 + 18.0
	)

	ground_check.force_raycast_update()


func _change_direction() -> void:
	direction *= -1.0
	velocity.x = direction * movement_speed

func _on_stomp_area_entered(body: Node2D) -> void:
	if monster_dead or player_dead:
		return

	# Pošast ne sme zaznati same sebe.
	if body == self:
		return

	if not body is CharacterBody2D:
		return

	if not body.is_in_group("player"):
		return

	var player := body as CharacterBody2D

	if player.global_position.y < global_position.y:
		_kill_monster(player)
		
func _on_danger_area_entered(body: Node2D) -> void:
	if monster_dead or player_dead:
		return

	if body == self:
		return

	if not body is CharacterBody2D:
		return

	if not body.is_in_group("player"):
		return

	var player := body as CharacterBody2D

	_resolve_danger_touch.call_deferred(player)


func _resolve_danger_touch(
	player: CharacterBody2D
) -> void:
	if monster_dead or player_dead:
		return

	if not is_instance_valid(player):
		return

	# Tudi če je igralec zaradi hitrega padca preskočil
	# signal StompArea, položaj nad pošastjo šteje kot skok.
	var stomp_height := (
		global_position.y
		- monster_height * 0.25
	)

	if player.global_position.y < stomp_height:
		_kill_monster(player)
	else:
		_kill_player(player)

func _kill_monster(
	player: CharacterBody2D
) -> void:
	if monster_dead:
		return

	monster_dead = true
	velocity = Vector2.ZERO

	# Igralec se po skoku odbije navzgor.
	player.velocity.y = -player_bounce

	var body_collision := get_node_or_null(
		"CollisionShape2D"
	) as CollisionShape2D

	var stomp_collision := get_node_or_null(
		"StompArea/CollisionShape2D"
	) as CollisionShape2D

	var danger_collision := get_node_or_null(
		"DangerArea/CollisionShape2D"
	) as CollisionShape2D

	if body_collision != null:
		body_collision.set_deferred(
			"disabled",
			true
		)

	if stomp_collision != null:
		stomp_collision.set_deferred(
			"disabled",
			true
		)

	if danger_collision != null:
		danger_collision.set_deferred(
			"disabled",
			true
		)

	var tween := create_tween()
	tween.set_parallel(true)

	# Pošast se splošči.
	tween.tween_property(
		self,
		"scale",
		Vector2(1.3, 0.1),
		death_time
	)

	# Pošast zbledi.
	tween.tween_property(
		self,
		"modulate:a",
		0.0,
		death_time
	)

	await tween.finished

	queue_free()
	
func _kill_player(player: CharacterBody2D) -> void:
	if player_dead or monster_dead:
		return

	if not is_instance_valid(player):
		return

	player_dead = true
	velocity = Vector2.ZERO

	if player.has_method("die_instantly"):
		player.die_instantly()

func _update_monster() -> void:
	var body_collision := get_node_or_null(
		"CollisionShape2D"
	) as CollisionShape2D

	var stomp_collision := get_node_or_null(
		"StompArea/CollisionShape2D"
	) as CollisionShape2D

	var danger_collision := get_node_or_null(
		"DangerArea/CollisionShape2D"
	) as CollisionShape2D

	if (
		body_collision == null
		or stomp_collision == null
		or danger_collision == null
	):
		return

	# Glavni fizični trk pošasti.
	var body_shape := RectangleShape2D.new()
	body_shape.size = Vector2(
		monster_width,
		monster_height
	)

	body_collision.shape = body_shape

	# Območje nad glavo.
	# Sega nekoliko nad fizični trk, zato ga igralec
	# zazna še preden zadene telo pošasti.
	var stomp_shape := RectangleShape2D.new()
	stomp_shape.size = Vector2(
		monster_width * 0.90,
		24.0
	)

	stomp_collision.shape = stomp_shape
	stomp_collision.position = Vector2(
		0,
		-monster_height / 2.0 - 10.0
	)

	# Nevarno območje je samo v spodnjem delu telesa.
	# Z območjem nad glavo se ne prekriva.
	var danger_height := maxf(
		monster_height - 14.0,
		10.0
	)

	var danger_shape := RectangleShape2D.new()
	danger_shape.size = Vector2(
		monster_width + 8.0,
		danger_height
	)

	danger_collision.shape = danger_shape
	danger_collision.position = Vector2(
		0,
		7.0
	)

	queue_redraw()
func _draw() -> void:
	var half_width := monster_width / 2.0
	var half_height := monster_height / 2.0

	var dark_color := monster_color.darkened(0.25)
	var light_color := monster_color.lightened(0.2)

	# Telo.
	draw_rect(
		Rect2(
			-half_width,
			-half_height,
			monster_width,
			monster_height
		),
		monster_color
	)

	# Zaobljen zgornji del.
	draw_circle(
		Vector2(0, -half_height),
		half_width,
		monster_color
	)

	# Nogi.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-half_width, half_height - 5),
			Vector2(-5, half_height - 5),
			Vector2(-half_width / 2.0, half_height + 10)
		]),
		dark_color
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(5, half_height - 5),
			Vector2(half_width, half_height - 5),
			Vector2(half_width / 2.0, half_height + 10)
		]),
		dark_color
	)

	# Oči.
	var eye_y := -monster_height * 0.22
	var eye_distance := monster_width * 0.18

	draw_circle(
		Vector2(-eye_distance, eye_y),
		6.0,
		Color.WHITE
	)

	draw_circle(
		Vector2(eye_distance, eye_y),
		6.0,
		Color.WHITE
	)

	var pupil_direction := direction * 2.0

	draw_circle(
		Vector2(-eye_distance + pupil_direction, eye_y),
		2.5,
		Color("222222")
	)

	draw_circle(
		Vector2(eye_distance + pupil_direction, eye_y),
		2.5,
		Color("222222")
	)

	# Jezna usta.
	draw_line(
		Vector2(-10, 8),
		Vector2(0, 13),
		light_color,
		3.0
	)

	draw_line(
		Vector2(0, 13),
		Vector2(10, 8),
		light_color,
		3.0
	)
