{ ... }:

# CPU budgeting for heavy background builds.
#
# Two pieces:
#
# 1. `build.slice` — a systemd user slice with CPUQuota and reduced CPU/IO
#    weight. Anything launched inside it shares a hard budget that cannot
#    exceed the quota, no matter how many parallel rustc/cargo/nix builds
#    run at the same time.
#
# 2. A drop-in for `app.slice` that bumps its CPUWeight, so graphical and
#    interactive apps (browser, Meet, terminals, Hyprland) get scheduler
#    priority over anything in build.slice when the CPU is saturated.
#
# Usage from the shell: `cap <cmd...>` (defined in zsh.nix) runs <cmd> inside
# build.slice. Example: `cap cargo build`, `cap nix build .#foo`.

{
  # Background build slice — capped to 7 of 12 hyperthreads, low weight.
  # Adjust CPUQuota if you change CPU or want a tighter/looser cap.
  xdg.configFile."systemd/user/build.slice".text = ''
    [Unit]
    Description=CPU-capped slice for background builds (cargo, nix, rustc, etc.)

    [Slice]
    CPUQuota=700%
    CPUWeight=50
    IOWeight=50
    TasksMax=infinity
  '';

  xdg.configFile."systemd/user/background.slice".text = ''
    [Unit]
    Description=Low-priority slice for background services

    [Slice]
    CPUWeight=25
    IOWeight=25
    TasksMax=infinity
  '';

  # Give interactive apps higher scheduler priority than background builds.
  # Default CPUWeight is 100; build.slice is 50, app.slice becomes 300.
  xdg.configFile."systemd/user/app.slice.d/priority.conf".text = ''
    [Slice]
    CPUWeight=300
  '';
}
