extends TileMapLayer
## Gera um chão de cidade: ruas de asfalto em faixas diagonais
## (no isométrico, linhas/colunas da grade aparecem na diagonal) e calçada no resto.
## Cada célula sorteia uma variante do atlas (RNG com semente = mapa reproduzível).

## Tamanho do mapa em células.
@export var map_size: Vector2i = Vector2i(140, 140)
## A cada quantas células começa uma rua (nos dois eixos).
@export var road_spacing: int = 10
## Largura da rua em células.
@export var road_width: int = 3
## ID da fonte (TileSetAtlasSource) dentro do TileSet.
@export var source_id: int = 0
## Semente do sorteio de variantes (mesma semente = mesmo chão).
@export var seed: int = 1993
## Variantes no atlas res://art/tiles.png (linha 0: asfalto, 1: calçada, 2: faixas).
@export var asphalt_variants: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
@export var sidewalk_variants: Array[Vector2i] = [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)]
## Faixa "\" para ruas ao longo do eixo X da grade.
@export var lane_variants: Array[Vector2i] = [Vector2i(0, 2), Vector2i(1, 2)]
## Faixa espelhada "/" para ruas ao longo do eixo Y da grade.
@export var lane_mirrored_variants: Array[Vector2i] = [Vector2i(2, 2), Vector2i(3, 2)]

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	generate()


## (Re)gera todo o chão.
func generate() -> void:
	clear()
	_rng.seed = seed
	for x: int in map_size.x:
		for y: int in map_size.y:
			set_cell(Vector2i(x, y), source_id, _tile_for(x, y))


## Escolhe o tile de uma célula conforme sua posição na grade.
func _tile_for(x: int, y: int) -> Vector2i:
	var rx: int = x % road_spacing   # posição dentro do "quarteirão" no eixo X
	var ry: int = y % road_spacing
	var on_road_x: bool = rx < road_width
	var on_road_y: bool = ry < road_width
	if on_road_x and on_road_y:
		return _pick(asphalt_variants)          # cruzamento: asfalto sem faixa
	var center: int = road_width / 2
	if on_road_x and rx == center:
		return _pick(lane_mirrored_variants)    # rua no eixo Y: faixa "/"
	if on_road_y and ry == center:
		return _pick(lane_variants)             # rua no eixo X: faixa "\"
	if on_road_x or on_road_y:
		return _pick(asphalt_variants)
	return _pick(sidewalk_variants)


# Sorteia uma variante da lista usando o RNG com semente.
func _pick(options: Array[Vector2i]) -> Vector2i:
	return options[_rng.randi_range(0, options.size() - 1)]


## Centro do mapa em coordenadas locais (útil para a câmera).
func get_map_center() -> Vector2:
	return map_to_local(map_size / 2)
