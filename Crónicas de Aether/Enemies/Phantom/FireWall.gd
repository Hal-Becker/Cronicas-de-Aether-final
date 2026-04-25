extends Node2D

const EXPLOSION = preload("res://Enemies/Phantom/Explosion.tscn")

@onready var animation_player = $AnimationPlayer
@onready var hurtbox = $HurtBox


func _ready():
	hurtbox.monitoring = false
	
	animation_player.play("fire")
	
	# 🔥 TELEGRAPH (tiempo antes de hacer daño)
	await get_tree().create_timer(0.2).timeout
	
	hurtbox.monitoring = true
	
	# 🔥 TIEMPO ACTIVO (aquí hace daño)
	await get_tree().create_timer(1.5).timeout
	
	hurtbox.monitoring = false
	
	# 🔥 TIEMPO EXTRA VISUAL (se queda visible sin hacer daño)
	await get_tree().create_timer(0.5).timeout
	
	queue_free()


func spawn_explosion():
	var exp = EXPLOSION.instantiate()
	get_parent().add_child(exp)
	exp.global_position = global_position
