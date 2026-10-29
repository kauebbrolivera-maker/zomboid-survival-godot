class_name CharacterModel
extends Node3D
## Componente do modelo 3D do personagem (fica no nó "Model", pivô que gira no eixo Y).
##
## - Sem `model_scene`: usa o boneco provisório (primitivas) com animação procedural.
## - Com `model_scene` (um .glb/.gltf gerado por IA ou do Mixamo):
##     instancia o modelo, esconde as primitivas, normaliza a altura, põe os pés
##     em y=0, aplica o giro de correção, acha o AnimationPlayer e mapeia
##     idle/walk/run pelo nome, e cria pontos de encaixe nos ossos (mão, coluna).
##
## O Player chama `set_motion(razao)` todo frame (0 = parado, 1 = andando no
## máximo, > run_threshold = correndo).

## Material opcional para "achatar" o visual de modelos de IA.
enum MaterialStyle { ORIGINAL, MATTE, UNSHADED }

## Papéis de animação que o componente entende.
const ROLES: PackedStringArray = ["idle", "walk", "run"]
## Palavras procuradas no nome da animação (minúsculas), por papel, em ordem de preferência.
const ROLE_KEYWORDS: Dictionary = {
	"idle": ["idle", "breath", "stand"],
	"walk": ["walk"],
	"run": ["run", "sprint", "jog"],
}
## Palavras que descartam uma animação (ex.: "WalkJump" não é andar).
const ROLE_EXCLUDE: PackedStringArray = ["jump", "back", "left", "right", "strafe", "turn", "start", "stop"]
## Nomes de osso comuns (Mixamo, Blender, Unity, AccuRIG...) em ordem de preferência.
const BONE_CANDIDATES: Dictionary = {
	"right_hand": ["mixamorig:RightHand", "RightHand", "hand.R", "Hand.R", "hand_r", "Hand_R", "R_Hand", "Palm2.R", "LowerArm.R"],
	"spine": ["mixamorig:Spine2", "mixamorig:Spine1", "Spine2", "Spine1", "spine.003", "Spine", "spine", "Chest", "Torso", "Torso_2", "Abdomen"],
}
## Palavras para a busca aproximada de ossos, se nenhum nome exato existir.
const BONE_FUZZY: Dictionary = {
	"right_hand": [["hand", "r"], ["palm", "r"], ["wrist", "r"], ["lowerarm", "r"], ["forearm", "r"]],
	"spine": [["spine"], ["chest"], ["torso"], ["abdomen"]],
}

@export_group("Modelo GLB")
## Cena do modelo (arraste o .glb aqui). Vazio = boneco provisório.
@export var model_scene: PackedScene = null:
	set(value):
		model_scene = value
		if is_node_ready():
			_load_model()
## Altura final do modelo, em unidades 3D (o boneco provisório tem ~1,9).
@export_range(0.2, 5.0, 0.05) var target_height: float = 1.8
## Correção de giro em graus. Use 180 se o modelo andar "de costas".
## (O jogo considera que a frente do modelo é +Z, padrão do glTF.)
@export_range(-180.0, 180.0, 1.0) var model_yaw_offset_deg: float = 0.0
## Mapeamento manual papel -> nome da animação, ex.: {"walk": "Armature|Walk"}.
## Papéis ausentes ou vazios são detectados pelo nome automaticamente.
@export var animation_map: Dictionary = {}
## Tempo de transição entre animações (s).
@export var crossfade_time: float = 0.2
## Acima disto (razão de velocidade) o personagem anda.
@export var walk_threshold: float = 0.08
## Acima disto corre. 1.0 = velocidade normal do Player; >1 só com corrida.
@export var run_threshold: float = 1.2
## Osso da mão direita. Vazio = detectar automaticamente.
@export var right_hand_bone: String = ""
## Osso da coluna (mochila). Vazio = detectar automaticamente.
@export var spine_bone: String = ""
## Estilo de material aplicado ao GLB (ORIGINAL = não mexe).
@export var material_style: MaterialStyle = MaterialStyle.ORIGINAL

@export_group("Animação procedural (boneco provisório)")
## Altura (unidades 3D) do balanço vertical ao andar.
@export var bob_height: float = 0.05
## Ângulo máximo (graus) do balanço das pernas/braços.
@export var leg_swing_deg: float = 28.0
## Passos por segundo na velocidade máxima.
@export var step_rate: float = 2.2

