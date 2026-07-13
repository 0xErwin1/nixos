{ ... }:
{
  xdg.configFile."systemd/user/build.slice".text = ''
    [Unit]
    Description=CPU-capped slice for headless builds

    [Slice]
    CPUQuota=600%
    CPUWeight=50
    IOWeight=50
    TasksMax=infinity
  '';

  xdg.configFile."systemd/user/background.slice".text = ''
    [Unit]
    Description=Low-priority slice for headless background services

    [Slice]
    CPUWeight=25
    IOWeight=25
    TasksMax=infinity
  '';
}
