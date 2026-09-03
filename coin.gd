@tool
extends Area2D


enum CoinType {
	GOLD,
	SILVER
}


@export_group("Vrsta kovanca")

@export_enum("Zlati", "Srebrni")
var coin_type: int = CoinType.GOLD:
	set(value):
		coin_type = value
		queue_redraw()


@export_group("Videz")

@export_range(5.0, 100.0, 1.0) var coin_radius: float = 18.0:
	set(value):
		coin_radius = value
		_update_coin()

@export_range(0.1, 2.0, 0.1) var collect_time: float = 0.25


var collected: bool = false
var starting_y: float
var animation_time: float = 0.0


func _ready() -> void:
	_update_coin()
	queue_redraw()

	if Engine.is_editor_hint():
		return

	starting_y = position.y

	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or collected:
		return

	# Kovanec nežno lebdi gor in dol.
	animation_time += delta

	position.y = (
		starting_y
		+ sin(animation_time * 3.0) * 4.0
	)


func _on_body_entered(body: Node2D) -> void:
	if collected:
		return

	if not body.is_in_group("player"):
		return

	if not body.has_method("collect_coin"):
		return

	collected = true

	body.collect_coin(coin_type)

	var collision := get_node_or_null(
		"CollisionShape2D"
	) as CollisionShape2D

	if collision != null:
		collision.set_deferred(
			"disabled",
			true
		)

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		self,
		"scale",
		Vector2.ZERO,
		collect_time
	)

	tween.tween_property(
		self,
		"position:y",
		position.y - 30.0,
		collect_time
	)

	await tween.finished

	queue_free()


func _update_coin() -> void:
	var collision := get_node_or_null(
		"CollisionShape2D"
	) as CollisionShape2D

	if collision == null:
		return

	var circle := CircleShape2D.new()
	circle.radius = coin_radius
	collision.shape = circle

	queue_redraw()


func _draw() -> void:
	var main_color: Color
	var edge_color: Color
	var shine_color: Color

	if coin_type == CoinType.GOLD:
		main_color = Color("f4c542")
		edge_color = Color("ad7417")
		shine_color = Color("fff1a8")
	else:
		main_color = Color("c9d1d9")
		edge_color = Color("737d87")
		shine_color = Color("ffffff")

	# Zunanji rob.
	draw_circle(
		Vector2.ZERO,
		coin_radius,
		edge_color
	)

	# Glavni del kovanca.
	draw_circle(
		Vector2.ZERO,
		coin_radius - 3.0,
		main_color
	)

	# Notranji relief.
	draw_arc(
		Vector2.ZERO,
		coin_radius * 0.55,
		0.0,
		TAU,
		32,
		edge_color,
		2.0
	)

	# Svetlobni odsev.
	draw_arc(
		Vector2.ZERO,
		coin_radius * 0.75,
		3.4,
		5.1,
		16,
		shine_color,
		3.0
	)