## Instância do GLB (null = usando o boneco provisório).
var imported: Node3D = null
## AnimationPlayer encontrado no GLB (ou null).
var anim_player: AnimationPlayer = null
## Papel -> nome real da animação no GLB.
var resolved_animations: Dictionary = {}
## Papel ("right_hand", "spine") -> nó de encaixe (BoneAttachment3D ou Marker3D).
var attach_points: Dictionary = {}

var _speed_ratio: float = 0.0
var _current_role: String = ""
var _walk_phase: float = 0.0
var _base_y: float = 0.0
var _pivot: Node3D = null   # nó intermediário: escala, pés no chão e correção de giro

@onready var _equipment: Node3D = get_node_or_null("Equipment") as Node3D


func _ready() -> void:
	_base_y = position.y
	_load_model()


## Informa a velocidade relativa (0 = parado, 1 = andar normal, > run_threshold = correr).
func set_motion(speed_ratio: float) -> void:
	_speed_ratio = maxf(speed_ratio, 0.0)


## true se um GLB foi carregado.
func has_imported_model() -> bool:
	return imported != null


## Ponto de encaixe para roupas/armas: "right_hand" ou "spine".
## No GLB é um BoneAttachment3D que segue o osso; no boneco provisório, um Marker3D.
func get_attach_point(role: String) -> Node3D:
	return attach_points.get(role, null) as Node3D


## Papel de animação tocando agora ("idle", "walk", "run" ou "" no procedural).
func get_current_role() -> String:
	return _current_role


func _process(delta: float) -> void:
	if anim_player != null and not resolved_animations.is_empty():
		_update_glb_animation()
	else:
		_update_procedural(delta)


# ---------------------------------------------------------------- carregar GLB

func _load_model() -> void:
	if _pivot != null:
		_pivot.queue_free()
	_pivot = null
	imported = null
	anim_player = null
	resolved_animations.clear()
	_current_role = ""
	var use_glb: bool = model_scene != null
	_set_placeholder_visible(not use_glb)
	if not use_glb:
		_setup_placeholder_attach_points()
		return

	_pivot = Node3D.new()
	_pivot.name = "ImportedPivot"
	add_child(_pivot)
	imported = model_scene.instantiate() as Node3D
	if imported == null:
		push_warning("CharacterModel: model_scene não tem um Node3D na raiz.")
		_pivot.queue_free()
		_pivot = null
		_set_placeholder_visible(true)
		return
	_pivot.add_child(imported)
	_normalize_size()
	_pivot.rotation.y = deg_to_rad(model_yaw_offset_deg)
	if material_style != MaterialStyle.ORIGINAL:
		_apply_material_style(imported)
	_setup_animations()
	_setup_bone_attach_points()


## Esconde/mostra as primitivas do boneco provisório (tudo menos Equipment e o GLB).
func _set_placeholder_visible(value: bool) -> void:
	for child: Node in get_children():
		if child == _pivot or child == _equipment:
			continue
		if child is Node3D:
			(child as Node3D).visible = value
	# A mochila provisória também é primitiva.
	var bag: Node3D = get_node_or_null("Equipment/Back/Backpack") as Node3D
	if bag != null:
		bag.visible = value


## Escala o GLB para `target_height` e põe os pés em y=0, centralizado em X/Z.
func _normalize_size() -> void:
	var box: AABB = _compute_model_aabb(imported)
	if box.size.y <= 0.0001:
		push_warning("CharacterModel: não consegui medir o modelo; mantendo a escala.")
		return
	var s: float = target_height / box.size.y
	imported.scale *= s
	var center := box.get_center() * s
	imported.position += Vector3(-center.x, -box.position.y * s, -center.z)


## AABB do modelo no espaço da raiz importada (inclui malhas com esqueleto, na pose de descanso).
func _compute_model_aabb(root: Node3D) -> AABB:
	var result := AABB()
	var first: bool = true
	for mi: MeshInstance3D in _find_all(root, "MeshInstance3D"):
		if mi.mesh == null:
			continue
		var points: PackedVector3Array = _mesh_points(mi, root)
		for p: Vector3 in points:
			if first:
				result = AABB(p, Vector3.ZERO)
				first = false
			else:
				result = result.expand(p)
	return result


