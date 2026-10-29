extends CanvasLayer
## Celular do jogador: relógio do jogo + bateria que descarrega em tempo real.

## Emitido uma única vez quando a bateria chega a 0%.
signal battery_depleted
## Emitido sempre que o nível de bateria muda (útil para HUD/sons).
signal battery_changed(level: float)

## Quantos minutos do jogo passam a cada segundo real.
@export var minutes_per_real_second: float = 1.0
## Hora inicial do relógio (em minutos desde 00:00). 480 = 08:00.
@export var start_minutes: float = 8.0 * 60.0
## Quanto de bateria (%) é gasto por segundo real, com o celular fechado.
@export var drain_per_second: float = 0.05
## Gasto extra (%) por segundo enquanto a tela está aberta.
@export var extra_drain_when_open: float = 0.1

const MINUTES_PER_DAY: float = 24.0 * 60.0
## Abaixo deste nível (%) a barra fica vermelha.
const LOW_BATTERY: float = 20.0
const COLOR_OK: Color = Color("5f9e4a")    # verde (dessaturado)
const COLOR_LOW: Color = Color("b8483a")   # vermelho

@onready var phone_panel: Panel = $PhonePanel
@onready var clock_label: Label = $PhonePanel/VBoxContainer/ClockLabel
@onready var battery_bar: ProgressBar = $PhonePanel/VBoxContainer/BatteryBar
@onready var battery_label: Label = $PhonePanel/VBoxContainer/BatteryLabel
@onready var screen_off: ColorRect = $PhonePanel/ScreenOff
@onready var notice_label: Label = $Notice

var game_minutes: float = 0.0   # Minutos do dia no jogo (0..1439)
var battery: float = 100.0      # Nível da bateria em %
var is_dead: bool = false       # true quando a bateria acabou
var _notice_tween: Tween = null # animação do aviso atual
var _fill_style: StyleBoxFlat = StyleBoxFlat.new() # preenchimento da barra


func _ready() -> void:
	add_to_group("phone")   # permite que outros nós achem o celular
	notice_label.visible = false
	_setup_battery_bar()
	game_minutes = fposmod(start_minutes, MINUTES_PER_DAY)
	phone_panel.visible = false   # Começa guardado no bolso
	screen_off.visible = false
	_update_clock()
	_update_battery_ui()


func _process(delta: float) -> void:
	# O relógio do jogo sempre anda, mesmo com o celular fechado.
	game_minutes = fposmod(game_minutes + minutes_per_real_second * delta, MINUTES_PER_DAY)
	if phone_panel.visible:
		_update_clock()

	# A bateria descarrega em tempo real (mais rápido se a tela estiver aberta).
	if not is_dead:
		var drain: float = drain_per_second
		if phone_panel.visible:
			drain += extra_drain_when_open
		_set_battery(battery - drain * delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_phone"):
		toggle()
		get_viewport().set_input_as_handled()


## Abre/fecha o celular. Não faz nada se a bateria estiver morta.
func toggle() -> void:
	if is_dead:
		return
	phone_panel.visible = not phone_panel.visible
	if phone_panel.visible:
		_update_clock()


## Recarrega a bateria em `amount` %. Religa o aparelho se estava descarregado.
func recharge(amount: float) -> void:
	if amount <= 0.0:
		return
	_set_battery(battery + amount)
	if is_dead and battery > 0.0:
		is_dead = false
		screen_off.visible = false


## Hora atual do jogo (0..23).
func get_hour() -> int:
	return int(game_minutes) / 60


## true entre 06:00 (inclusive) e 18:00 (exclusive).
func is_daytime() -> bool:
	var hour: int = get_hour()
	return hour >= 6 and hour < 18


## Mostra um aviso na tela por `seconds` segundos.
## Fica fora do PhonePanel, então aparece mesmo com o celular fechado ou sem bateria.
func show_notice(text: String, seconds: float = 2.5) -> void:
	if _notice_tween != null and _notice_tween.is_valid():
		_notice_tween.kill()
	notice_label.text = text
	notice_label.modulate.a = 1.0
	notice_label.visible = true
	_notice_tween = create_tween()
	_notice_tween.tween_interval(seconds)
	_notice_tween.tween_property(notice_label, "modulate:a", 0.0, 0.4)  # some suavemente
	_notice_tween.tween_callback(notice_label.hide)


## Retorna a hora do jogo no formato "HH:MM".
func get_time_string() -> String:
	var total: int = int(game_minutes)
	return "%02d:%02d" % [total / 60, total % 60]


func _set_battery(value: float) -> void:
	battery = clampf(value, 0.0, 100.0)
	_update_battery_ui()
	battery_changed.emit(battery)
	if battery <= 0.0 and not is_dead:
		_shutdown()


# Desliga o celular: tela preta, fecha e bloqueia novas aberturas.
func _shutdown() -> void:
	is_dead = true
	screen_off.visible = true
	phone_panel.visible = false
	battery_depleted.emit()


func _update_clock() -> void:
	clock_label.text = get_time_string()


# Estilo da barra: fundo escuro + preenchimento colorido (verde/vermelho).
func _setup_battery_bar() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("2a2a2b")
	bg.set_corner_radius_all(6)
	_fill_style.set_corner_radius_all(6)
	_fill_style.bg_color = COLOR_OK
	battery_bar.add_theme_stylebox_override("background", bg)
	battery_bar.add_theme_stylebox_override("fill", _fill_style)


func _update_battery_ui() -> void:
	battery_bar.value = battery
	_fill_style.bg_color = COLOR_LOW if battery < LOW_BATTERY else COLOR_OK
	battery_label.text = "Bateria: %d%%" % ceili(battery)
