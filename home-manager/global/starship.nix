{
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      scan_timeout = 60;
      command_timeout = 10000;
      cmd_duration = {
        format = "[$duration]($style) ";
      };
      username.disabled = true;
      hostname.disabled = true;
      directory = {
        format = "[$path]($style) ";
        style = "bold yellow";
        truncation_length = 8;
        use_os_path_sep = true;
        truncate_to_repo = false;
      };
      nix_shell = {
        format = "[$symbol$path]($style) ";
        symbol = " ";
      };
      direnv = {
        symbol = " ";
        disabled = false;
        loaded_msg = "✓";
        unloaded_msg = "✗";
        allowed_msg = "󰄭 ";
        not_allowed_msg = " ";
        denied_msg = "";
      };
      status = {
        disabled = false;
        format = "[$status]($style) ";
        symbol = "";
        not_found_symbol = " ";
        not_executable_symbol = " ";
        sigint_symbol = " ";
        map_symbol = true;
      };
      sudo = {
        format = "[$symbol]($style) ";
        style = "bold red";
        symbol = " ";
      };
      git_commit = {
        format = "[$symbol$commit]($style) ";
      };
      git_branch = {
        format = "[$symbol$branch(:$remote_branch)]($style) ";
      };
      jobs = {
        number_threshold = 1;
        symbol_threshold = 1;
        threshold = 1;
        symbol = " ";
      };
      package = {
        format = "[$symbol$version]($style) ";
        symbol = "󰏗 ";
      };
      c = {
        disabled = false;
        symbol = " ";
        format = "[$symbol($version(-$name))]($style) ";
      };
      cmake = {
        format = "[$symbol($version)]($style) ";
        symbol = " ";
      };
      python = {
        format = "[$symbol$pyenv_prefix($version)(\\($virtualenv\\) )]($style) ";
        symbol = " ";
        pyenv_prefix = " ";
      };
      nodejs = {
        format = "[$symbol($version)]($style) ";
        symbol = "󰎙 ";
      };
      php = {
        format = "[$symbol($version)]($style) ";
        symbol = " ";
      };
      java = {
        format = "[$symbol($version)]($style) ";
        style = "red dimmed bold";
        symbol = " ";
      };
      rust = {
        symbol = "󱘗 ";
        format = "[$symbol($version)]($style)";
      };
      golang = {
        format = "[$symbol($version)]($style) ";
        symbol = "󰟓 ";
      };
      deno = {
        format = "[$symbol ($version)]($style) ";
        symbol = "🦕 ";
        style = "bold green";
      };
      scala = {
        format = "[$symbol($version)]($style) ";
        symbol = " ";
        style = "red bold";
      };
      aws = {
        format = "[$symbol$profile]($style) ";
        symbol = "  ";
        style = "bold blue";
      };
      crystal = {
        format = "[$symbol ($version)]($style) ";
        symbol = " ";
      };
      nim = {
        format = "[$symbol($version)]($style) ";
        symbol = " ";
      };
      ocaml = {
        format = "[$symbol$version]($style) ";
        symbol = " ";
      };
    };
  };
}
