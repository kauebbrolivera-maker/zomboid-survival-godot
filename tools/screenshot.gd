extends SceneTree
## Screenshots de dia (12:00) e de noite (22:00) com o cone apontado.
func _shot(main: Node, minutes: float, path: String) -> void:
	var phone: Node = main.get_node("Phone")
	phone.set("game_minutes", minutes)
	for i: int in 30: await process_frame
	root.get_texture().get_image().save_png(path)
	print(path, " hora=", phone.call("get_time_string"), " cor=", (main.get_node("Darkness") as CanvasModulate).color)

func _initialize() -> void:
	var main: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.get_node("Phone").set("minutes_per_real_second", 0.0)
	var player := main.get_node("Player") as Node2D
	player.global_position = (main.get_node("PainelSolar") as Node2D).global_position + Vector2(-110, 40)
	player.set("last_direction", Vector2(1, -0.3).normalized())   # olhando p/ o painel
	(main.get_node("Camera") as Node2D).global_position = player.global_position
	for i: int in 30: await process_frame
	await _shot(main, 12.0 * 60.0, "/workspace/scene6_day.png")
	await _shot(main, 22.0 * 60.0, "/workspace/scene6_night.png")
	quit()
