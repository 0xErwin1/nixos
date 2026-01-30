# Leftwm

![leftwm](../../.screenshots/leftwm.png)

## Installation
```sh
# ArchLinux
paru -S leftwm leftwm-theme eww polybar

git clone https://github.com/KaiserErwin/dotfiles.git
cp -r dotfiles/.config/leftwm ~/.config/bspwm/

leftwm-theme applay ayu-eww

cp dotfiles/.local/bin/percentage ~/.local/bin/
cp dotfiles/.local/bin/battery ~/.local/bin/
cp dotfiles/.local/bin/brightness ~/.local/bin/
cp dotfiles/.local/bin/volume ~/.local/bin/

# In ~/.xprofile
export PATH=$HOME/.local/bin:$PATH

sudo pacman -S pacman-contrib brightnessctl pamixer upower --noconfirm
```



