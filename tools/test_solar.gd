extends SceneTree
## Teste do painel solar: dia carrega até 100%, noite não carrega.
func _press_e() -> void:
	# Gera um evento real de tecla (chega em _unhandled_input).
	var ev := InputEventAction.new()
	ev.action = "interact"; ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame
	ev = InputEventAction.new(); ev.action = "interact"; ev.pressed = false
	Input.parse_input_event(ev)
	await process_frame

func _initialize() -> void:
	var main: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	var phone: Node = main.get_node("Phone")
	var player := main.get_node("Player") as Node2D
	var panel: Node = main.get_node("PainelSolar")
	phone.set("minutes_per_real_second", 0.0)   # congela o relógio durante o teste
	player.global_position = (panel as Node2D).global_position + Vector2(40, 20)
	for i: int in 10: await physics_frame
	print("grupos: player=", player.is_in_group("player"), " phone=", phone.is_in_group("phone"), " prompt_visivel=", panel.get_node("Prompt").visible)
	# --- DIA, com bateria morta ---
	phone.set("game_minutes", 10.0 * 60.0)
	phone.set("battery", 0.0); phone.call("_shutdown")
	print("DIA inicio: bateria=%.1f morto=%s" % [phone.get("battery"), phone.get("is_dead")])
	await _press_e()
	await process_frame
	print("  carregando=", panel.call("is_charging"), " aviso='", phone.get_node("Notice").text, "' morto=", phone.get("is_dead"))
	var t: float = 0.0
	while panel.call("is_charging") and t < 60.0:
		await process_frame; t += get_root().get_process_delta_time()
	print("  fim (%.1fs de jogo): bateria=%.1f carregando=%s aviso='%s' morto=%s" % [t, phone.get("battery"), panel.call("is_charging"), phone.get_node("Notice").text, phone.get("is_dead")])
	# --- NOITE ---
	phone.set("game_minutes", 20.0 * 60.0)
	phone.set("battery", 30.0)
	print("NOITE is_daytime=", phone.call("is_daytime"), " hora=", phone.call("get_hour"))
	await _press_e()
	for i: int in 60: await process_frame
	print("  bateria=%.2f (antes 30, só dreno) carregando=%s aviso='%s' visivel=%s" % [phone.get("battery"), panel.call("is_charging"), phone.get_node("Notice").text, phone.get_node("Notice").visible])
	# --- afastar-se interrompe ---
	phone.set("game_minutes", 10.0 * 60.0)
	await _press_e()
	await process_frame
	player.global_position += Vector2(400, 0)
	for i: int in 5: await physics_frame
	print("AFASTOU: carregando=", panel.call("is_charging"), " aviso='", phone.get_node("Notice").text, "'")
	quit()
