# Xmonad

![Xmonad](../.screenshots/xmonad.png)

## Installation
```sh
# ArchLinux
sudo pacman -S xmonad xmonad-contrib xmobar trayer xdotol --noconfirm
paru -S nerd-fonts-ubuntu-mono

git clone https://github.com/KaiserErwin/dotfiles.git
cp -r dotfiles/.xmonad ~/
cp -r dotfiles/.config/xmobar ~/.config
```
*Xmobar* uses scripts located in **[~/.local/bin](https://github.com/KaiserErwin/dotfiles/tree/master/.local/bin)**

```sh
cp dotfiles/.local/bin/percentage ~/.local/bin/
cp dotfiles/.local/bin/battery ~/.local/bin/
cp dotfiles/.local/bin/brightness ~/.local/bin/
cp dotfiles/.local/bin/volume ~/.local/bin/

sudo pacman -S pacman-contrib brightnessctl pamixer upower --noconfirm
```
