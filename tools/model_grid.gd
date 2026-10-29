extends SceneTree
## Renderiza o jogador (modelo 3D + contorno, como aparece no jogo, escala 1:1
## do mundo) virado para as 8 direções e monta uma grade 4x2 ampliada 2x.
const NAMES: Array = ["down", "down_right", "right", "up_right", "up", "up_left", "left", "down_left"]
const DIRS: Array = [Vector2(0,1), Vector2(1,1), Vector2(1,0), Vector2(1,-1), Vector2(0,-1), Vector2(-1,-1), Vector2(-1,0), Vector2(-1,1)]

func _initialize() -> void:
	var bg := ColorRect.new()
	bg.color = Color("5a5a58"); bg.size = Vector2(1152, 648)
	root.add_child(bg)
	# Uso: ... -s res://tools/model_grid.gd -- [caminho.glb] [saida.png]
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var out_path: String = args[1] if args.size() > 1 else "/workspace/model3d_8dir.png"
	var p := (load("res://player/player.tscn") as PackedScene).instantiate() as Player
	if args.size() > 0 and args[0] != "":
		(p.get_node("ModelView/SubViewport/World3D/Model") as CharacterModel).model_scene = load(args[0]) as PackedScene
	p.position = Vector2(576, 400)
	root.add_child(p)
	(p.get_node("VisionCone") as Node2D).visible = false
	(p.get_node("AmbientRadius") as Node2D).visible = false
	p.set_process(false)
	await process_frame
	var cell := Vector2i(200, 280)
	var grid := Image.create(cell.x * 4, cell.y * 2, false, Image.FORMAT_RGBA8)
	for i: int in 8:
		p.model.rotation.y = p.call("_yaw_for", (DIRS[i] as Vector2).normalized())
		for f: int in 4: await process_frame
		var img: Image = root.get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		grid.blit_rect(img, Rect2i(Vector2i(476, 187), cell), Vector2i((i % 4) * cell.x, (i / 4) * cell.y))
		print(NAMES[i])
	grid.resize(grid.get_width() * 2, grid.get_height() * 2, Image.INTERPOLATE_NEAREST)
	grid.save_png(out_path)
	quit()
