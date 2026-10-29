extends SceneTree
## Testa as 8 direções: o "nariz" do modelo 3D, projetado pela Camera3D,
## aponta na tela para a mesma direção do movimento (com achatamento 2:1).
const CASES: Array = [
	[["move_down"], Vector2(0, 1)], [["move_down", "move_right"], Vector2(1, 1)],
	[["move_right"], Vector2(1, 0)], [["move_up", "move_right"], Vector2(1, -1)],
	[["move_up"], Vector2(0, -1)], [["move_up", "move_left"], Vector2(-1, -1)],
	[["move_left"], Vector2(-1, 0)], [["move_down", "move_left"], Vector2(-1, 1)],
]

func _initialize() -> void:
	var main: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	var p := main.get_node("Player") as Player
	await process_frame
	var cam: Camera3D = p.camera_3d
	var ok: int = 0
	for c: Array in CASES:
		for a: String in c[0]: Input.action_press(a)
		for i: int in 40: await process_frame
		var cone_deg: float = rad_to_deg((p.get_node("VisionCone") as Node2D).rotation)
		for a: String in c[0]: Input.action_release(a)
		for i: int in 20: await process_frame
		var origin: Vector3 = p.model.global_position + Vector3(0, 1.0, 0)
		var fwd: Vector3 = p.model.global_transform.basis.z.normalized()
		var screen: Vector2 = cam.unproject_position(origin + fwd) - cam.unproject_position(origin)
		var expected: Vector2 = c[1] * Vector2(1, 0.5)   # direção real na tela (2:1)
		var err: float = rad_to_deg(absf(angle_difference(screen.angle(), expected.angle())))
		var good: bool = err < 2.0
		ok += int(good)
		print("%-26s yaw=%7.1f°  nariz na tela=%7.1f°  esperado=%7.1f°  cone=%7.1f°  erro=%.2f° %s" % [
			str(c[0]), rad_to_deg(wrapf(p.model.rotation.y, -PI, PI)), rad_to_deg(screen.angle()),
			rad_to_deg(expected.angle()), wrapf(cone_deg, -180, 180), err, "OK" if good else "FALHOU"])
	print("resultado: %d/8" % ok)
	# Mouse: mira para a direita-baixo do jogador na tela
	p.aim_mode = Player.AimMode.MOUSE
	print("modo mouse get_aim_direction=", p.get_aim_direction())
	quit()
