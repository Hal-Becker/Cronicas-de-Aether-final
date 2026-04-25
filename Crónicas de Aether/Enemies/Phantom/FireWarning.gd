extends Node2D

@onready var animation_player = $AnimationPlayer

func _ready():
	animation_player.play("warn")
	
	await animation_player.animation_finished
	
	queue_free()
