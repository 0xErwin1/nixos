# BSPWM

![bspwm](../../.screenshots/BSPWM.png)

## Installation
```sh
# ArchLinux
sudo pacman -S bspwm sxhkd polybar --noconfirm
yay -S nerd-fonts-ubuntu-mono

git clone https://github.com/KaiserErwin/dotfiles.git
cp -r dotfiles/.config/bspwm ~/.config/bspwm/
cp -r dotfiles/.config/sxhkd ~/.config/sxhkd/
cp -r dotfiles/.config/polybar ~/.config/polybar/
```
*Polybar* uses scripts located in **[~/.local/bin](https://github.com/KaiserErwin/dotfiles/tree/master/.local/bin)**

```sh
cp dotfiles/.local/bin/percentage ~/.local/bin/
cp dotfiles/.local/bin/battery ~/.local/bin/
cp dotfiles/.local/bin/brightness ~/.local/bin/
cp dotfiles/.local/bin/volume ~/.local/bin/

# In ~/.xprofile
export PATH=$HOME/.local/bin:$PATH

sudo pacman -S pacman-contrib brightnessctl pamixer upower --noconfirm
```



