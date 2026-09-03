@tool
extends Area2D


@export_group("Velikost in videz")

@export var zone_size: Vector2 = Vector2(250, 120):
	set(value):
		zone_size = value
		_update_zone()

@export var zone_color: Color = Color(
	0.8,
	0.15,
	0.15,
	0.35
):
	set(value):
		zone_color = value
		_update_zone()


@export_group("Poškodba")

@export_range(1, 20, 1) var damage_amount: int = 1
@export_range(0.1, 10.0, 0.1) var damage_interval: float = 1.0


var player_inside: CharacterBody2D = null


func _ready() -> void:
	_update_zone()

	if Engine.is_editor_hint():
		return

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	$DamageTimer.wait_time = damage_interval
	$DamageTimer.one_shot = false
	$DamageTimer.timeout.connect(_on_damage_timer_timeout)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if not body is CharacterBody2D:
		return

	player_inside = body as CharacterBody2D

	# Prvo življenje izgubi po eni sekundi.
	$DamageTimer.start()


func _on_body_exited(body: Node2D) -> void:
	if body != player_inside:
		return

	player_inside = null
	$DamageTimer.stop()


func _on_damage_timer_timeout() -> void:
	if not is_instance_valid(player_inside):
		player_inside = null
		$DamageTimer.stop()
		return

	if player_inside.has_method("take_damage"):
		player_inside.take_damage(damage_amount)


func _update_zone() -> void:
	var collision := get_node_or_null(
		"CollisionShape2D"
	) as CollisionShape2D

	var visual := get_node_or_null(
		"Polygon2D"
	) as Polygon2D

	if collision == null or visual == null:
		return

	var rectangle := RectangleShape2D.new()
	rectangle.size = zone_size
	collision.shape = rectangle

	var half_size := zone_size / 2.0

	visual.polygon = PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y)
	])

	visual.color = zone_color
