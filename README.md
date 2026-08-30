# Dotfiles propios — setup wlroots mínimo (sin Noctalia, sin shell)

Filosofía: **cero dependencias de Noctalia ni de ninguna desktop shell**. Solo
herramientas wlroots independientes que corren idénticas en **mango** (mangowm)
y **niri** (ambos compositores wlroots).

## Componentes (compositor-agnósticos)
| Función        | App            | Estado 2026-08-29 |
|----------------|----------------|-------------------|
| Barra          | `waybar`       | ✅ instalado + linkeado |
| Launcher       | `fuzzel`       | ✅ instalado + linkeado |
| Notificaciones | `mako`         | ✅ instalado + linkeado |
| Lock           | `swaylock`     | ✅ instalado |
| Idle/lock      | `swayidle`     | ✅ instalado |
| Clipboard      | `cliphist`+`wl-clipboard` | ✅ instalados |
| Wallpaper      | `awww` (provee `swww`) | ✅ instalado |
| Screenshots    | `grim`+`slurp` | ✅ instalados |
| Greeter        | `greetd-tuigreet` (bin `tuigreet`) | ✅ activo |
| Polkit agent   | `polkit-kde` | ✅ (fallback en start-common.sh) |

## Instalación ya completada
```bash
sudo pacman -S mako fuzzel swayidle greetd-tuigreet grim slurp awww --needed
# awww provee swww - el binario real es /usr/bin/awww
```

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

## Activar (completado 2026-08-29 con Kira)
1. ✅ `chmod +x scripts/start-common.sh` + fix `awww`/`swww` y typo `wallpaper.sh`
2. ✅ Symlink de sesiones: `/usr/share/wayland-sessions/mango.desktop` y `niri.desktop`
3. ✅ `greetd` ya en `tuigreet --time --remember --remember-session --asterisks`
4. ✅ Symlinks `~/.config/waybar|mako|fuzzel|swaylock → ~/dotfiles/*`
5. ✅ `~/.config/niri/config.kdl` limpio (quitado `hypridle` noctalia, usa `swayidle` de start-common.sh)
6. ✅ `~/.config/mango/config.conf` ya sin binds noctalia (fuzzel/power-menu/wallpaper)
7. Próximo: probar en VT y luego `sudo pacman -Rns noctalia noctalia-greeter`

## Rollback
Restaurar backups en `~/backups/noctalia-2026-08-29/` y
`/etc/greetd/config.toml.pre-noctalia`, reinstalar noctalia.
