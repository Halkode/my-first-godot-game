# Survival Horror Top-Down

Jogo de sobrevivência e horror com câmera de cima, inspirado em Darkwood,
Project Zomboid e This War of Mine. O diferencial é um sistema médico
detalhado, em que tratar cada ferimento é um processo com o qual o
jogador interage, e não um clique que cura instantaneamente.

Veja [GAME_DESIGN_ROADMAP.md](GAME_DESIGN_ROADMAP.md) para a análise
técnica, a arquitetura e o roadmap de desenvolvimento.

## Estado atual

- Movimento point-and-click com pathfinding A* em grid top-down de 32x32
- Sistema de saúde por parte do corpo, com sangramento, dor e ferimentos
- Tela de tratamento e minigame de aplicação de bandagem
- Ciclo de dia/noite: um dia completo dura 25 minutos reais
- Catálogo de props em `data/props/`, gerado por
  `tools/generate_prop_resources.py`

## Arte

O projeto começou como uma demo isométrica e está sendo convertido para
top-down. Os tilesets já usam grid quadrado de 32x32, mas os sprites em
`assets/isometric_tiles/` ainda são desenhados em perspectiva isométrica
e precisam ser substituídos por arte top-down. Depois de trocar os PNGs,
rode `python3 tools/generate_prop_resources.py` para regenerar os
resources.

Tiles originais: https://godotengine.org/asset-library/asset/2476
