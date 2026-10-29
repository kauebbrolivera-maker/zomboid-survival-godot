class_name Player
extends CharacterBody2D
## Jogador: movimento em 8 direções (WASD/setas) com aceleração e atrito,
## e animações reais para as 8 direções (AnimatedSprite2D "Body").

## Nomes das 8 direções, na ordem dos ângulos (0° = direita, sentido horário na tela).
## Precisam bater com os nomes das animações: idle_<dir> e walk_<dir>.
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
## Como os tiles isométricos são 2:1 (128x64), andar "para cima" na tela cobre
## o dobro de células que andar para o lado. Com o achatamento, a velocidade
## *na grade* fica igual em todas as direções e o movimento acompanha as ruas.
@export var iso_vertical_squash: bool = true

## Última direção (normalizada) em que o jogador andou. Usada para o idle e o cone de visão.
var last_direction: Vector2 = Vector2.DOWN

@onready var body: AnimatedSprite2D = $Body


func _ready() -> void:
	add_to_group("player")   # permite que objetos do cenário encontrem o jogador
	_update_facing(Vector2.ZERO)


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


## Escolhe a animação pela direção:
## andando -> "walk_<direção do input>"; parado -> "idle_<última direção>".
## As direções da esquerda já vêm desenhadas na folha (sem flip_h).
func _update_facing(input_dir: Vector2) -> void:
	var anim: StringName
	if input_dir != Vector2.ZERO:
		anim = StringName("walk_" + get_direction_name(input_dir))
	else:
		anim = StringName("idle_" + get_direction_name(last_direction))
	if body.animation != anim or not body.is_playing():
		body.play(anim)   # só troca quando muda, para não reiniciar o ciclo


## Nome da direção (8 direções) de `dir`, ex.: "up_left". Usa last_direction por padrão.
func get_direction_name(dir: Vector2 = last_direction) -> String:
	var index: int = wrapi(roundi(dir.angle() / (PI / 4.0)), 0, 8)
	return DIRECTION_NAMES[index]
