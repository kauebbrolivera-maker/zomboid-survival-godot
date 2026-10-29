extends Node
## Demo automática para gravar vídeo (--write-movie). Roteiro por tempo.
var main: Node
var player: Node2D
var phone: Node
var panel: Node2D
var t: float = 0.0
var _done: Dictionary = {}

func _ready() -> void:
	main = (load("res://main.tscn") as PackedScene).instantiate()
	add_child(main)
	player = main.get_node("Player"); phone = main.get_node("Phone"); panel = main.get_node("PainelSolar")
	phone.set("battery", 35.0)
	phone.set("drain_per_second", 0.4)
	phone.set("minutes_per_real_second", 4.0)

func _once(key: String) -> bool:
	if _done.has(key): return false
	_done[key] = true; return true

func _hold(actions: Array) -> void:
	for a: String in ["move_up", "move_down", "move_left", "move_right"]:
		if a in actions: Input.action_press(a)
		else: Input.action_release(a)

func _tap(action: String) -> void:
	var ev := InputEventAction.new(); ev.action = action; ev.pressed = true
	Input.parse_input_event(ev)
	var up := InputEventAction.new(); up.action = action; up.pressed = false
	Input.parse_input_event(up)

func _wheel(down: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_WHEEL_DOWN if down else MOUSE_BUTTON_WHEEL_UP
	ev.pressed = true; ev.position = Vector2(576, 324)
	Input.parse_input_event(ev)

func _walk_to(target: Vector2) -> bool:
	var d: Vector2 = target - player.global_position
	var acts: Array = []
	if d.x > 20: acts.append("move_right")
	elif d.x < -20: acts.append("move_left")
	if d.y > 10: acts.append("move_down")
	elif d.y < -10: acts.append("move_up")
	_hold(acts)
	return acts.is_empty()

func _process(delta: float) -> void:
	t += delta
	if t < 2.0: _hold([])
	elif t < 5.0: _hold(["move_right"])
	elif t < 7.5: _hold(["move_up", "move_right"])
	elif t < 9.0: _hold(["move_up"])
	elif t < 9.5:
		_hold([])
		if _once("tab1"): _tap("toggle_phone")
	elif t < 13.0: _hold(["move_left"])
	elif t < 13.5:
		_hold([])
		if _once("tab2"): _tap("toggle_phone")
	elif t < 19.0:
		_walk_to(panel.global_position + Vector2(-60, 30))
	elif t < 27.0:
		_hold(["move_right"] if t < 19.3 else [])   # vira para o painel
		if t > 19.5 and _once("e1"): _tap("interact")
		if t > 20.0 and _once("tab3"): _tap("toggle_phone")
	elif t < 31.0:
		if _once("tab4"): _tap("toggle_phone")
		if int(t * 4) % 2 == 0 and _once("w%d" % int(t * 4)): _wheel(true)
	elif t < 32.0:
		if _once("night"):
			phone.set("game_minutes", 17.0 * 60.0)
			phone.set("minutes_per_real_second", 40.0)
	elif t < 36.0:
		_hold(["move_left", "move_down"])
		if phone.get("game_minutes") > 20.0 * 60.0: phone.set("minutes_per_real_second", 2.0)
	elif t < 38.0:
		_hold([])
		if int(t * 4) % 2 == 0 and _once("z%d" % int(t * 4)): _wheel(false)
	elif t < 42.0: _hold(["move_right"])
	elif t < 44.0: _hold(["move_up", "move_left"])
	elif t < 45.0:
		_hold([])
		if _once("tab5"): _tap("toggle_phone")
	if t > 48.0: get_tree().quit()
