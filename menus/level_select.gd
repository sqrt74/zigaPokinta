extends Control


const LEVEL_CONFIG_PATH := "res://levels/levels.cfg"


@onready var levels_container: VBoxContainer = (
	$CenterContainer/MenuPanel/MenuContent/LevelsContainer
)

@onready var message_label: Label = (
	$CenterContainer/MenuPanel/MenuContent/MessageLabel
)


func _ready() -> void:
	_create_level_buttons()


func _create_level_buttons() -> void:
	var config := ConfigFile.new()
	var error := config.load(LEVEL_CONFIG_PATH)

	if error != OK:
		message_label.text = (
			"Napaka pri branju datoteke levels.cfg."
		)
		push_error(
			"Ni mogoče prebrati: %s" % LEVEL_CONFIG_PATH
		)
		return

	var button_count: int = 0

	for section in config.get_sections():
		var enabled: bool = bool(
			config.get_value(section, "enabled", true)
		)

		if not enabled:
			continue

		var level_name: String = str(
			config.get_value(section, "name", section)
		)

		var scene_path: String = str(
			config.get_value(section, "scene", "")
		)

		if scene_path.is_empty():
			push_warning(
				"Level %s nima določene scene." % section
			)
			continue

		if not ResourceLoader.exists(
			scene_path,
			"PackedScene"
		):
			push_warning(
				"Scena levela ne obstaja: %s" % scene_path
			)
			continue

		var level_button := Button.new()
		level_button.text = level_name
		level_button.custom_minimum_size = Vector2(320, 52)
		level_button.pressed.connect(
			_open_level.bind(scene_path)
		)

		levels_container.add_child(level_button)
		button_count += 1

	if button_count == 0:
		message_label.text = "Ni omogočenih levelov."
	else:
		message_label.text = "Izberi level, ki ga želiš igrati."


func _open_level(scene_path: String) -> void:
	var error := get_tree().change_scene_to_file(scene_path)

	if error != OK:
		message_label.text = "Levela ni mogoče odpreti."
		push_error(
			"Napaka pri odpiranju levela: %s" % scene_path
		)
