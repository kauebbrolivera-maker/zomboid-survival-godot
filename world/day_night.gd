extends CanvasModulate
## Escuridão do mundo (névoa de guerra). Só afeta o canvas do mundo:
## o celular é um CanvasLayer próprio, então NÃO escurece.
## Com follow_clock, clareia de dia e escurece à noite usando o relógio do celular.

## Se true, a cor acompanha a hora do jogo (phone.game_minutes).
@export var follow_clock: bool = true
## Cor à noite (bem escura, azulada).
@export var night_color: Color = Color("1a1c22")
## Cor ao meio-dia (ainda levemente escurecida, para o cone aparecer).
@export var day_color: Color = Color("9c9ea6")

var _phone: Node = null


func _ready() -> void:
	color = night_color


func _process(_delta: float) -> void:
	if not follow_clock:
		return
	if _phone == null:
		_phone = get_tree().get_first_node_in_group("phone")
		if _phone == null:
			return
	var hour: float = float(_phone.get("game_minutes")) / 60.0
	color = night_color.lerp(day_color, daylight(hour))


## 0 = noite, 1 = dia. Amanhecer 05h-07h e entardecer 17h-19h com transição suave.
static func daylight(hour: float) -> float:
	if hour < 12.0:
		return smoothstep(5.0, 7.0, hour)
	return 1.0 - smoothstep(17.0, 19.0, hour)
