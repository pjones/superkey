{ self, pkgs }:
pkgs.nixosTest {
  name = "superkey-sway-test";

  nodes = {
    machine = { pkgs, lib, ... }: {
      imports = [
        (import ./common.nix { inherit self; })
      ];

      services.greetd.enable = lib.mkForce false;
      services.getty.autologinUser = "pjones";
      environment.systemPackages = [ pkgs.fastfetch ];

      programs.bash.loginShellInit = ''
        if [ "$(tty)" = "/dev/tty1" ]; then
          sway --validate
          sway && touch /tmp/sway-exit-ok
        fi
      '';
    };
  };

  testScript = ''
    with subtest("Start machines and prepare"):
        start_all()
        machine.wait_for_unit("multi-user.target")

    with subtest("Verify home-manager installed config files"):
        machine.wait_for_unit("home-manager-pjones.service")
        machine.succeed("test -L /home/pjones/.config/emacs/init.el")

    with subtest("Wait for sway to start"):
        machine.wait_for_file("/run/user/1000/wayland-1")
        machine.wait_for_file("/tmp/sway-ipc.sock")
        machine.wait_until_succeeds("pgrep waybar")

    with subtest("Run sway tests"):
        machine.copy_from_host(
            "${./stage-for-screenshot.sh}",
            "/tmp/stage.sh",
        )
        machine.succeed(
            "su - pjones -c 'swaymsg -t command exec bash /tmp/stage.sh'"
        )
        machine.wait_for_file("/run/user/1000/emacs/1:Hacking")

    with subtest("Test screen locking"):
        machine.succeed(
            "su - pjones -c 'swaymsg -t command exec loginctl lock-session'"
        )
        machine.wait_until_succeeds("pgrep -x swaylock")
        machine.sleep(1)
        machine.screenshot("lock")
        machine.send_chars("password")
        machine.send_key("ret")
        machine.wait_until_fails("pgrep -x swaylock")

    with subtest("Wait to get a screenshot"):
        machine.sleep(5)
        machine.screenshot("screen")

    with subtest("Exit sway"):
        machine.execute("su - pjones -c 'swaymsg -t command exit'")
        machine.wait_until_fails("pgrep -x sway")
        machine.wait_for_file("/tmp/sway-exit-ok")
  '';
}
