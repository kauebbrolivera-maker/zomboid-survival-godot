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
player/player.tscn|.gd   CharacterBody2D: física 2D + modelo 3D pixelizado em SubViewport
player/character_model.gd componente do modelo: GLB de IA, idle/walk/run, encaixes nos ossos
shaders/pixel_outline    contorno de 1 pixel em volta do modelo 3D
art/models/              modelos .glb (teste: RobotExpressive, CC0)
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
godot --headless --path . -s res://tools/test_anim.gd   # rotação 8 direções
godot --headless --path . -s res://tools/test_glb.gd    # pipeline de GLB
```

## Personagens com IA

O jogador é um modelo 3D renderizado num `SubViewport` de baixa resolução (pixelizado, com contorno). O nó **Player > ModelView > SubViewport > World3D > Model** usa o componente `character_model.gd`, que aceita qualquer personagem **GLB com esqueleto (rig)**, inclusive os gerados por IA.

### Fluxo recomendado
1. **Gerar** um personagem *low-poly*, estilo sobrevivente (roupas simples, cores apagadas), por texto ou imagem. Pose em T ou A ajuda o auto-rig.
2. **Auto-rig + animações** básicas: `idle`, `walk`, `run` (no Mixamo, marque "In Place" para não sair do lugar).
3. **Exportar em GLB** (glTF binário), com as animações embutidas.
4. Copiar para `res://art/models/` (o Godot importa sozinho).
5. No editor: selecione **Player > ModelView > SubViewport > World3D > Model** e, no Inspector, arraste o `.glb` para **Model Scene**.
6. Ajuste **Target Height** (altura em unidades 3D, padrão 1,8) e **Model Yaw Offset Deg** (use `180` se o boneco andar de costas).
7. Se os nomes das animações forem estranhos, preencha **Animation Map**, ex.: `{"idle": "Armature|Breathing", "walk": "Armature|Walk_02"}`.
8. Rode o jogo. O boneco provisório some e o modelo novo gira, anda e fica parado com as animações certas.

### Ferramentas
| Ferramenta | Para quê |
|---|---|
| **Fal.ai** | text-to-3D / image-to-3D (Hunyuan3D, Tripo, Meshy etc. via API) |
| **Meshy** | modelo por texto/imagem, tem auto-rig e animações |
| **Tripo** | modelo por texto/imagem, bom para low-poly, rig automático |
| **Hunyuan 3D** | modelo por imagem/texto (Tencent) |
| **Sloyd** | modelos paramétricos + rig + animações prontas |
| **Ludo.ai** | pipeline completo: modelo + rig + animação |
| **Idyllic** | personagens já com idle/walk |
| **Summer Engine** | gera, faz rig, anima e testa na cena |
| **Kinemo Studio** | auto-rig + animação por texto |
| **Mixamo** (Adobe) | auto-rig gratuito + biblioteca de animações (exporta FBX; converta para GLB no Blender) |

> ⚠️ **Licenças:** confira os termos de cada ferramenta (e do plano usado) antes de uso **comercial**; alguns planos gratuitos não permitem ou exigem atribuição.
> ⚠️ **Polígonos:** mantenha o modelo leve (idealmente < 5 a 10 mil triângulos, texturas ≤ 1024 px). Ele aparece com ~40x56 pixels, então detalhe extra não aparece e só pesa.

### Dicas de nomes de animação
- A detecção automática procura, sem diferenciar maiúsculas: **idle** (`idle`, `breath`, `stand`), **walk** (`walk`) e **run** (`run`, `sprint`, `jog`).
- O prefixo `Armature|` e nomes como `mixamo.com` são aceitos; variações como `WalkJump`, `Walk_Back` e `Run_Left` são ignoradas.
- O melhor é renomear no Blender ou na ferramenta para `Idle`, `Walk` e `Run`.
- Faltando `run`, usa `walk`. Faltando `idle`, usa o primeiro quadro de `walk`.
- O `Player` passa a velocidade relativa: até `walk_threshold` fica parado, até `run_threshold` (1,2) anda, e acima disso corre (útil quando houver corrida).

### Encaixes (roupas, mochilas, armas)
`Model.get_attach_point("right_hand")` e `get_attach_point("spine")` devolvem um `BoneAttachment3D` que segue o osso (ex.: `mixamorig:RightHand`, `hand.R`, `mixamorig:Spine2`), detectado automaticamente ou definido em **Right Hand Bone** / **Spine Bone**. Sem GLB, devolvem os `Marker3D` de `Model/Equipment`.

### Modelo de teste
`art/models/test_character.glb` = **RobotExpressive**, de Tomás Laulhé (Quaternius), **CC0 1.0** (domínio público), com modificações de Don McCurdy, obtido dos exemplos do three.js. Por ser binário, ele **não está no GitHub**: baixe de `https://raw.githubusercontent.com/mrdoob/three.js/dev/examples/models/gltf/RobotExpressive/RobotExpressive.glb` e salve como `art/models/test_character.glb`.

## Exportar
`export_presets.cfg` já tem **Windows Desktop** (x86_64, PCK embutido), **Linux** e **Web** (`variant/thread_support=false`, funciona no GitHub Pages sem cabeçalhos COOP/COEP). Exemplo:
```bash
godot --headless --path . --export-release "Web" docs/index.html
```

## Licença
MIT.
