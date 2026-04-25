extends CharacterBody2D

const EXPLOSION = preload("res://Enemies/Phantom/Explosion.tscn")

var speed : float = 220.0
var direction = Vector2.ZERO
var lifetime = 2.0

var exploded = false

var target_position: Vector2 = Vector2.ZERO
var mode = 0  # 0 = pared, 1 = target

var shooter = null

@onready var animation_player = $AnimationPlayer

func _ready():
	await get_tree().process_frame
	
	rotation = direction.angle()
	animation_player.play("fireball")
	
	mode = randi() % 2
	
	
	if mode == 1 and target_position == Vector2.ZERO:
		target_position = global_position + direction * 200

func _physics_process(delta):
	if exploded:
		return
	
	var motion = direction * speed * delta
	var collision = move_and_collide(motion)

	if collision:
		var body = collision.get_collider()

		#  ignorar al que disparó SIEMPRE
		if body == shooter:
			return

		#  evitar que el player se dañe con su propia magia
		if shooter is Player and body is Player:
			return

		# enemigos no se dañan entre sí
		if shooter != null and body.get_class() == shooter.get_class():
			return

		if body.has_method("_take_damage"):
			var hurtbox = HurtBox.new()
			hurtbox.damage = 2
			body._take_damage(hurtbox)

		elif body.has_node("HitBox"):
			
			var hb = body.get_node("HitBox")
			if hb.has_method("damage"):
				hb.damage(2)

		explode()
		return

	
	if mode == 1:
		if global_position.distance_to(target_position) < 10:
			explode()


func explode():
	if exploded:
		return
	
	exploded = true
	
	spawn_explosion()
	queue_free()

func spawn_explosion():
	print("EXPLOSION SPAWN")
	var exp = EXPLOSION.instantiate()
	get_parent().add_child(exp)
	exp.global_position = global_position