## Pontos (amostrados) da malha no espaço de `root`. Para malhas com Skin,
## aplica a pose de descanso do esqueleto (osso de maior peso por vértice).
func _mesh_points(mi: MeshInstance3D, root: Node3D) -> PackedVector3Array:
	var out := PackedVector3Array()
	var mi_xf: Transform3D = _relative_transform(mi, root)
	var skel: Skeleton3D = null
	if mi.skin != null and not mi.skeleton.is_empty():
		skel = mi.get_node_or_null(mi.skeleton) as Skeleton3D
	for surf: int in mi.mesh.get_surface_count():
		var arrays: Array = mi.mesh.surface_get_arrays(surf)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var step: int = maxi(1, verts.size() / 1500)   # limita o custo
		if skel == null or arrays[Mesh.ARRAY_BONES] == null:
			var aabb_xf: Transform3D = mi_xf
			for i: int in range(0, verts.size(), step):
				out.append(aabb_xf * verts[i])
			continue
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var per: int = bones.size() / maxi(verts.size(), 1)
		var skel_xf: Transform3D = _relative_transform(skel, root)
		for i: int in range(0, verts.size(), step):
			var best: int = 0
			for k: int in per:
				if weights[i * per + k] > weights[i * per + best]:
					best = k
			var bind: int = bones[i * per + best]
			var bone_idx: int = mi.skin.get_bind_bone(bind)
			if bone_idx < 0:
				bone_idx = skel.find_bone(mi.skin.get_bind_name(bind))
			if bone_idx < 0:
				continue
			var xf: Transform3D = skel_xf * skel.get_bone_global_rest(bone_idx) * mi.skin.get_bind_pose(bind)
			out.append(xf * verts[i])
	return out


