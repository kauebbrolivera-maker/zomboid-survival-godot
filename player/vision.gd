extends PointLight2D
## Cone de visão (FOV) do jogador.
## A textura res://art/vision_cone.png aponta para +X; giramos a luz para a
## direção do olhar, que vem de Player.get_aim_direction() (mesma fonte que
## gira o modelo 3D, então cone e corpo nunca discordam).
## Para sombras atrás de paredes no futuro: ligue `shadow_enabled` nesta luz
## e adicione LightOccluder2D nas paredes/prédios.

## Velocidade do giro suave (maior = mais rápido).
@export var turn_speed: float = 10.0
## Achata o ângulo na vertical (grade 2:1), para o cone seguir as ruas isométricas.
@export var iso_aim_squash: bool = true

var _player: Player = null


func _ready() -> void:
	_player = get_parent() as Player
	rotation = _target_angle()   # começa já apontado, sem girar na largada


func _process(delta: float) -> void:
	# lerp_angle pega o caminho mais curto (ex.: de 350° para 10°).
	var t: float = 1.0 - exp(-turn_speed * delta)   # independente de FPS
	rotation = lerp_angle(rotation, _target_angle(), t)


## Ângulo (rad) na tela para onde o cone deve apontar.
func _target_angle() -> float:
	if _player == null:
		return rotation
	# A direção do jogador vem "desachatada" (espaço do chão); na tela o eixo Y
	# da grade 2:1 aparece pela metade.
	var dir: Vector2 = _player.get_aim_direction()
	if iso_aim_squash:
		dir.y *= 0.5
	if dir.length_squared() < 0.0001:
		return rotation   # sem direção: mantém o ângulo atual
	return dir.angle()
