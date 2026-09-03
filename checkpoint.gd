@tool
extends Area2D

@export_group("Velikost")

@export_range(20.0, 200.0, 1.0) var checkpoint_width: float = 50.0:
	set(value):
		checkpoint_width = value
		_update_checkpoint()

@export_range(30.0, 300.0, 1.0) var checkpoint_height: float = 100.0:
	set(value):
		checkpoint_height = value
		_update_checkpoint()

@export_group("Ponovni začetek")

# Položaj igralca glede na checkpoint.
@export var respawn_offset: Vector2 = Vector2(0, -70)


@export_group("Barve")

@export var inactive_color: Color = Color("d95050"):
	set(value):
		inactive_color = value
		queue_redraw()

@export var active_color: Color = Color("55d96b"):
	set(value):
		active_color = value
		queue_redraw()


var active: bool = false


func _ready() -> void:
	add_to_group("checkpoints")

	_update_checkpoint()
	queue_redraw()

	if Engine.is_editor_hint():
		return

	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if not body.has_method("set_checkpoint"):
		return

	# Izključimo prejšnji aktivni checkpoint.
	for checkpoint in get_tree().get_nodes_in_group(
		"checkpoints"
	):
		if checkpoint.has_method("deactivate"):
			checkpoint.deactivate()

	# Aktiviramo tega.
	active = true
	queue_redraw()

	body.set_checkpoint(
		global_position + respawn_offset
	)


func deactivate() -> void:
	active = false
	queue_redraw()


func _update_checkpoint() -> void:
	var collision := get_node_or_null(
		"CollisionShape2D"
	) as CollisionShape2D

	if collision == null:
		return

	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(
		checkpoint_width,
		checkpoint_height
	)

	collision.shape = rectangle
	collision.position = Vector2(
		0,
		-checkpoint_height / 2.0
	)

	queue_redraw()


func _draw() -> void:
	var color := inactive_color

	if active:
		color = active_color

	var pole_height := checkpoint_height
	var flag_width := checkpoint_width
	var pole_color := Color("555b66")

	# Drog.
	draw_rect(
		Rect2(
			-3,
			-pole_height,
			6,
			pole_height
		),
		pole_color
	)

	# Konica droga.
	draw_circle(
		Vector2(0, -pole_height),
		7,
		Color("f2cf55")
	)

	# Zastavica.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(3, -pole_height + 10),
			Vector2(flag_width, -pole_height + 25),
			Vector2(3, -pole_height + 45)
		]),
		color
	)

	# Podstavek.
	draw_rect(
		Rect2(
			-15,
			-6,
			30,
			6
		),
		pole_color
	)
