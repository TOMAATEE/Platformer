extends RichTextLabel

var coin_count = 0
const COIN_IMG = &"[img]res://assets/tiles/tile_coin.png[/img]"
# Called when the node enters the scene tree for the first time.
func _ready():
	text = COIN_IMG + &"[color=yellow] 0"

func _on_world_coin_collected(amount: int) -> void:
	update_coins(amount)

func update_coins(amount: int) -> void:
	coin_count += amount
	text = COIN_IMG + &"[color=yellow] " + str(coin_count)