## Transform de `node` relativo a `ancestor` (funciona mesmo fora da árvore).
func _relative_transform(node: Node3D, ancestor: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var n: Node = node
	while n != null and n != ancestor:
		if n is Node3D:
			xf = (n as Node3D).transform * xf
		n = n.get_parent()
	return xf


## Lista todos os descendentes de uma classe.
func _find_all(root: Node, type_name: String) -> Array[Node]:
	return root.find_children("*", type_name, true, false)


# ---------------------------------------------------------------- animações

func _setup_animations() -> void:
	var found: Array[Node] = _find_all(imported, "AnimationPlayer")
	if found.is_empty():
		return
	anim_player = found[0] as AnimationPlayer
	var names: PackedStringArray = anim_player.get_animation_list()
	for role: String in ROLES:
		var manual: String = str(animation_map.get(role, ""))
		if manual != "" and anim_player.has_animation(manual):
			resolved_animations[role] = manual
			continue
		var auto: String = _match_animation(names, role)
		if auto != "":
			resolved_animations[role] = auto
	# Faltando papéis: run -> walk, walk -> run, idle -> walk (parado no quadro 0).
	if not resolved_animations.has("walk") and resolved_animations.has("run"):
		resolved_animations["walk"] = resolved_animations["run"]
	if not resolved_animations.has("run") and resolved_animations.has("walk"):
		resolved_animations["run"] = resolved_animations["walk"]
	if resolved_animations.is_empty() and names.size() > 0:
		resolved_animations["walk"] = names[0]   # GLB com uma animação só
		resolved_animations["run"] = names[0]
	for role: String in resolved_animations:
		var anim: Animation = anim_player.get_animation(resolved_animations[role])
		if anim != null:
			anim.loop_mode = Animation.LOOP_LINEAR


## Acha a animação do papel pelo nome (sem diferenciar maiúsculas), ignorando o
## prefixo "Armature|" e nomes de variações (ex.: "WalkJump", "Walk_Back").
func _match_animation(names: PackedStringArray, role: String) -> String:
	for key: String in ROLE_KEYWORDS[role]:
		var best: String = ""
		for full: String in names:
			var n: String = full.to_lower().get_slice("|", full.count("|"))
			if not n.contains(key):
				continue
			var excluded: bool = false
			for bad: String in ROLE_EXCLUDE:
				if n.contains(bad) and not key.contains(bad):
					excluded = true
					break
			if excluded:
				continue
			if best == "" or full.length() < best.length():
				best = full   # prefere o nome mais curto ("Walk" a "Walk_Carry")
		if best != "":
			return best
	return ""


func _update_glb_animation() -> void:
	var role: String = "idle"
	if _speed_ratio > run_threshold:
		role = "run"
	elif _speed_ratio > walk_threshold:
		role = "walk"
	if not resolved_animations.has(role):
		role = "walk" if resolved_animations.has("walk") else ""
	if role == "":
		return
	if role != _current_role:
		_current_role = role
		anim_player.play(resolved_animations[role], crossfade_time)
	# Velocidade da animação acompanha a do personagem (sem deslizar).
	if role == "walk":
		anim_player.speed_scale = clampf(_speed_ratio, 0.5, 1.3)
	elif role == "run":
		anim_player.speed_scale = clampf(_speed_ratio / run_threshold, 0.8, 1.5)
	else:
		anim_player.speed_scale = 1.0
	# Sem animação de idle: usa a de andar congelada no início.
	if _speed_ratio <= walk_threshold and not resolved_animations.has("idle"):
		anim_player.speed_scale = 0.0


# ---------------------------------------------------------------- encaixes

func _setup_placeholder_attach_points() -> void:
	attach_points.clear()
	var hand: Node3D = get_node_or_null("Equipment/RightHand") as Node3D
	var back: Node3D = get_node_or_null("Equipment/Back") as Node3D
	if hand != null:
		attach_points["right_hand"] = hand
	if back != null:
		attach_points["spine"] = back


func _setup_bone_attach_points() -> void:
	_setup_placeholder_attach_points()   # padrão, se não houver esqueleto
	var skels: Array[Node] = _find_all(imported, "Skeleton3D")
	if skels.is_empty():
		return
	var skel := skels[0] as Skeleton3D
	var manual: Dictionary = {"right_hand": right_hand_bone, "spine": spine_bone}
	for role: String in ["right_hand", "spine"]:
		var bone: String = _find_bone(skel, role, manual[role])
		if bone == "":
			push_warning("CharacterModel: osso para '%s' não encontrado." % role)
			continue
		var att := BoneAttachment3D.new()
		att.name = "Attach_" + role
		att.bone_name = bone
		skel.add_child(att)
		attach_points[role] = att


func _find_bone(skel: Skeleton3D, role: String, manual: String) -> String:
	if manual != "" and skel.find_bone(manual) >= 0:
		return manual
	for cand: String in BONE_CANDIDATES[role]:
		if skel.find_bone(cand) >= 0:
			return cand
	# Busca aproximada: todas as palavras presentes; "r" = lado direito.
	for words: Array in BONE_FUZZY[role]:
		for i: int in skel.get_bone_count():
			var n: String = skel.get_bone_name(i).to_lower()
			var ok: bool = true
			for w: String in words:
				if w == "r":
					ok = ok and (n.ends_with(".r") or n.ends_with("_r") or n.contains("right") or n.begins_with("r_"))
				else:
					ok = ok and n.contains(w)
			if ok:
				return skel.get_bone_name(i)
	return ""


# ---------------------------------------------------------------- materiais

## Deixa o GLB com cara de "pixel survival": fosco ou sem iluminação.
func _apply_material_style(root: Node) -> void:
	for mi: MeshInstance3D in _find_all(root, "MeshInstance3D"):
		if mi.mesh == null:
			continue
		for s: int in mi.mesh.get_surface_count():
			var src: Material = mi.get_active_material(s)
			var mat: BaseMaterial3D = null
			if src is BaseMaterial3D:
				mat = (src as BaseMaterial3D).duplicate() as BaseMaterial3D
			else:
				mat = StandardMaterial3D.new()
			mat.metallic = 0.0
			mat.roughness = 1.0
			mat.metallic_specular = 0.0
			mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			if material_style == MaterialStyle.UNSHADED:
				mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mi.set_surface_override_material(s, mat)


# ---------------------------------------------------------------- procedural

## Boneco provisório: balanço vertical + pernas/braços em pêndulo.
func _update_procedural(delta: float) -> void:
	if imported != null:
		return   # GLB sem animações: fica parado (só gira)
	var amount: float = clampf(_speed_ratio, 0.0, 1.0)
	if amount > 0.05:
		_walk_phase = wrapf(_walk_phase + delta * step_rate * TAU * amount, 0.0, TAU)
	else:
		_walk_phase = lerp_angle(_walk_phase, 0.0, 1.0 - exp(-10.0 * delta))
	var swing: float = sin(_walk_phase) * deg_to_rad(leg_swing_deg) * amount
	_rot_x("LegL", swing)
	_rot_x("LegR", -swing)
	_rot_x("ArmL", -swing * 0.8)
	_rot_x("ArmR", swing * 0.8)
	position.y = _base_y + absf(sin(_walk_phase)) * bob_height * amount
	_current_role = "walk" if amount > walk_threshold else "idle"


func _rot_x(node_name: String, angle: float) -> void:
	var n: Node3D = get_node_or_null(node_name) as Node3D
	if n != null:
		n.rotation.x = angle
