#!/usr/bin/env python3
"""Gera um PropData .tres para cada sprite em assets/isometric_tiles/.

Cada PNG é uma imagem 500x500 contendo um único objeto com muita
margem transparente. Este script calcula a região com conteúdo real
(bbox do canal alpha) e uma escala que faz o objeto ocupar o número de
tiles definido em FOOTPRINTS, no grid top-down de 32x32.

ATENÇÃO: a arte em assets/isometric_tiles/ é desenhada em perspectiva
isométrica e não encaixa visualmente numa câmera top-down. Estes
resources existem para manter o pipeline funcionando; troque os PNGs
por arte top-down e rode este script de novo.

Uso:  python3 tools/generate_prop_resources.py
"""

import re
from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parent.parent
SPRITE_DIR = REPO / "assets" / "isometric_tiles"
OUT_DIR = REPO / "data" / "props"

TILE_SIZE = 32

# Categorias por padrão no nome do arquivo. A primeira que casar vence,
# então os padrões mais específicos vêm antes dos genéricos.
CATEGORY_PATTERNS = [
    (r"rug|woodtexture", "FLOOR"),
    (r"brickswall|window", "WALL"),
    (r"bricks", "WALL"),
    (r"stair|slope|arch|pillar|ladder|door|pit|lever", "STRUCTURE"),
    (r"chair|table|bookcase|bookcase-back", "FURNITURE"),
    (r"chest|barrel|crate", "CONTAINER"),
    (r"candle|torch", "LIGHT"),
    (r"tree|bush|rock", "NATURE"),
]
DEFAULT_CATEGORY = "DECOR"

# Largura desejada em tiles por categoria.
FOOTPRINTS = {
    "FLOOR": 1.0,
    "WALL": 1.0,
    "STRUCTURE": 1.0,
    "FURNITURE": 1.0,
    "CONTAINER": 0.7,
    "LIGHT": 0.4,
    "NATURE": 1.5,
    "DECOR": 0.5,
}

BLOCKING = {"WALL", "STRUCTURE", "FURNITURE", "CONTAINER", "NATURE"}
INTERACTABLE = {"CONTAINER", "LIGHT", "STRUCTURE"}
LIGHT_ENERGY = {"isocandlelit": 0.6, "isowalltorch": 0.8, "isowalltorch2": 0.8}

# Nomes legíveis para os prefixos mais comuns.
DISPLAY_NAMES = {
    "isocube": "Cubo",
    "isotree": "Árvore",
    "isobush": "Arbusto",
    "isorock": "Rocha",
    "isocrate": "Caixote",
    "isochest": "Baú",
    "isobarrel": "Barril",
    "isobones": "Ossos",
    "isobook": "Livro",
    "isogold": "Ouro",
    "isoladder": "Escada de mão",
    "isolever": "Alavanca",
    "isorug": "Tapete",
    "isobanner": "Estandarte",
    "isocandle": "Vela",
    "isocandlelit": "Vela acesa",
    "isowalltorch": "Tocha de parede",
    "isowindow": "Janela",
    "isodoorwood1": "Porta de madeira",
    "isodoorwood2": "Porta de madeira",
    "isopillar": "Pilar",
    "isosquare-pillar1": "Pilar quadrado",
    "isotableround": "Mesa redonda",
    "isotablesquare": "Mesa quadrada",
    "isochair1": "Cadeira",
    "isochair2": "Cadeira",
    "isochair3": "Cadeira",
    "isochair4": "Cadeira",
    "isobookcase": "Estante",
    "isoempty-bookcase": "Estante vazia",
    "isobricks": "Tijolos",
    "isobrickswall": "Parede de tijolos",
    "isostair": "Escada",
    "isoslope": "Rampa",
    "isoarch": "Arco",
    "iso-pit": "Fosso",
    "isowoodtexture": "Piso de madeira",
    "isoassets": "Diversos",
    "isoarchporticullis": "Grade levadiça",
}


def categorize(stem: str) -> str:
    lowered = stem.lower()
    for pattern, category in CATEGORY_PATTERNS:
        if re.search(pattern, lowered):
            return category
    return DEFAULT_CATEGORY


def display_name_for(stem: str) -> str:
    lowered = stem.lower()
    if lowered in DISPLAY_NAMES:
        return DISPLAY_NAMES[lowered]
    # Tenta casar removendo o sufixo numérico (isobricks3 -> isobricks)
    base = re.sub(r"\d+$", "", lowered)
    if base in DISPLAY_NAMES:
        suffix = lowered[len(base):]
        return f"{DISPLAY_NAMES[base]} {suffix}".strip()
    return stem


def read_uid(png_path: Path) -> str:
    """Lê o uid gerado pelo Godot no .import ao lado do PNG."""
    import_file = png_path.with_suffix(png_path.suffix + ".import")
    if not import_file.exists():
        return ""
    match = re.search(r'^uid="([^"]+)"', import_file.read_text(), re.MULTILINE)
    return match.group(1) if match else ""


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    script_uid_line = 'path="res://scripts/world/prop_data.gd"'

    generated = 0
    for png in sorted(SPRITE_DIR.glob("*.png")):
        stem = png.stem
        image = Image.open(png).convert("RGBA")
        bbox = image.getbbox()
        if bbox is None:
            print(f"pulando {png.name}: totalmente transparente")
            continue

        left, top, right, bottom = bbox
        width, height = right - left, bottom - top

        category = categorize(stem)
        footprint = FOOTPRINTS[category]
        scale = round(TILE_SIZE * footprint / max(width, height), 4)

        uid = read_uid(png)
        uid_attr = f'uid="{uid}" ' if uid else ""

        content = f"""[gd_resource type="Resource" script_class="PropData" load_steps=3 format=3]

[ext_resource type="Script" {script_uid_line} id="1_script"]
[ext_resource type="Texture2D" {uid_attr}path="res://assets/isometric_tiles/{png.name}" id="2_tex"]

[resource]
script = ExtResource("1_script")
id = "{stem}"
display_name = "{display_name_for(stem)}"
category = {list(FOOTPRINTS).index(category)}
texture = ExtResource("2_tex")
content_region = Rect2i({left}, {top}, {width}, {height})
suggested_scale = {scale}
footprint_tiles = {footprint}
blocks_movement = {str(category in BLOCKING).lower()}
interactable = {str(category in INTERACTABLE).lower()}
light_energy = {LIGHT_ENERGY.get(stem.lower(), 0.0)}
"""
        (OUT_DIR / f"{stem}.tres").write_text(content)
        generated += 1

    print(f"{generated} resources gerados em {OUT_DIR.relative_to(REPO)}")


if __name__ == "__main__":
    main()
