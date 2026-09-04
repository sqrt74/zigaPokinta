extends PanelContainer


const LEVEL_SELECT_SCENE := "res://menus/level_select.tscn"


@onready var gold_count: Label = (
	$ResultsContent/ResultsGrid/GoldCount
)

@onready var silver_count: Label = (
	$ResultsContent/ResultsGrid/SilverCount
)

@onready var total_count: Label = (
	$ResultsContent/ResultsGrid/TotalCount
)

@onready var back_button: Button = (
	$ResultsContent/BackButton
)


func _ready() -> void:
	visible = false
	back_button.pressed.connect(_return_to_level_select)


func show_results(
	gold: int,
	silver: int
) -> void:
	gold_count.text = str(gold)
	silver_count.text = str(silver)
	total_count.text = str(gold + silver)

	visible = true
	back_button.grab_focus()


func _return_to_level_select() -> void:
	var error := get_tree().change_scene_to_file(
		LEVEL_SELECT_SCENE
	)

	if error != OK:
		push_error(
			"Menija za izbiro levela ni mogoče odpreti."
		)
