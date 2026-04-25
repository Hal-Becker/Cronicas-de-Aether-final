extends Node2D

@onready var animation_player = $AnimationPlayer

func _ready():
	print("EXPLOSION READY")
	
	animation_player.play("explode")
	
	await get_tree().create_timer(0.5).timeout
	
	queue_free()
