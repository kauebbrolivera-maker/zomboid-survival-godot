extends SceneTree
## Screenshot no jogo: jogador andando em diagonal (baixo+esquerda) no fim da tarde.
func _initialize() -> void:
	var main: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	var phone: Node = main.get_node("Phone")
	phone.set("minutes_per_real_second", 0.0)
	phone.set("game_minutes", 16.0 * 60.0)
	(main.get_node("Camera") as Camera2D).zoom = Vector2(0.35, 0.35)
	Input.action_press("move_down"); Input.action_press("move_left")
	for i: int in 50: await process_frame
	root.get_texture().get_image().save_png("/workspace/scene8.png")
	print("yaw=", rad_to_deg((main.get_node("Player") as Player).model.rotation.y))
	quit()
