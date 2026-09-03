@tool
extends StaticBody2D


@export_group("Velikost in videz")

@export_range(20.0, 1000.0, 1.0) var platform_width: float = 250.0:
	set(value):
		platform_width = value
		_update_detector()

		if not is_inside_tree():
			return

		if Engine.is_editor_hint():
			current_width = platform_width
			_update_platform()

@export_range(10.0, 200.0, 1.0) var platform_height: float = 30.0:
	set(value):
		platform_height = value
		_update_platform()
		_update_detector()

@export var platform_color: Color = Color("d95c5c"):
	set(value):
		platform_color = value
		_update_platform()


@export_group("Zmanjševanje")

@export_range(0.0, 500.0, 1.0) var minimum_width: float = 40.0

# Število pikslov na sekundo.
@export_range(1.0, 500.0, 1.0) var shrink_speed: float = 70.0

@export_range(1.0, 1000.0, 1.0) var restore_speed: float = 180.0
# Koliko sekund mora biti igralec s platforme,
# preden se ta začne povečevati.
@export_range(0.0, 30.0, 0.1) var restore_delay: float = 3.0

var current_width: float
var player_on_platform: bool = false
var time_without_player: float = 0.0

func _ready() -> void:
	current_width = platform_width

	_update_platform()
	_update_detector()

	if Engine.is_editor_hint():
		return

	$PlayerDetector.body_entered.connect(
		_on_body_entered
	)

	$PlayerDetector.body_exited.connect(
		_on_body_exited
	)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if player_on_platform:
		# Igralec je na platformi:
		# prekinemo odštevanje in zmanjšujemo platformo.
		time_without_player = 0.0

		var target_width: float = minf(
			minimum_width,
			platform_width
		)
		current_width = move_toward(
			current_width,
			target_width,
			shrink_speed * delta
		)
	else:
		# Igralec je zapustil platformo.
		time_without_player += delta

		# Platforma začne rasti šele po preteku zakasnitve.
		if time_without_player >= restore_delay:
			current_width = move_toward(
				current_width,
				platform_width,
				restore_speed * delta
			)

	_update_platform()


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	# Igralec mora priti na platformo od zgoraj.
	if body.global_position.y < global_position.y:
		player_on_platform = true
		time_without_player = 0.0


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_on_platform = false
		time_without_player = 0.0


func _update_platform() -> void:
	var collision := get_node_or_null(
		"CollisionShape2D"
	) as CollisionShape2D

	var visual := get_node_or_null(
		"Polygon2D"
	) as Polygon2D

	if collision == null or visual == null:
		return

	var width: float = current_width

	if width < 0.0:
		width = platform_width

	# Ko platforma postane skoraj popolnoma ozka,
	# jo skrijemo in izključimo trk.
	if width <= 1.0:
		visual.visible = false
		collision.set_deferred("disabled", true)
		return

	# Ko se platforma ponovno povečuje,
	# jo spet prikažemo in vključimo trk.
	visual.visible = true
	collision.set_deferred("disabled", false)

	var half_width := width / 2.0
	var half_height := platform_height / 2.0

	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(
		width,
		platform_height
	)

	collision.shape = rectangle

	visual.polygon = PackedVector2Array([
		Vector2(-half_width, -half_height),
		Vector2(half_width, -half_height),
		Vector2(half_width, half_height),
		Vector2(-half_width, half_height)
	])

	visual.color = platform_color
func _update_detector() -> void:
	var detector_collision := get_node_or_null(
		"PlayerDetector/CollisionShape2D"
	) as CollisionShape2D

	if detector_collision == null:
		return

	var detector_shape := RectangleShape2D.new()

	# Območje ostane široko kot prvotna platforma.
	detector_shape.size = Vector2(
		platform_width,
		20.0
	)

	detector_collision.shape = detector_shape

	# Območje postavimo tik nad platformo.
	detector_collision.position = Vector2(
		0,
		-platform_height / 2.0 - 10.0
	)
