extends SceneTree
## Testa as 8 direções: animação andando e idle mantendo a última direção.
const CASES: Array = [
	[["move_down"], "down"], [["move_down", "move_right"], "down_right"],
	[["move_right"], "right"], [["move_up", "move_right"], "up_right"],
	[["move_up"], "up"], [["move_up", "move_left"], "up_left"],
	[["move_left"], "left"], [["move_down", "move_left"], "down_left"],
]

func _initialize() -> void:
	var main: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	var body := main.get_node("Player/Body") as AnimatedSprite2D
	var ok: int = 0
	for c: Array in CASES:
		for a: String in c[0]: Input.action_press(a)
		for i: int in 10: await physics_frame
		var walk: String = body.animation
		var playing: bool = body.is_playing()
		for a: String in c[0]: Input.action_release(a)
		for i: int in 10: await physics_frame
		var idle: String = body.animation
		var good: bool = walk == "walk_" + c[1] and idle == "idle_" + c[1] and playing
		ok += int(good)
		print("%-22s andando=%-16s parado=%-16s %s" % [str(c[0]), walk, idle, "OK" if good else "FALHOU"])
	print("resultado: %d/8" % ok)
	var phone: Node = main.get_node("Phone")
	var bar := phone.get_node("PhonePanel/VBoxContainer/BatteryBar") as ProgressBar
	var fill := bar.get_theme_stylebox("fill") as StyleBoxFlat
	phone.call("_set_battery", 50.0); print("bateria 50%% -> cor %s" % fill.bg_color.to_html(false))
	phone.call("_set_battery", 15.0); print("bateria 15%% -> cor %s" % fill.bg_color.to_html(false))
	quit()
