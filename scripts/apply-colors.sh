#!/bin/sh
# apply-colors.sh — wallbash con pywal + matugen
# Uso: apply-colors.sh /ruta/a/wallpaper.jpg [--no-wallpaper] [--vantablack]
# Genera colores y aplica a foot/waybar/mango/mako/fuzzel

WALLPAPER="$1"
MODE="${2:-auto}"  # auto | vantablack | pywal

if [ -z "$WALLPAPER" ] && [ "$MODE" != "vantablack" ]; then
  WALLPAPER="$HOME/.config/dotfiles/wallpaper.png"
fi

# Asegurar PATH para pipx
export PATH="$HOME/.local/bin:$PATH"

# VANTABLACK ESTÁTICO
apply_vantablack() {
  echo "[apply-colors] Aplicando Vanta Black estático..."

  # Foot - Vanta Black puro
  cat > ~/.config/foot/themes/vantablack <<'FOOT'
[colors-dark]
foreground=e5e5e5
background=000000
selection-foreground=ffffff
selection-background=1a1a1a
jump-labels=ffffff 1a1a1a
scrollback-indicator=000000 333333
urls=888888
alpha=0.96
cursor=e5e5e5 000000
regular0=000000
regular1=8c1d1d
regular2=4a5a3c
regular3=6b6b4a
regular4=2a4a6b
regular5=4a3a5a
regular6=3a5a5a
regular7=e5e5e5
bright0=333333
bright1=aa2a2a
bright2=6a7a5a
bright3=8a8a6a
bright4=3a6a9a
bright5=6a4a7a
bright6=4a7a7a
bright7=ffffff
dim0=1a1a1a
dim1=5a1a1a
dim2=3a3a2a
dim3=4a4a3a
dim4=1a2a3a
dim5=2a1a2a
dim6=1a3a3a
dim7=8a8a8a
FOOT

  # Mango - Vanta Black
  cat > ~/.cache/wal/mango-colors.conf <<'MANGO'
bordercolor=0x1a1a1aff
focuscolor=0xffffffff
urgentcolor=0xaa2a2aff
globalcolor=0x888888ff
overlaycolor=0x444444ff
rootcolor=0x000000ff
maximizescreencolor=0x1a1a1aff
scratchpadcolor=0x000000ff
dropcolor=0xffffff22
splitcolor=0x333333ff
MANGO

  # Mako
  mkdir -p ~/.config/mako
  cat > ~/.config/mako/config <<'MAKO'
font=JetBrainsMono Nerd Font 10
background-color=#000000f2
text-color=#e5e5e5
border-size=1
border-color=#333333
border-radius=10
padding=12
margin=12
width=360
height=150
default-timeout=4000
max-visible=4
sort=-time
layer=overlay
anchor=top-right
progress-color=over #1a1a1a
[urgency=high]
background-color=#aa2a2af2
text-color=#ffffff
border-color=#aa2a2a
[urgency=low]
background-color=#0a0a0af2
text-color=#888888
border-color=#1a1a1a
MAKO

  # Fuzzel
  mkdir -p ~/.config/fuzzel
  cat > ~/.config/fuzzel/fuzzel.ini <<'FUZZEL'
[main]
font=JetBrainsMono Nerd Font:size=11
width=42
lines=12
line-height=24
inner-pad=12
horizontal-pad=16
vertical-pad=10
anchor=center
[colors]
background=000000f0
text=e5e5e5ff
placeholder=666666ff
input=e5e5e5ff
match=ffffffff
selection=1a1a1aff
selection-text=ffffffff
selection-match=aaaaaaff
border=333333ff
counter=666666ff
[border]
width=1
radius=12
selection-radius=8
FUZZEL

  # Actualizar foot.ini para usar vantablack
  if ! grep -q "vantablack" ~/.config/foot/foot.ini; then
    sed -i "s|include=.*|include=~/.config/foot/themes/vantablack|" ~/.config/foot/foot.ini
  else
    sed -i "s|include=.*|include=~/.config/foot/themes/vantablack|" ~/.config/foot/foot.ini
  fi

  # Señalizar mango include
  if ! grep -q "mango-colors.conf" ~/.config/mango/config.conf; then
    echo "include=~/.cache/wal/mango-colors.conf" >> ~/.config/mango/config.conf
  fi

  pkill -USR1 mako 2>/dev/null || (pkill mako; mako &)
  pkill -SIGUSR2 waybar 2>/dev/null || true
  notify-send "Vanta Black" "Tema puro negro aplicado" -i "$WALLPAPER" 2>/dev/null || true
  echo "[apply-colors] Vanta Black listo"
  return
}

