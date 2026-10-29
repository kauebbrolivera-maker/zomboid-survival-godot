extends SceneTree
## Testa: cone gira para a direção do movimento; escuridão segue o relógio.
func _initialize() -> void:
	var main: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	var cone := main.get_node("Player/VisionCone") as PointLight2D
	var dark := main.get_node("Darkness") as CanvasModulate
	var phone: Node = main.get_node("Phone")
	phone.set("minutes_per_real_second", 0.0)
	Input.action_press("move_left")
	for i: int in 60: await physics_frame
	Input.action_release("move_left")
	for i: int in 30: await process_frame
	print("cone apos andar p/ esquerda: %.1f graus (esperado ~180)" % rad_to_deg(wrapf(cone.rotation, 0, TAU)))
	Input.action_press("move_up"); Input.action_press("move_right")
	for i: int in 60: await physics_frame
	Input.action_release("move_up"); Input.action_release("move_right")
	for i: int in 30: await process_frame
	print("cone apos cima+direita: %.1f graus (esperado ~-26.6 = 333.4 com achatamento iso)" % rad_to_deg(wrapf(cone.rotation, 0, TAU)))
	for h: float in [0.0, 6.0, 12.0, 18.0, 22.0]:
		phone.set("game_minutes", h * 60.0); await process_frame
		print("hora %02d -> escuridao %s" % [int(h), dark.color])
	print("velocidade max=", main.get_node("Player").get("speed"), " zoom=", (main.get_node("Camera") as Camera2D).zoom)
	quit()
