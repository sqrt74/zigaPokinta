@tool
extends Node2D


@export_group("Velikost in videz")

@export_range(20.0, 1000.0, 1.0) var spikes_width: float = 200.0:
	set(value):
		spikes_width = value
		_update_spikes()

@export_range(10.0, 200.0, 1.0) var spikes_height: float = 45.0:
	set(value):
		spikes_height = value
		_update_spikes()

@export_range(1, 30, 1) var spike_count: int = 6:
	set(value):
		spike_count = value
		_update_spikes()

@export var spikes_color: Color = Color("b9bec7"):
	set(value):
		spikes_color = value
		_update_spikes()


@export_group("Smrt igralca")

@export_range(0.0, 5.0, 0.1) var restart_delay: float = 0.5

func _ready() -> void:
	_update_spikes()

	if Engine.is_editor_hint():
		return

	$DangerArea.body_entered.connect(
		_on_body_entered
	)


func _update_spikes() -> void:
	var visual := get_node_or_null(
		"Polygon2D"
	) as Polygon2D

	var collision := get_node_or_null(
		"DangerArea/CollisionShape2D"
	) as CollisionShape2D

	if visual == null or collision == null:
		return

	var points := PackedVector2Array()
	var count: int = maxi(spike_count, 1)
	var single_width: float = spikes_width / float(count)
	var left_edge: float = -spikes_width / 2.0
	var bottom: float = spikes_height / 2.0
	var top: float = -spikes_height / 2.0

	# Začetni spodnji levi kot.
	points.append(
		Vector2(left_edge, bottom)
	)

	# Vsaka špica ima levi spodnji rob, vrh in desni rob.
	for i in range(count):
		var spike_left := left_edge + i * single_width
		var spike_middle := spike_left + single_width / 2.0
		var spike_right := spike_left + single_width

		points.append(
			Vector2(spike_left, bottom)
		)

		points.append(
			Vector2(spike_middle, top)
		)

		points.append(
			Vector2(spike_right, bottom)
		)

	# Zaključimo spodnji del oblike.
	points.append(
		Vector2(left_edge + spikes_width, bottom)
	)

	visual.polygon = points
	visual.color = spikes_color

	# Nevarno območje pokriva celotne špice.
	var danger_shape := RectangleShape2D.new()
	danger_shape.size = Vector2(
		spikes_width,
		spikes_height
	)

	collision.shape = danger_shape
	collision.position = Vector2.ZERO
	
func _on_body_entered(body: Node2D) -> void:

	if not body.is_in_group("player"):
		return

	if not body is CharacterBody2D:
		return

	var player := body as CharacterBody2D

	# Spodnji rob špic.
	var spikes_bottom := (
		global_position.y
		+ spikes_height / 2.0
	)

	# Če je središče igralca pod spodnjim robom špic,
	# se jih dotika od spodaj in zato ne umre.
	if player.global_position.y > spikes_bottom:
		return

	# Dotik od zgoraj ali s strani ubije igralca.
	_kill_player(player)

func _kill_player(player: CharacterBody2D) -> void:
	if player.has_method("die_instantly"):
		player.die_instantly()