apply_pywal() {
  IMG="$1"
  echo "[apply-colors] Pywal con $IMG"
  # Limpiar cache si imagen distinta
  wal -i "$IMG" -n --cols16 lighten 2>&1 | tail -n 5
  # wal ya generó templates en ~/.cache/wal/
  # Linkear foot
  mkdir -p ~/.config/foot/themes
  cp ~/.cache/wal/colors-foot-dark.ini ~/.config/foot/themes/pywal 2>/dev/null
  sed -i "s|include=.*|include=~/.config/foot/themes/pywal|" ~/.config/foot/foot.ini

  # Mako - pywal ya tiene colors-mako? usar nuestro template colors-mako
  if [ -f ~/.cache/wal/colors-mako ]; then
    cp ~/.cache/wal/colors-mako ~/.config/mako/config 2>/dev/null
    # Añadir header si falta
    if ! grep -q "font=" ~/.config/mako/config; then
      cat ~/.cache/wal/colors-mako > ~/.config/mako/config
    fi
  fi
  # Fuzzel - pywal genera colors-fuzzel.ini? nuestro template es colors-fuzzel?
  if [ -f ~/.cache/wal/colors-fuzzel.ini ]; then
    mkdir -p ~/.config/fuzzel
    # Convertir pywal template a fuzzel.ini completo
    cat ~/.cache/wal/colors-fuzzel.ini > ~/.config/fuzzel/fuzzel.ini
    # Asegurar main section
    if ! grep -q "^\[main\]" ~/.config/fuzzel/fuzzel.ini; then
      cat > ~/.config/fuzzel/fuzzel.ini <<EOF
[main]
font=JetBrainsMono Nerd Font:size=11
width=42
lines=12
anchor=center
$(cat ~/.cache/wal/colors-fuzzel.ini)
EOF
    fi
  fi

  # Mango colors ya generado como mango-colors.conf
  if ! grep -q "mango-colors.conf" ~/.config/mango/config.conf; then
    echo "include=~/.cache/wal/mango-colors.conf" >> ~/.config/mango/config.conf
  fi

  # Waybar dotfiles - pywal (subida + full recolor)
  if [ -f ~/.cache/wal/waybar-vantablack.css ]; then
    cp ~/.cache/wal/waybar-vantablack.css ~/.config/waybar/style.css
  fi
  # Waybar niri - pywal también (para que no revierta en segundo reinicio via systemd)
  if [ -f ~/.cache/wal/waybar-niri.css ]; then
    mkdir -p ~/.config/niri/waybar
    cp ~/.cache/wal/waybar-niri.css ~/.config/niri/waybar/style.css
  elif [ -f ~/.cache/wal/waybar-vantablack.css ]; then
    # fallback si no hay template niri, usar mismo que dotfiles
    mkdir -p ~/.config/niri/waybar
    cp ~/.cache/wal/waybar-vantablack.css ~/.config/niri/waybar/style.css
  fi

  # Wofi - pywal tintado con preview
  if [ -f ~/.cache/wal/wofi-style.css ]; then
    mkdir -p ~/.config/wofi
    cp ~/.cache/wal/wofi-style.css ~/.config/wofi/style.css
  fi
  # Rofi wallpaper selector - grid con preview
  if [ -f ~/.cache/wal/rofi-wallpaper-selector.rasi ]; then
    mkdir -p ~/.config/rofi
    cp ~/.cache/wal/rofi-wallpaper-selector.rasi ~/.config/rofi/wallpaper-selector.rasi
  fi

  # Matugen adicional para material (opcional)
  if command -v matugen >/dev/null 2>&1; then
    matugen image "$IMG" --mode dark 2>&1 | tail -n 5 || true
  fi

  pkill -USR1 mako 2>/dev/null || (pkill mako; mako >/dev/null 2>&1 &)
  pkill -SIGUSR2 waybar 2>/dev/null || (pkill waybar; waybar >/dev/null 2>&1 &)
  notify-send "Wallbash" "Colores generados de $(basename "$IMG")" -i "$IMG" 2>/dev/null || true
  echo "[apply-colors] Pywal aplicado"
}

# Main
if [ "$MODE" = "vantablack" ] || [ "$1" = "--vantablack" ]; then
  apply_vantablack
  exit 0
fi

if [ "$1" = "--no-wallpaper" ]; then
  apply_pywal "$WALLPAPER"
  exit 0
fi

if [ -f "$WALLPAPER" ]; then
  # Copiar wallpaper y aplicar con awww
  mkdir -p ~/.config/dotfiles
  cp "$WALLPAPER" ~/.config/dotfiles/wallpaper.png
  ln -sf "$WALLPAPER" ~/.config/dotfiles/wallpaper.current 2>/dev/null
  if command -v awww >/dev/null 2>&1; then
    pgrep -x awww-daemon >/dev/null 2>&1 || (awww-daemon 2>/dev/null & sleep 0.8)
    awww img "$WALLPAPER" 2>/dev/null
  fi
  # Aplicar colores auto
  apply_pywal "$WALLPAPER"
else
  echo "Wallpaper no encontrado: $WALLPAPER"
  exit 1
fi
