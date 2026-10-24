# Credits

Source and license of every asset in the game.

| File | Source | License |
|---|---|---|
| `assets/characters/soldier.glb` | Made in this repo (`tools/blender/make_soldier.py`); old placeholder, only used by `tools/preview_character.gd` | Our own |
| `assets/characters/skins/male.glb`, `female.glb` | [Meshy](https://www.meshy.ai) API (Pro): Text to Image (nano-banana-pro) + Multi-Image to 3D + Rigging + Animation, clips merged with `tools/meshy/merge_animations.py` | Made with our Meshy Pro account |
| `assets/characters/team_colors/*.jpg` | Made from the models' textures (`tools/meshy/make_team_texture.py`) | Our own |
| `assets/weapons/*.glb` | [Meshy](https://www.meshy.ai) API (Pro): Text to Image (nano-banana-pro) + Image to 3D, `tools/meshy/prepare_model.py` | Made with our Meshy Pro account |
| `assets/props/container.glb`, `crate.glb`, `barrel.glb`, `barrier.glb` | [Meshy](https://www.meshy.ai) API (Pro): Text to Image + Image to 3D, sized with `tools/meshy/prepare_model.py --fit` | Made with our Meshy Pro account |
| `assets/props/colors/*.jpg` | Repainted container texture (`tools/meshy/make_team_texture.py --hue`) | Our own |
| `assets/props/pillar.glb` | Made in this repo (`tools/blender/make_props.py`) | Our own |
| `assets/textures/*` | Meshy Text to Image (nano-banana-2), made tileable + normal maps with `tools/make_tiling_texture.py` | Made with our Meshy Pro account |
| `assets/ui/splash_bg.jpg`, `lobby_bg.jpg` | Meshy Text to Image (nano-banana-pro) | Made with our Meshy Pro account |
| `assets/ui/portrait_*.png`, `weapon_*.png` | Rendered from our models (`tools/render_ui_images.gd`) | Our own |
| `assets/fonts/Rajdhani-*.ttf` | [Rajdhani](https://fonts.google.com/specimen/Rajdhani) by Indian Type Foundry | SIL Open Font License (`assets/fonts/OFL-Rajdhani.txt`) |
| `assets/fonts/Teko-Variable.ttf` | [Teko](https://fonts.google.com/specimen/Teko) by Indian Type Foundry | SIL Open Font License (`assets/fonts/OFL-Teko.txt`) |
| Engine | [Godot Engine](https://godotengine.org) | MIT |
