# The Decryptor's Cell — LÖVE2D

## Lancer le jeu
```
love .
```
(depuis le dossier `DecryptorsCell/`)

Ou avec love.js pour le web :
```
npx love.js . build --title "The Decryptor's Cell"
```

## Contrôles
| Touche | Action |
|--------|--------|
| Flèches / ZQSD | Déplacer le personnage |
| [E] | Interagir avec un objet / la porte |
| Tapez + [Entrée] | Valider dans le terminal |
| [Backspace] | Effacer dans le terminal |
| `aide` | Aide dans le terminal |
| [ESC] | Fermer / Menu |

## Solutions (spoilers)
- **Niveau 1 — César** : tapez `4`
- **Niveau 2 — Vigenère** : tapez `LEMON`
- **Niveau 3 — Vernam** : tapez `xor 42`

## Architecture
```
DecryptorsCell/
├── main.lua              — Entry point LÖVE
├── conf.lua              — Fenêtre 960×640
├── game/
│   ├── Game.lua          — Orchestrateur (états, transitions)
│   ├── Player.lua        — Joueur (mouvement, sprite pixel-art)
│   ├── Room.lua          — Classe de base des salles
│   ├── RoomCaesar.lua    — Niveau 1 : Chiffre de César
│   ├── RoomVigenere.lua  — Niveau 2 : Chiffre de Vigenère
│   ├── RoomVernam.lua    — Niveau 3 : Vernam / XOR
│   ├── GameObject.lua    — Objets interactifs
│   └── Terminal.lua      — Interface de déchiffrement
└── systems/
    ├── Renderer.lua      — Palette, fonts, CRT, helpers
    ├── UIManager.lua     — HUD, panel, keypad, modals, menus
    ├── CryptoEngine.lua  — César, Vigenère, Vernam/XOR
    └── AudioManager.lua  — Stub audio
```
