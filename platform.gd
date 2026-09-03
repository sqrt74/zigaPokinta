@tool
extends StaticBody2D

@export_range(10.0, 2000.0, 1.0) var platform_width: float = 250.0:
	set(value):
		platform_width = value
		_update_platform()

@export_range(10.0, 500.0, 1.0) var platform_height: float = 30.0:
	set(value):
		platform_height = value
		_update_platform()

@export var platform_color: Color = Color("d98b3a"):
	set(value):
		platform_color = value
		_update_platform()


func _ready() -> void:
	_update_platform()


func _update_platform() -> void:
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	var visual := get_node_or_null("Polygon2D") as Polygon2D

	if collision == null or visual == null:
		return

	var half_width := platform_width / 2.0
	var half_height := platform_height / 2.0

	# Ustvari samostojno obliko trka.
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(platform_width, platform_height)
	collision.shape = rectangle

	# Ustvari enako velik vidni pravokotnik.
	visual.polygon = PackedVector2Array([
		Vector2(-half_width, -half_height),
		Vector2(half_width, -half_height),
		Vector2(half_width, half_height),
		Vector2(-half_width, half_height)
	])

	visual.color = platform_color
