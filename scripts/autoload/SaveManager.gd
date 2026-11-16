extends Node

## SaveManager: Verwaltet Meta-Progression, Goldene Samenkörner und Gärtner-Buch Upgrades.

const SAVE_PATH := "user://petal_and_thorn_save.json"

var golden_seeds: int = 0
var highest_unlocked_level: int = 1
var upgrades: Dictionary = {
	"bonus_start_dewdrops": 0,
	"symbiosis_cost_discount_pct": 0,
	"core_health_bonus_pct": 0,
}

func _ready() -> void:
	load_game()

func add_golden_seeds(amount: int) -> void:
	golden_seeds += amount
	save_game()

func unlock_level(level_id: int) -> void:
	if level_id > highest_unlocked_level:
		highest_unlocked_level = level_id
		save_game()

func save_game() -> void:
	var data := {
		"golden_seeds": golden_seeds,
		"highest_unlocked_level": highest_unlocked_level,
		"upgrades": upgrades,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) == OK and json.data is Dictionary:
		var d: Dictionary = json.data
		golden_seeds = int(d.get("golden_seeds", 0))
		highest_unlocked_level = int(d.get("highest_unlocked_level", 1))
		if d.has("upgrades") and d["upgrades"] is Dictionary:
			upgrades = d["upgrades"]
