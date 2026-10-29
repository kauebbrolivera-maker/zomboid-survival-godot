extends SceneTree
## Teste: simula entradas e mede a velocidade do jogador.
func _measure(p: CharacterBody2D, actions: Array[String], squash: bool) -> Vector2:
	p.set("iso_vertical_squash", squash)
	for a: String in actions: Input.action_press(a)
	for i: int in 40: await physics_frame
	var v: Vector2 = p.velocity
	for a: String in actions: Input.action_release(a)
	for i: int in 40: await physics_frame
	return v

func _initialize() -> void:
	var main: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	var p := main.get_node("Player") as CharacterBody2D
	var cam := main.get_node("Camera") as Camera2D
	for i: int in 5: await physics_frame
	var start: Vector2 = p.global_position
	for sq: bool in [false, true]:
		var r: Vector2 = await _measure(p, ["move_right"], sq)
		var d: Vector2 = await _measure(p, ["move_right", "move_down"], sq)
		var u: Vector2 = await _measure(p, ["move_up"], sq)
		print("squash=%s reta(dir) v=%s |v|=%.1f  diagonal v=%s |v|=%.1f  cima v=%s |v|=%.1f" % [sq, r, r.length(), d, d.length(), u, u.length()])
	Input.action_press("move_left")
	for i: int in 30: await physics_frame
	print("yaw apos esquerda=", rad_to_deg((p as Player).model.rotation.y), " nome=", p.call("get_direction_name"))
	Input.action_release("move_left")
	for i: int in 30: await physics_frame
	print("nome parado=", p.call("get_direction_name"))
	Input.action_press("move_up"); Input.action_press("move_left")
	for i: int in 20: await physics_frame
	print("nome diagonal=", p.call("get_direction_name"))
	Input.action_release("move_up"); Input.action_release("move_left")
	for i: int in 120: await process_frame
	print("moveu: inicio=%s fim=%s  camera=%s dist_cam=%.1f" % [start, p.global_position, cam.global_position, cam.global_position.distance_to(p.global_position)])
	quit()
