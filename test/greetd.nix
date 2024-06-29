{ self, pkgs }:
pkgs.nixosTest {
  name = "superkey-greetd-test";

  nodes = {
    machine = { pkgs, lib, ... }: {
      imports = [
        (import ./common.nix { inherit self; })
      ];
    };
  };

  testScript = ''
    with subtest("Start machines and prepare"):
        start_all()
        machine.wait_for_unit("multi-user.target")

    with subtest("Verify home-manager installed config files"):
        machine.wait_for_unit("home-manager-pjones.service")
        machine.succeed("test -L /home/pjones/.config/sway/config")

    with subtest("Console login"):
        machine.send_chars("pjones")
        machine.send_key("ret")
        machine.send_chars("password")
        machine.send_key("ret")

    with subtest("Wait for sway to start"):
        machine.wait_for_file("/run/user/1000/wayland-1")
        machine.wait_for_file("/tmp/sway-ipc.sock")
        machine.wait_until_succeeds("pgrep waybar")

    with subtest("Exit sway"):
        machine.execute("su - pjones -c 'swaymsg -t command exit'")
        machine.wait_until_fails("pgrep -x sway")
  '';
}
