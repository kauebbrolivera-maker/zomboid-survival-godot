extends Camera2D
## Câmera isométrica: segue um alvo suavemente (lerp) ou fica no centro do mapa,
## e afasta o zoom suavemente com a roda do mouse (como olhar o GPS).

## Alvo a seguir (ex.: o Player). Se vazio, centraliza no mapa.
@export var target_path: NodePath
## TileMapLayer usado para achar o centro do mapa.
@export var ground_path: NodePath = ^"../Ground"
## Velocidade de seguir o alvo (maior = mais "grudada").
@export var follow_speed: float = 6.0
## Zoom máximo (perto) e mínimo (longe).
@export var max_zoom: float = 0.35
@export var min_zoom: float = 0.15
## Quanto cada clique da roda altera o zoom.
@export var zoom_step: float = 0.05
## Velocidade da interpolação (lerp) do zoom.
@export var zoom_speed: float = 8.0

var _target_zoom: float = 1.0
var _target: Node2D = null


func _ready() -> void:
	_target_zoom = max_zoom
	zoom = Vector2.ONE * max_zoom
	if not target_path.is_empty():
		_target = get_node_or_null(target_path) as Node2D
	if _target != null:
		global_position = _target.global_position   # começa já em cima do alvo
	else:
		_center_on_map()
	make_current()


func _process(delta: float) -> void:
	# Fator de lerp independente de FPS: 1 - e^(-velocidade * delta).
	if _target != null:
		var follow_t: float = 1.0 - exp(-follow_speed * delta)
		global_position = global_position.lerp(_target.global_position, follow_t)
	var zoom_t: float = 1.0 - exp(-zoom_speed * delta)
	var z: float = lerpf(zoom.x, _target_zoom, zoom_t)
	zoom = Vector2(z, z)


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed:
		return
	if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_target_zoom = clampf(_target_zoom - zoom_step, min_zoom, max_zoom)  # afasta
	elif mb.button_index == MOUSE_BUTTON_WHEEL_UP:
		_target_zoom = clampf(_target_zoom + zoom_step, min_zoom, max_zoom)  # aproxima


# Posiciona a câmera no centro do TileMapLayer.
func _center_on_map() -> void:
	var ground := get_node_or_null(ground_path) as TileMapLayer
	if ground == null:
		return
	if ground.has_method("get_map_center"):
		global_position = ground.to_global(ground.call("get_map_center"))
	else:
		global_position = ground.to_global(ground.map_to_local(Vector2i(20, 20)))
