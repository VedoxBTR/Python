# Dotfiles propios — setup wlroots mínimo (sin Noctalia, sin shell)

Filosofía: **cero dependencias de Noctalia ni de ninguna desktop shell**. Solo
herramientas wlroots independientes que corren idénticas en **mango** (mangowm)
y **niri** (ambos compositores wlroots).

## Componentes (compositor-agnósticos)
| Función        | App            | Estado        |
|----------------|----------------|---------------|
| Barra          | `waybar`       | instalado     |
| Launcher       | `fuzzel`       | por instalar  |
| Notificaciones | `mako`         | por instalar  |
| Lock           | `swaylock`     | instalado     |
| Idle/lock      | `swayidle`     | por instalar  |
| Clipboard      | `cliphist`+`wl-clipboard` | instalados |
| Wallpaper      | `swww`         | instalado     |
| Screenshots    | `grim`+`slurp` | por instalar  |
| Greeter        | `greetd-tuigreet` (bin `tuigreet`) | por instalar  |
| Polkit agent   | `polkit-gnome` | por instalar  |

## Instalar (requiere sudo — hacer cuando vuelvas / haya huella)
```
sudo pacman -S mako fuzzel swayidle greetd-tuigreet grim slurp
```
> El paquete es `greetd-tuigreet`; el binario resultante es `/usr/bin/tuigreet`
> (la config de greetd usa `/usr/bin/tuigreet`).
> Nota: el agente polkit ya está cubierto por `polkit-kde-authentication-agent-1`
> (presente). `start-common.sh` lo reusará; no hace falta instalar `polkit-gnome`.
> Si prefieres un agente sin dependencias KDE, instala `polkit-gnome` y listo.

## Estructura
```
dotfiles/
├── scripts/start-common.sh   # lanza waybar+mako+swayidle+swww+polkit y luego el compositor
├── sessions/mango.desktop    # entrada wayland-sessions
├── sessions/niri.desktop
├── waybar/                   # barra mínima
├── mako/                     # notificaciones
├── fuzzel/                   # launcher
├── swaylock/                 # lock
└── compositors/              # snippets de binds para mango y niri
```

## Activar (cuando estés de vuelta y con sudo)
1. `chmod +x scripts/start-common.sh`
2. Symlink de sesiones:
   `sudo ln -sf ~/dotfiles/sessions/mango.desktop /usr/share/wayland-sessions/`
   `sudo ln -sf ~/dotfiles/sessions/niri.desktop /usr/share/wayland-sessions/`
3. Cambiar greeter en greetd a tuigreet (ver `Plan quitar noctalia.md`):
   `/etc/greetd/config.toml` → `command = "tuigreet --greetd --asterisk --remember"`
4. Quitar `exec-once=noctalia` y los binds de noctalia en
   `~/.config/mango/config.conf` (ver `compositors/mango-bindings.md`).
5. Probar en una VT alterna antes de reiniciar.
6. Solo tras confirmar login: `sudo pacman -Rns noctalia noctalia-greeter`.

## Rollback
Restaurar backups en `~/backups/noctalia-2026-08-29/` y
`/etc/greetd/config.toml.pre-noctalia`, reinstalar noctalia.
