extends CharacterBody2D

const FIRE_WALL = preload("res://Enemies/Phantom/FireWall.tscn")
const FIRE_WARNING = preload("res://Enemies/Phantom/FireWarning.tscn")
const FIREBALL = preload("res://Enemies/Phantom/Fireball.tscn")
const GOBLIN = preload("res://Enemies/goblin/goblin.tscn")


@onready var hit_box = $HitBox
@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var shield = $Shield/AnimatedSprite2D
@onready var persistent = $PersistentDataHandler


var player : Node = null
var player_in_range : bool = false
var was_in_range = false
var is_pulling : bool = false
var is_attacking : bool = false
var is_invulnerable : bool = true

var max_hp : int = 50
var hp : int = 50

var allow_pull : bool = true
var last_attack = -1
var is_hurt = false
var is_dead = false
var phase = 1
var firewall_count = 3
var pull_strength : float = 40.0
var fireball_speed : float = 220.0




func _ready():
	persistent.data_loaded.connect(_on_data_loaded)
	
	player = PlayerManager.player
	PlayerHud.show_boss_health("Phantom")
	PlayerHud.update_boss_health(hp, max_hp)
	hit_box.damaged.connect(_take_damage)
	animation_player.play("idle")

	shield.visible = false   
	set_invulnerable(true)

func _process(delta):
	if is_dead:
		return
	if player_in_range and not was_in_range:
		print("Jugador detectado")
	
	if not player_in_range and was_in_range:
		print("Jugador salió")
	
	was_in_range = player_in_range
	
	is_pulling = player_in_range and allow_pull
	
	if player_in_range and not is_attacking:
		start_attack_cycle()


func _physics_process(delta):
	if is_dead:
		return
	
	if is_invulnerable:
		keep_player_out()
	
	if is_pulling:
		pull_player(delta)


func keep_player_out():
	if not player:
		return
	
	var distance = global_position.distance_to(player.global_position)
	var shield_radius = 60
	
	if distance < shield_radius:
		var dir = (player.global_position - global_position).normalized()
		
		var push_force = 900  
		
		player.velocity = dir * push_force



func pull_player(delta):
	if not player:
		return
	
	var direction = (global_position - player.global_position).normalized()
	
	var force = pull_strength * 20  
	
	player.velocity += direction * force * delta

func _on_data_loaded():
	if persistent.value:
		queue_free()
		return
	
	init_boss()


func init_boss():
	player = PlayerManager.player
	PlayerHud.show_boss_health("Phantom")
	PlayerHud.update_boss_health(hp, max_hp)
	hit_box.damaged.connect(_take_damage)
	animation_player.play("idle")

	shield.visible = false   
	set_invulnerable(true)

func start_attack_cycle():
	if is_dead or is_attacking:
		return
	
	is_attacking = true
	allow_pull = true
	
	await get_tree().create_timer(1.2).timeout
	if is_dead:
		is_attacking = false
		return
	
	allow_pull = false
	
	print("CARGANDO ATAQUE")
	
	await get_tree().create_timer(0.5).timeout
	if is_dead:
		is_attacking = false
		return
	
	var attack_type = randi() % 2
	
	while attack_type == last_attack:
		attack_type = randi() % 2
	
	last_attack = attack_type
	
	if attack_type == 0:
		print("ATAQUE FIREWALL")
		animation_player.play("firewall")
		await animation_player.animation_finished
		if is_dead:
			is_attacking = false
			return
		
		spawn_attack_pattern()
	
	else:
		print("ATAQUE FIREBALL")
		animation_player.play("fireball")
		await animation_player.animation_finished
		if is_dead:
			is_attacking = false
			return
		
		shoot_fireball()
	
	# VENTANA DE DAÑO
	set_invulnerable(false)
	
	await get_tree().create_timer(2.0).timeout
	if is_dead:
		is_attacking = false
		return
	
	set_invulnerable(true)
	
	is_attacking = false
	
	if not is_dead:
		animation_player.play("idle")


func check_phase():
	var hp_percent = float(hp) / float(max_hp)
	
	if hp_percent <= 0.2 and phase < 3:
		phase = 3
		enter_phase_3()
	
	elif hp_percent <= 0.5 and phase < 2:
		phase = 2
		enter_phase_2()


func enter_phase_2():
	print("FASE 2")
	
	PlayerHud.queue_notification(
		"¡El Phantom se enfurece!",
		"Su poder aumenta"
	)
	
	pull_strength = 50.0
	firewall_count = 6
	fireball_speed = 300


func enter_phase_3():
	print("FASE 3")
	
	PlayerHud.queue_notification(
		"¡El Phantom invoca refuerzos!",
		"Ten cuidado..."
	)
	
	firewall_count = 10
	start_summoning()



func summon_goblin():
	var goblin = GOBLIN.instantiate()
	
	var spawn_pos = get_valid_spawn_position(80)
	
	get_parent().add_child(goblin)
	goblin.global_position = spawn_pos


func get_valid_spawn_position(radius: float) -> Vector2:
	var attempts = 30
	
	for i in range(attempts):
		var offset = Vector2(
			randf_range(-radius, radius),
			randf_range(-radius, radius)
		)
		
		var pos = global_position + offset
		
		if is_position_valid(pos) and pos.distance_to(player.global_position) > 50:
			return pos
	
	
	return global_position


