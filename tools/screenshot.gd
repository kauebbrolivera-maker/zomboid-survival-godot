extends SceneTree
## Screenshot: jogador andando em diagonal (cima+esquerda) com o celular aberto.
func _initialize() -> void:
	var main: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	var phone: Node = main.get_node("Phone")
	phone.set("minutes_per_real_second", 0.0)
	phone.set("game_minutes", 18.5 * 60.0)
	phone.set("battery", 15.0)
	var player := main.get_node("Player") as Node2D
	(main.get_node("Camera") as Node2D).global_position = player.global_position
	Input.action_press("move_down"); Input.action_press("move_left")
	for i: int in 40: await process_frame
	phone.call("toggle")
	for i: int in 10: await process_frame
	root.get_texture().get_image().save_png("/workspace/scene7.png")
	print("anim=", (main.get_node("Player/Body") as AnimatedSprite2D).animation)
	quit()
