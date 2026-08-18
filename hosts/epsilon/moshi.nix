{ ... }:
# Host side of Moshi, the phone terminal that attaches to this machine.
#
# The phone connects over SSH, which is already configured, and optionally over
# Mosh, which is not the same transport: Mosh authenticates through SSH once and
# then speaks its own UDP protocol, so a session survives losing the network and
# changing address, which is what a phone does all day.
#
# Everything above the transport is already here: herdr is the multiplexer the
# app drives, and it is declared per-user alongside its configuration.
{
  # This opens 60000-61000/udp, the range mosh-server picks a port from. The SSH
  # port it authenticates through is already open: this host runs sshd on 22222,
  # which is the port the app has to be told, since it is not the default.
  programs.mosh.enable = true;
}