func start_summoning():
	while not is_dead and phase == 3:
		summon_goblin()
		await get_tree().create_timer(3.0).timeout




func spawn_fire_wall():
	var fire = FIRE_WALL.instantiate()
	
	get_parent().add_child(fire)
	
	# aparece justo debajo del enemigo
	var offset = Vector2(
		randf_range(-16, 16),
		randf_range(16, 40)
	)
	
	fire.global_position = global_position + offset


func spawn_fire_with_warning(pos: Vector2):
	# ⚠️ WARNING
	var warn = FIRE_WARNING.instantiate()
	get_parent().add_child(warn)
	warn.global_position = pos
	
	# esperar antes del fuego
	await get_tree().create_timer(0.6).timeout
	
	# FUEGO
	var fire = FIRE_WALL.instantiate()
	get_parent().add_child(fire)
	fire.global_position = pos

func spawn_attack_pattern():
	if not player:
		return
	
	var base_pos = player.global_position
	
	var min_distance = 60
	var min_player_distance = 50
	var positions = []
	
	for i in range(firewall_count):
		var pos
		
		while true:
			var offset = Vector2(
				randf_range(-80, 80),
				randf_range(-80, 80)
			)
			
			pos = base_pos + offset
			
			var valid = true
			
			for p in positions:
				if pos.distance_to(player.global_position) < min_player_distance:
					valid = false
					break
			
			if valid:
				break
		
		positions.append(pos)
		
		# AQUÍ VA EL WARNING + FIRE
		spawn_fire_with_warning(pos)
	
	# TELEPORT SOLO UNA VEZ AL FINAL
	teleport()
	spawn_fire_wall()


func shoot_fireball():
	if not player:
		return
	
	var shots = 1
	
	if phase == 2:
		shots = 3
	elif phase == 3:
		shots = 5
	
	for i in range(shots):
		var fireball = FIREBALL.instantiate()
		get_parent().add_child(fireball)
		
		fireball.global_position = global_position
		fireball.shooter = self
		
		var base_dir = (player.global_position - global_position).normalized()
		
		var angle_offset = deg_to_rad(randf_range(-20, 20))
		var dir = base_dir.rotated(angle_offset)
		
		fireball.direction = dir
		fireball.target_position = player.global_position
		fireball.speed = fireball_speed




func _take_damage(hurt_box: HurtBox):
	if is_invulnerable or is_dead:
		return
	
	hp -= hurt_box.damage
	
	PlayerHud.update_boss_health(hp, max_hp)
	check_phase()
	
	print("ENEMIGO GOLPEADO")
	
	if hp <= 0:
		die()
		return
	
	# HURT SIN BLOQUEAR EL SISTEMA
	play_hurt_animation()


func play_hurt_animation():
	if is_hurt or is_dead:
		return
	
	is_hurt = true
	
	animation_player.play("hurt")
	await animation_player.animation_finished
	
	is_hurt = false
	
	if not is_attacking and not is_dead:
		animation_player.play("idle")


func teleport():
	if not player:
		return
	
	var max_attempts = 10
	var distance = 120
	var new_pos = global_position
	
	for i in range(max_attempts):
		var offset = Vector2(
			randf_range(-distance, distance),
			randf_range(-distance, distance)
		)
		
		var test_pos = player.global_position + offset
		
		if is_position_valid(test_pos):
			new_pos = test_pos
			break
	
	# DESAPARECER
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.2)
	await tween.finished
	
	global_position = new_pos
	
	# APARECER
	var tween2 = create_tween()
	tween2.tween_property(sprite, "modulate:a", 1.0, 0.2)
	await tween2.finished



func is_position_valid(pos: Vector2) -> bool:
	var space = get_world_2d().direct_space_state
	
	var shape = CircleShape2D.new()
	shape.radius = 16  # tamaño del enemigo
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, pos)
	query.collision_mask = 5  # Walls
	
	var result = space.intersect_shape(query)
	
	return result.is_empty()


func set_invulnerable(value: bool):
	is_invulnerable = value
	
	$Shield/ShieldArea.monitoring = value 
	
	if value:
		shield.visible = true
		shield.play("shield")
		push_player_out(player)
	else:
		shield.visible = false

func _on_detection_area_body_entered(body):
	if body is Player:
		player_in_range = true


func _on_detection_area_body_exited(body):
	if body is Player:
		player_in_range = false



func die():
	if is_dead:
		return
	
	PlayerHud.hide_boss_health()
	
	is_dead = true
	
	print("ENEMIGO MUERTO")
	
	# detener todo
	is_attacking = false
	allow_pull = false
	
	# quitar colisiones
	$HitBox.monitoring = false
	
	animation_player.play("death")
	await animation_player.animation_finished
	
	PlayerHud.queue_notification(
	"🔥 Has adquirido el poder de fuego",
	"Presiona F para lanzar bolas de fuego")
	
	PlayerManager.unlock_fire_power()
	persistent.set_value()
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://title_scene/credits.tscn")


func _on_shield_area_body_entered(body):
	if body is Player:
		push_player_out(body)


func push_player_out(player):
	if player == null:
		return
	
	var direction = (player.global_position - global_position).normalized()
	
	var push_force = 450 
	player.velocity = direction * push_force
