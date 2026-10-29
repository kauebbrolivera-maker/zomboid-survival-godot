class_name Player
extends CharacterBody2D
## Jogador: física 2D (move_and_slide) + modelo 3D pixelizado num SubViewport,
## no estilo Project Zomboid. O corpo inteiro gira 360° suavemente no eixo Y.
## O visual/animação do modelo fica no componente CharacterModel (nó "Model").

## MOVEMENT: olha para onde anda. MOUSE: olha para o cursor.
enum AimMode { MOVEMENT, MOUSE }

## Nomes das 8 direções, na ordem dos ângulos (0° = direita, sentido horário na tela).
const DIRECTION_NAMES: PackedStringArray = [
	"right", "down_right", "down", "down_left", "left", "up_left", "up", "up_right",
]

@export_group("Movimento")
## Velocidade máxima em pixels por segundo.
@export var speed: float = 320.0
## Aceleração (px/s²) ao começar a andar.
@export var acceleration: float = 2400.0
## Atrito (px/s²) ao soltar as teclas.
@export var friction: float = 3200.0
## Se true, reduz pela metade o componente vertical (grade isométrica 2:1),
## para a velocidade na grade ser igual em todas as direções.
@export var iso_vertical_squash: bool = true

@export_group("Modelo 3D")
## De onde vem a direção do olhar (corpo 3D e cone de visão).
@export var aim_mode: AimMode = AimMode.MOVEMENT
## Velocidade do giro do corpo (maior = mais rápido).
@export var turn_speed: float = 12.0

## Última direção de movimento, no espaço "desachatado" do input
## (igual ao input_dir; x = direita na tela, y = baixo na tela).
var last_direction: Vector2 = Vector2.DOWN

var _ground_right: Vector3 = Vector3.RIGHT   # "direita da tela" no chão 3D
var _ground_down: Vector3 = Vector3.BACK     # "baixo da tela" no chão 3D

@onready var model: CharacterModel = $ModelView/SubViewport/World3D/Model
@onready var camera_3d: Camera3D = $ModelView/SubViewport/World3D/Camera3D


func _ready() -> void:
	add_to_group("player")   # permite que objetos do cenário encontrem o jogador
	_compute_ground_axes()
	model.rotation.y = _yaw_for(get_aim_direction())   # já começa virado


func _physics_process(delta: float) -> void:
	# get_vector já normaliza: na diagonal o tamanho é 1, igual às retas.
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if input_dir != Vector2.ZERO:
		last_direction = input_dir
		var target_velocity: Vector2 = input_dir * speed
		if iso_vertical_squash:
			target_velocity.y *= 0.5   # proporção 2:1 da grade isométrica
		velocity = velocity.move_toward(target_velocity, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()


func _process(delta: float) -> void:
	_update_facing(delta)
	# idle/walk/run do GLB ou animação procedural do boneco provisório
	model.set_motion(velocity.length() / speed)


## Direção do olhar no espaço "desachatado" (mesmo espaço do input_dir).
## Usada pelo modelo 3D e pelo vision.gd.
func get_aim_direction() -> Vector2:
	if aim_mode == AimMode.MOUSE:
		var d: Vector2 = get_global_mouse_position() - global_position
		d.y *= 2.0   # desfaz o achatamento 2:1 da tela
		if d.length_squared() > 1.0:
			return d.normalized()
	return last_direction


## Nome da direção (8 direções) de `dir`, ex.: "up_left". Usa last_direction por padrão.
func get_direction_name(dir: Vector2 = last_direction) -> String:
	var index: int = wrapi(roundi(dir.angle() / (PI / 4.0)), 0, 8)
	return DIRECTION_NAMES[index]


## Converte uma direção da tela (desachatada) em yaw (rad) do modelo.
## O "nariz" do modelo aponta para +Z local; rotation.y = yaw o leva a (sin yaw, 0, cos yaw).
func _yaw_for(screen_dir: Vector2) -> float:
	var g: Vector3 = _ground_right * screen_dir.x + _ground_down * screen_dir.y
	return atan2(g.x, g.z)


## Eixos da tela projetados no chão 3D, tirados da própria Camera3D
## (assim continua certo se o yaw/inclinação da câmera mudar).
func _compute_ground_axes() -> void:
	var b: Basis = camera_3d.global_transform.basis
	_ground_right = Vector3(b.x.x, 0.0, b.x.z).normalized()
	# +Z da câmera aponta "para trás" dela = para baixo na tela, no chão.
	_ground_down = Vector3(b.z.x, 0.0, b.z.z).normalized()


## Gira o corpo inteiro suavemente (caminho mais curto, independente de FPS).
func _update_facing(delta: float) -> void:
	var dir: Vector2 = get_aim_direction()
	if dir.length_squared() < 0.0001:
		return
	var t: float = 1.0 - exp(-turn_speed * delta)
	model.rotation.y = lerp_angle(model.rotation.y, _yaw_for(dir), t)
