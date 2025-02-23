{ self, pkgs }:

let
  withXwininfo = pkgs.appendOverlays [
    (final: prev: {
      xorg = prev.xorg // {
        xwininfo = self.packages.${prev.system}.xwininfo-tests;
      };
    })
  ];

  testHelpers = ''
    def superkey_start():
        with subtest("Start machines and prepare"):
            start_all()
            machine.wait_for_unit("multi-user.target")

        with subtest("Verify home-manager installed config files"):
            machine.succeed("test -L /home/pjones/.config/emacs/init.el")

        with subtest("Wait for sway to start"):
            machine.wait_for_file("/run/user/1000/wayland-1")
            machine.wait_for_file("/tmp/sway-ipc.sock")
            machine.wait_until_succeeds("pgrep waybar")
            machine.wait_for_unit("emacs", "pjones")
            machine.wait_for_file("/run/user/1000/emacs/server")

        with subtest("Upload staging script"):
            machine.copy_from_host(
                "${./stage-for-screenshot.sh}",
                "/tmp/stage.sh",
            )

    def superkey_lock():
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

    def superkey_screenshot(theme="dark"):
        with subtest(f"Screenshot: {theme}"):
            machine.succeed(
                "su - pjones -c 'swaymsg -t command exec bash /tmp/stage.sh'"
            )
            machine.wait_for_window("fastfetch")
            machine.sleep(5) # Need other windows to go away and settle
            machine.screenshot(f"screenshot-{theme}")
            machine.sleep(1) # Need to be stable for the screenshot

    def superkey_switch_to_light_theme():
        with subtest("Switching to light theme"):
            machine.send_key("meta_l-spc")
            machine.sleep(1)
            machine.send_chars("light theme")
            machine.send_key("ret")
            machine.sleep(2)

    def superkey_exit():
        with subtest("Exit sway"):
            machine.execute("su - pjones -c 'swaymsg -t command exit'")
            machine.wait_until_fails("pgrep -x sway")
            machine.wait_for_file("/tmp/sway-exit-ok")
  '';
in
withXwininfo.nixosTest {
  name = "superkey-sway-test";
  passthru.testHelpers = testHelpers;

  nodes = {
    machine = { pkgs, lib, ... }: {
      imports = [
        (import ./common.nix { inherit self; })
        ./autologin.nix
      ];

      environment.systemPackages = [
        pkgs.fastfetch
      ];
    };
  };

  testScript = ''
    ${testHelpers}
    superkey_start()
    superkey_screenshot("dark")
    superkey_lock()
    superkey_switch_to_light_theme()
    superkey_screenshot("light")
    superkey_exit()
  '';
}
