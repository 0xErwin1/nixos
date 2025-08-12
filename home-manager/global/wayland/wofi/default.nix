{
  program.wofi = {
    enable = true;
    settings = {
      show = "dmenu";
      promt = "Select an option";
      width = 800;
      height = 600;
      location = "center";
      allow_markup = true;
      insensitive = true;
      term = "alacritty";
      columns = 2;
      hide_scroll = false;
      allow_images = true;
      image_size = 32;
      no_actions = true;
    };
    style = ''
      window {
        background-color: #0a0e14;
        border: 2px solid #5277C3;
        border-radius: 8px;
      }

      #input {
        font-family: "LiterationMono Nerd Font";
        font-size: 16px;
        color: #e0def4;
        background-color: #1e1e2e;
        border-radius: 6px;
        padding: 6px;
      }

      #entry {
        padding: 8px;
        border-radius: 4px;
      }

      #entry:selected {
        background-color: #5277C3;
        color: white;
      }
    '';
  };
}
