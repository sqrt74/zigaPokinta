@tool
extends AnimatableBody2D


@export_group("Velikost in videz")

@export_range(10.0, 2000.0, 1.0) var platform_width: float = 250.0:
	set(value):
		platform_width = value
		_update_platform()

@export_range(10.0, 500.0, 1.0) var platform_height: float = 30.0:
	set(value):
		platform_height = value
		_update_platform()

@export var platform_color: Color = Color("4da6e8"):
	set(value):
		platform_color = value
		_update_platform()


@export_group("Premikanje")

# Premik glede na začetni položaj.
@export var movement_offset: Vector2 = Vector2(300, 0)

# Čas poti samo v eno smer.
@export_range(0.1, 30.0, 0.1) var travel_time: float = 3.0

# Čas čakanja na obeh koncih.
@export_range(0.0, 10.0, 0.1) var wait_time: float = 0.5


var start_position: Vector2
var movement_tween: Tween


func _ready() -> void:
	_update_platform()

	if Engine.is_editor_hint():
		return

	start_position = position
	_start_movement()


func _update_platform() -> void:
	var collision := get_node_or_null(
		"CollisionShape2D"
	) as CollisionShape2D

	var visual := get_node_or_null(
		"Polygon2D"
	) as Polygon2D

	if collision == null or visual == null:
		return

	var half_width := platform_width / 2.0
	var half_height := platform_height / 2.0

	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(
		platform_width,
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


func _start_movement() -> void:
	var end_position := start_position + movement_offset

	movement_tween = create_tween()
	movement_tween.set_loops()
	movement_tween.set_trans(Tween.TRANS_SINE)
	movement_tween.set_ease(Tween.EASE_IN_OUT)

	movement_tween.tween_property(
		self,
		"position",
		end_position,
		travel_time
	)

	movement_tween.tween_interval(wait_time)

	movement_tween.tween_property(
		self,
		"position",
		start_position,
		travel_time
	)

	movement_tween.tween_interval(wait_time)
