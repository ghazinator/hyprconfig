#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Sudo Check --- (NEW)
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo."
  exit
fi

# Define color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- Main Functions ---

install_packages() {
    echo -e "${GREEN}---> Installing necessary packages...${NC}"
    
    # The full list of packages needed for your setup
    PACKAGES=(
        hyprland hyprpaper waybar wofi swaylock dunst alacritty
        pcmanfm firefox qt5-wayland qt6-wayland polkit-kde
        pipewire wireplumber pavucontrol wpctl playerctl brightnessctl
        flameshot noto-fonts noto-fonts-emoji ttf-font-awesome
        xdg-desktop-portal-hyprland git
        kdeconnect network-manager-applet # <-- ADDED
    )
    
    pacman -Syu --noconfirm --needed "${PACKAGES[@]}"
    
    echo -e "${GREEN}---> Package installation complete!${NC}"
}

create_configs() {
    # This function needs to run as the user, not root.
    # We use the SUDO_USER variable which is set when you run a script with sudo.
    local user_home="/home/$SUDO_USER"

    echo -e "${GREEN}---> Creating configuration files for user: $SUDO_USER...${NC}"
    
    # Create config directories as the user
    sudo -u "$SUDO_USER" mkdir -p "$user_home/.config/hypr"
    sudo -u "$SUDO_USER" mkdir -p "$user_home/.config/waybar"
    sudo -u "$SUDO_USER" mkdir -p "$user_home/Pictures/Wallpapers" # <-- ADDED

    # Hyprland Config
    sudo -u "$SUDO_USER" tee "$user_home/.config/hypr/hyprland.conf" > /dev/null <<'EOF'
monitor=,preferred,auto,auto
exec-once = waybar
exec-once = hyprpaper
exec-once = dunst
exec-once = kdeconnect-indicator # <-- UPDATED from kdeconnectd
exec-once = /usr/lib/polkit-kde-authentication-agent-1
env = XCURSOR_THEME,breeze_cursors,24
env = GTK_THEME,Breeze
general {
    gaps_in = 5
    gaps_out = 0
    border_size = 2
    col.active_border = rgb(285577)
    col.inactive_border = rgb(5F676A)
    layout = dwindle
}
decoration {
    rounding = 0
    blur { enabled = false }
    drop_shadow = false
}
animations { enabled = false }
dwindle {
    pseudotile = true
    preserve_split = true
}
$mod = SUPER
bind = $mod, D, exec, wofi --show drun
bind = $mod, RETURN, exec, alacritty
bind = $mod SHIFT, B, exec, firefox
bind = $mod SHIFT, D, exec, discord --ozone-platform-hint=auto # <-- UPDATED for Wayland screenshare
bind = $mod SHIFT, F, exec, pcmanfm
bind = $mod SHIFT, RETURN, exec, alacritty -t 'alacritty-float'
bind = $mod SHIFT, X, exec, swaylock
bind = $mod SHIFT, S, exec, flameshot gui
bind = $mod SHIFT, E, exit,
bind = $mod SHIFT, Q, killactive,
bind = $mod, F, fullscreen, 0
bind = $mod, SPACE, togglefloating,
bind = $mod SHIFT, MINUS, pin,
bind = $mod, H, movefocus, l
bind = $mod, L, movefocus, r
bind = $mod, K, movefocus, u
bind = $mod, J, movefocus, d
bind = $mod SHIFT, H, movewindow, l
bind = $mod SHIFT, L, movewindow, r
bind = $mod SHIFT, K, movewindow, u
bind = $mod SHIFT, J, movewindow, d
bind = $mod, 1, workspace, 1
bind = $mod, 2, workspace, 2
bind = $mod, 3, workspace, 3
bind = $mod, 4, workspace, 4
bind = $mod, 5, workspace, 5
bind = $mod, 6, workspace, 6
bind = $mod, 7, workspace, 7
bind = $mod, 8, workspace, 8
bind = $mod, 9, workspace, 9
bind = $mod, 0, workspace, 10
bind = $mod SHIFT, 1, movetoworkspace, 1
bind = $mod SHIFT, 2, movetoworkspace, 2
bind = $mod SHIFT, 3, movetoworkspace, 3
bind = $mod SHIFT, 4, movetoworkspace, 4
bind = $mod SHIFT, 5, movetoworkspace, 5
bind = $mod SHIFT, 6, movetoworkspace, 6
bind = $mod SHIFT, 7, movetoworkspace, 7
bind = $mod SHIFT, 8, movetoworkspace, 8
bind = $mod SHIFT, 9, movetoworkspace, 9
bind = $mod SHIFT, 0, movetoworkspace, 10
bind = $mod, mouse_down, workspace, e+1
bind = $mod, mouse_up, workspace, e-1
bindm = $mod, mouse:272, movewindow
bindm = $mod, mouse:273, resizewindow
bind = $mod, N, exec, dunstctl set-paused toggle
bind = $mod SHIFT, N, exec, dunstctl history-pop
binde=, XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
binde=, XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bind =, XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
bind =, XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
bind =, XF86AudioNext, exec, playerctl next
bind =, XF86AudioPrev, exec, playerctl previous
bind =, XF86AudioPlay, exec, playerctl play-pause
bind =, XF86AudioStop, exec, playerctl stop
binde=, XF86MonBrightnessUp, exec, brightnessctl set +10%
binde=, XF86MonBrightnessDown, exec, brightnessctl set 10-%
windowrulev2 = float, title:^(alacritty-float)$
windowrulev2 = center, title:^(alacritty-float)$
EOF

    # Waybar Config
    sudo -u "$SUDO_USER" tee "$user_home/.config/waybar/config.jsonc" > /dev/null <<'EOF'
{
    "layer": "top", "position": "top", "height": 20, "spacing": 4,
    "modules-left": ["hyprland/workspaces"],
    "modules-center": ["clock"],
    "modules-right": ["network", "pulseaudio", "battery", "disk", "cpu", "memory"],
    "hyprland/workspaces": { "format": "{name}" },
    "network": {
        "format-wifi": "W: {ipaddr} ({signalStrength}%)",
        "format-ethernet": "E: {ipaddr}",
        "format-disconnected": "Offline",
        "tooltip-format": "{ifname} via {gwaddr} ",
        "on-click": "nm-connection-editor"
    },
    "pulseaudio": {
        "format": "V: {volume}% {icon}", "format-muted": "V: muted",
        "format-icons": { "default": ["", "", ""] },
        "on-click": "pavucontrol"
    },
    "battery": {
        "states": { "good": 95, "warning": 30, "critical": 15 },
        "format": "{status} {capacity}% {time}",
        "format-charging": " {capacity}%", "format-plugged": " {capacity}%",
        "format-alt": "{time} {icon}", "format-icons": ["", "", "", "", ""]
    },
    "disk": { "interval": 30, "format": "💾 {free}", "path": "/" },
    "cpu": { "interval": 5, "format": "CPU: {load_avg}", "tooltip": true },
    "memory": { "interval": 5, "format": "MEM: {}%" },
    "clock": {
        "format": "{:%Y-%m-%d %H:%M:%S}",
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>"
    }
}
EOF

    # Waybar CSS
    sudo -u "$SUDO_USER" tee "$user_home/.config/waybar/style.css" > /dev/null <<'EOF'
* { border: none; border-radius: 0; font-family: monospace; font-size: 11px; min-height: 0; }
window#waybar { background-color: #000000; color: #ffffff; transition-property: background-color; transition-duration: .5s; }
#workspaces button { padding: 0 5px; background-color: #222222; color: #888888; }
#workspaces button:hover { background: rgba(0, 0, 0, 0.2); box-shadow: inherit; }
#workspaces button.focused { background-color: #285577; color: #FFFFFF; }
#workspaces button.urgent { background-color: #900000; }
#clock, #battery, #cpu, #memory, #disk, #pulseaudio, #network { padding: 0 10px; color: #ffffff; }
EOF

    # Hyprpaper Config
    sudo -u "$SUDO_USER" tee "$user_home/.config/hypr/hyprpaper.conf" > /dev/null <<'EOF'
preload = ~/Pictures/Wallpapers/your_wallpaper.png
wallpaper = ,~/Pictures/Wallpapers/your_wallpaper.png
EOF

    echo -e "${GREEN}---> Config files created successfully!${NC}"
}

final_instructions() {
    echo -e "\n${YELLOW}--- All Done! ---${NC}"
    echo -e "Your Hyprland environment is set up."
    echo -e "\n${YELLOW}IMPORTANT NEXT STEPS:${NC}"
    echo "1. The wallpaper is set to '~/Pictures/Wallpapers/your_wallpaper.png'."
    echo "   The script has already created the directory for you. Just add an image!"
    echo "2. It's highly recommended to ${YELLOW}reboot${NC} your system now."
    echo "   You can do this by running: ${GREEN}reboot${NC}"
    echo "3. After rebooting, if you don't have a graphical login manager, simply type ${GREEN}Hyprland${NC} at the TTY prompt and press Enter."
    echo -e "\nWelcome to Hyprland!"
}

# --- Script Execution ---

install_packages
create_configs
final_instructions
