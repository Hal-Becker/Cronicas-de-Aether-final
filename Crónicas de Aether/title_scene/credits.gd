extends Control

@onready var fade = $ColorRect
@onready var btn_continue = $VBoxContainer/BtnContinue
@onready var btn_menu = $VBoxContainer/BtnMenu

func _ready():
	# 🔥 evita bloqueo de input
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	btn_continue.pressed.connect(_on_continue_pressed)
	btn_menu.pressed.connect(_on_menu_pressed)
	
	fade.modulate.a = 1.0
	fade_in()


func fade_in():
	var tween = create_tween()
	tween.tween_property(fade, "modulate:a", 0.0, 1.5)


func _on_continue_pressed():
	print("CLICK CONTINUE")
	fade_out_and_resume()


func _on_menu_pressed():
	print("CLICK MENU")
	fade_out_and_menu()


func fade_out_and_resume():
	var tween = create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, 1.0)
	await tween.finished
	
	get_tree().change_scene_to_file("res://Levels/Area01/prueba.tscn")


func fade_out_and_menu():
	var tween = create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, 1.0)
	await tween.finished
	
	get_tree().change_scene_to_file("res://title_scene/title_scene.tscn")
