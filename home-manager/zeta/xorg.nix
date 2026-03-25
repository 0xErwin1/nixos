{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      solaar
    ];
  };

  xsession = {
    profileExtra = ''
      export XCURSOR_THEME=Bibata-Modern-Classic
      export XCURSOR_SIZE=16
    '';
  };
}
