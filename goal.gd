@tool
extends Node2D


@export_group("Videz cilja")

@export_range(40.0, 500.0, 1.0) var goal_width: float = 180.0:
	set(value):
		goal_width = value
		_update_goal()

@export_range(10.0, 200.0, 1.0) var goal_height: float = 50.0:
	set(value):
		goal_height = value
		_update_goal()

@export var goal_color: Color = Color("472d66"):
	set(value):
		goal_color = value
		_update_goal()


@export_group("Animacija")

@export_range(0.1, 3.0, 0.1) var sink_time: float = 0.8
@export_range(10.0, 300.0, 1.0) var sink_distance: float = 100.0


var completed: bool = false


func _ready() -> void:
	_update_goal()

	if Engine.is_editor_hint():
		return

	var trigger := $Area2D as Area2D
	trigger.body_entered.connect(_on_body_entered)

	$Label.visible = false


func _update_goal() -> void:
	var visual := get_node_or_null("Polygon2D") as Polygon2D
	var collision := get_node_or_null(
		"Area2D/CollisionShape2D"
	) as CollisionShape2D

	if visual == null or collision == null:
		return

	# Izdelava elipse iz 40 točk.
	var ellipse_points := PackedVector2Array()
	var point_count := 40

	for i in range(point_count):
		var angle := TAU * float(i) / float(point_count)

		ellipse_points.append(
			Vector2(
				cos(angle) * goal_width / 2.0,
				sin(angle) * goal_height / 2.0
			)
		)

	visual.polygon = ellipse_points
	visual.color = goal_color

	# Območje zaznavanja je samo na zgornjem delu elipse.
	var trigger_shape := RectangleShape2D.new()
	trigger_shape.size = Vector2(
		goal_width * 0.8,
		max(goal_height * 0.35, 10.0)
	)

	collision.shape = trigger_shape
	collision.position = Vector2(
		0,
		-goal_height * 0.15
	)


func _on_body_entered(body: Node2D) -> void:
	if completed:
		return

	if not body.is_in_group("player"):
		return

	# Cilj se aktivira samo, če igralec prihaja od zgoraj.
	if body.global_position.y > global_position.y:
		return

	if body is CharacterBody2D:
		var player := body as CharacterBody2D

		# Če se igralec trenutno premika navzgor, cilj še ne velja.
		if player.velocity.y < 0:
			return

		_complete_goal(player)


func _complete_goal(player: CharacterBody2D) -> void:
	completed = true

	# Ustavimo igralčevo upravljanje in trke.
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)

	var player_collision := player.get_node_or_null(
		"CollisionShape2D"
	) as CollisionShape2D

	if player_collision != null:
		player_collision.set_deferred("disabled", true)

	# Pred potapljanjem postavimo igralca pred elipso.
	player.z_index = -1

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		player,
		"global_position",
		player.global_position + Vector2(0, sink_distance),
		sink_time
	)

	tween.tween_property(
		player,
		"scale",
		Vector2(0.25, 0.25),
		sink_time
	)

	tween.set_parallel(false)
	tween.tween_callback(
		_show_victory.bind(player)
	)


func _show_victory(player: CharacterBody2D) -> void:
	var results_panel := get_tree().get_first_node_in_group(
		"results_panel"
	)

	if results_panel == null:
		push_error(
			"Ni vozlišča v skupini results_panel."
		)
		return

	var gold: int = 0
	var silver: int = 0

	if player.has_method("get_gold_coins"):
		gold = player.get_gold_coins()

	if player.has_method("get_silver_coins"):
		silver = player.get_silver_coins()

	results_panel.show_results(
		gold,
		silver
	)
