extends PanelContainer


@onready var gold_count: Label = (
	$ResultsContent/ResultsGrid/GoldCount
)

@onready var silver_count: Label = (
	$ResultsContent/ResultsGrid/SilverCount
)

@onready var total_count: Label = (
	$ResultsContent/ResultsGrid/TotalCount
)


func _ready() -> void:
	visible = false


func show_results(
	gold: int,
	silver: int
) -> void:
	gold_count.text = str(gold)
	silver_count.text = str(silver)
	total_count.text = str(gold + silver)

	visible = true
