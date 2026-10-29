# Zomboid Survival (Godot 4)

Protótipo de jogo de **sobrevivência isométrico** feito na **Godot 4.7.2 (GDScript)**, inspirado em *Project Zomboid* e ambientado nos dias atuais. O jogador depende de um **smartphone** para ver a hora — e o aparelho gasta bateria.

## Mecânicas
- **Smartphone (Tab):** relógio digital do jogo (o tempo passa sozinho, começa às 08:00) e barra de bateria que descarrega em tempo real (mais rápido com o celular aberto). Com **0%** a tela apaga e o celular não abre mais.
- **Painéis solares (E):** perto de um painel, aperte E para recarregar o celular até 100%. Só funciona de **dia (06:00–18:00)**; à noite aparece o aviso *"Sem energia solar: é noite!"*. Funciona mesmo com a bateria zerada (religa o aparelho).
- **Cidade isométrica:** `TileMapLayer` com tiles 128x64 (losango 2:1), ruas de asfalto com faixas gastas e calçadas, variantes sorteadas com semente.
- **Campo de visão (FOV):** `CanvasModulate` escurece o mundo; um `PointLight2D` em forma de cone (90°) sai do personagem na direção em que ele anda (ou do mouse), mais uma luz ambiente fraca ao redor.
- **Dia e noite:** a escuridão acompanha o relógio do celular (amanhecer 05–07h, anoitecer 17–19h).
- **Câmera:** segue o jogador com suavização (lerp) e dá zoom com a roda do mouse.

## Controles
| Tecla | Ação |
|---|---|
| WASD / setas | andar (8 direções) |
| Tab | abrir/fechar o celular |
| E | carregar no painel solar (de dia) |
| Roda do mouse | afastar/aproximar a câmera |

## Como rodar
1. Instale a **Godot 4.7.2** (versão padrão, não .NET).
2. **Gere a arte** (os PNGs não estão no repositório; são gerados por código, de forma determinística):
   ```bash
   pip install pillow
   python3 tools/gen_art.py
   ```
3. Abra a pasta na Godot (ou `godot --path .`) e aperte F5.

## Estrutura
```
project.godot            configurações + ações de entrada (Tab, WASD/setas, E)
main.tscn                cena principal: Darkness, Ground, Player, painéis, Camera, Phone
ui/phone.tscn|.gd        celular: relógio, bateria, avisos, recharge(), sinais
player/player.tscn|.gd   CharacterBody2D: 8 direções, aceleração/atrito, flip do sprite
player/vision.gd         cone de visão (PointLight2D) girando com lerp_angle
world/city_ground.gd     gera o chão da cidade no TileMapLayer
world/iso_camera.gd      câmera que segue o jogador + zoom suave
world/painel_solar.*     Area2D de recarga solar (só de dia)
world/day_night.gd       CanvasModulate que segue o relógio
tools/gen_art.py         gerador da arte (paleta dessaturada estilo Zomboid)
tools/*.gd               testes automatizados, screenshots e demo para vídeo
export_presets.cfg       presets: Windows Desktop, Linux, Web (sem threads)
```

## Testes (headless)
```bash
godot --headless --path . --import
godot --headless --path . -s res://tools/test_player.gd
godot --headless --path . -s res://tools/test_solar.gd
godot --headless --path . -s res://tools/test_vision.gd
```

## Exportar
`export_presets.cfg` já tem **Windows Desktop** (x86_64, PCK embutido), **Linux** e **Web** (`variant/thread_support=false`, funciona no GitHub Pages sem cabeçalhos COOP/COEP). Exemplo:
```bash
godot --headless --path . --export-release "Web" docs/index.html
```

## Licença
MIT.
