extends SceneTree
## Testa o pipeline de GLB: escala/pés, mapeamento de animações, encaixes nos
## ossos, troca idle/walk/run e rotação nas 8 direções com o modelo importado.
const GLB := "res://art/models/test_character.glb"

func _initialize() -> void:
	var main: Node = (load("res://main.tscn") as PackedScene).instantiate()
	var model := main.get_node("Player/ModelView/SubViewport/World3D/Model") as CharacterModel
	model.model_scene = load(GLB) as PackedScene   # antes de entrar na árvore
	root.add_child(main)
	await process_frame
	var p := main.get_node("Player") as Player
	print("GLB carregado=", model.has_imported_model())
	print("animações no GLB=", model.anim_player.get_animation_list())
	print("mapeadas=", model.resolved_animations)
	for role: String in model.attach_points:
		var a: Node3D = model.attach_points[role]
		print("encaixe %s -> %s (%s)" % [role, a.name, (a as BoneAttachment3D).bone_name if a is BoneAttachment3D else "marker"])
	var box: AABB = model.call("_compute_model_aabb", model.imported)
	var s: float = model.imported.scale.y
	print("altura final=%.3f (alvo %.2f)  pés y=%.3f" % [box.size.y * s, model.target_height, model.imported.position.y + box.position.y * s])
	var visible_placeholder: bool = (model.get_node("Torso") as Node3D).visible
	print("boneco provisório visível=", visible_placeholder)
	# idle -> walk -> idle -> run
	for i: int in 5: await process_frame
	print("parado: papel=%s anim=%s" % [model.get_current_role(), model.anim_player.current_animation])
	Input.action_press("move_right")
	for i: int in 30: await physics_frame
	print("andando: papel=%s anim=%s speed_scale=%.2f" % [model.get_current_role(), model.anim_player.current_animation, model.anim_player.speed_scale])
	Input.action_release("move_right")
	for i: int in 30: await physics_frame
	print("soltou: papel=%s anim=%s" % [model.get_current_role(), model.anim_player.current_animation])
	p.set_physics_process(false)
	p.velocity = Vector2(p.speed * 1.5, 0)
	for i: int in 5: await process_frame
	print("corrida (1.5x): papel=%s anim=%s" % [model.get_current_role(), model.anim_player.current_animation])
	p.velocity = Vector2.ZERO
	p.set_physics_process(true)
	# rotação com o GLB (o pivô do modelo é o mesmo)
	var ok: int = 0
	for d: Vector2 in [Vector2(0,1), Vector2(1,1), Vector2(1,0), Vector2(1,-1), Vector2(0,-1), Vector2(-1,-1), Vector2(-1,0), Vector2(-1,1)]:
		p.last_direction = d.normalized()
		await create_timer(0.8).timeout   # tempo real para o giro suave convergir
		var o: Vector3 = model.global_position + Vector3(0, 1, 0)
		var f: Vector3 = (model.global_transform.basis * model.get_node("ImportedPivot").transform.basis).z.normalized()
		var sc: Vector2 = p.camera_3d.unproject_position(o + f) - p.camera_3d.unproject_position(o)
		ok += int(rad_to_deg(absf(angle_difference(sc.angle(), (d * Vector2(1, 0.5)).angle()))) < 2.0)
	print("rotação GLB: %d/8" % ok)
	quit()
