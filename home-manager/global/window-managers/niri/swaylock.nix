{ pkgs, ... }:
{
  programs.swaylock = {
    enable = true;

    settings = {
      no-input-feedback-text = true;
      hide-keyboard-layout-indicator = true;
      clock = true;
      screensaver = false;
      fade-in = false;
      affect-awesome = false;
      color = "#0a0e14";
      ring-color = "#73d0ff";
      line-color = "#0a0e14";
      separator-color = "#0a0e14";
      key-hl-color = "#ffb454";
      ring-ver-color = "#bae67e";
      line-ver-color = "#0a0e14";
      ring-wrong-color = "#ff3333";
      line-wrong-color = "#0a0e14";
      text-color = "#bfbab0";
      text-ver-color = "#bfbab0";
      text-wrong-color = "#ff3333";
      inside-color = "#0a0e1480";
      inside-ver-color = "#0a0e1480";
      inside-wrong-color = "#0a0e1480";
      ring-clear-color = "#0a0e1400";
      line-clear-color = "#0a0e1400";
      inside-clear-color = "#0a0e1400";
      font-family = "LiterationMono Nerd Font";
      font-size = 24;
      tscolor = "#0a0e14";
      tsthcolor = "#ffb454";
    };
  };
}
