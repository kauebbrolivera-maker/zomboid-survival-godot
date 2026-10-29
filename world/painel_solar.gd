class_name PainelSolar
extends Area2D
## Painel solar: perto dele, o jogador aperta E para carregar o celular (só de dia).

## Quanto de bateria (%) sobe por segundo enquanto carrega.
@export var charge_per_second: float = 5.0

@onready var prompt: Label = $Prompt

var _player_near: bool = false   # jogador dentro do raio de interação?
var _charging: bool = false      # está carregando agora?


func _ready() -> void:
	prompt.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if _player_near and event.is_action_pressed("interact"):
		toggle_charging()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not _charging:
		return
	var phone: Node = _get_phone()
	if phone == null:
		_stop_charging("")
		return
	# Se anoitecer durante a recarga, para.
	if not phone.call("is_daytime"):
		_stop_charging("O sol se pôs: recarga interrompida.")
		return
	phone.call("recharge", charge_per_second * delta)
	if float(phone.get("battery")) >= 100.0:
		_stop_charging("Bateria carregada!")


## Liga/desliga a recarga (chamado ao apertar E perto do painel).
func toggle_charging() -> void:
	if _charging:
		_stop_charging("Recarga pausada.")
		return
	var phone: Node = _get_phone()
	if phone == null:
		return
	if not phone.call("is_daytime"):
		phone.call("show_notice", "Sem energia solar: é noite!")
	elif float(phone.get("battery")) >= 100.0:
		phone.call("show_notice", "Bateria já está cheia.")
	else:
		_charging = true
		phone.call("show_notice", "Carregando com energia solar...")
	_update_prompt()


## true enquanto o painel está carregando o celular.
func is_charging() -> bool:
	return _charging


func _stop_charging(message: String) -> void:
	_charging = false
	var phone: Node = _get_phone()
	if phone != null and message != "":
		phone.call("show_notice", message)
	_update_prompt()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_near = true
		_update_prompt()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_near = false
		if _charging:
			_stop_charging("Você se afastou do painel.")
		_update_prompt()


func _update_prompt() -> void:
	prompt.visible = _player_near
	prompt.text = "[E] Parar" if _charging else "[E] Recarregar"


# Busca o celular pelo grupo "phone" (sem depender do caminho na árvore).
func _get_phone() -> Node:
	return get_tree().get_first_node_in_group("phone")
