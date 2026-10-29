class_name Player
extends CharacterBody2D
## Jogador: movimento em 8 direções (WASD/setas) com aceleração e atrito.

## Nomes das 8 direções, na ordem dos ângulos (0° = direita, sentido horário na tela).
const DIRECTION_NAMES: PackedStringArray = [
	"right", "down_right", "down", "down_left", "left", "up_left", "up", "up_right",
]

## Velocidade máxima em pixels por segundo.
@export var speed: float = 320.0
## Aceleração (px/s²) ao começar a andar.
@export var acceleration: float = 2400.0
## Atrito (px/s²) ao soltar as teclas.
@export var friction: float = 3200.0
## Se true, reduz pela metade o componente vertical depois de normalizar.
## Como os tiles isométricos são 2:1 (64x32), andar "para cima" na tela cobre
## o dobro de células que andar para o lado. Com o achatamento, a velocidade
## *na grade* fica igual em todas as direções e o movimento acompanha as ruas.
@export var iso_vertical_squash: bool = true

## Última direção (normalizada) em que o jogador andou. Útil para animações.
var last_direction: Vector2 = Vector2.DOWN

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("player")   # permite que objetos do cenário encontrem o jogador


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
	_update_facing(input_dir)


# Espelha o sprite conforme o lado; parado, mantém o último lado.
func _update_facing(input_dir: Vector2) -> void:
	if input_dir.x < 0.0:
		sprite.flip_h = true
	elif input_dir.x > 0.0:
		sprite.flip_h = false


## Nome da direção (8 direções) de `dir`, ex.: "up_left". Usa last_direction por padrão.
func get_direction_name(dir: Vector2 = last_direction) -> String:
	var index: int = wrapi(roundi(dir.angle() / (PI / 4.0)), 0, 8)
	return DIRECTION_NAMES[index]
