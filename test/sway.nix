{ self, pkgs }:

let
  withXwininfo = pkgs.appendOverlays [
    (final: prev: {
      xorg = prev.xorg // {
        xwininfo = self.packages.${prev.stdenv.hostPlatform.system}.xwininfo-tests;
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
            machine.wait_for_file("/tmp/compositor-ipc.sock")
            machine.wait_until_succeeds("pgrep waybar")
            machine.wait_for_unit("emacs", "pjones")
            machine.wait_for_file("/run/user/1000/emacs/server")

    def superkey_lock():
        with subtest("Test screen locking"):
            machine.succeed("su - pjones -c test-lock-screen.sh")
            machine.wait_until_succeeds("pgrep swaylock")
            machine.sleep(1)
            machine.screenshot("lock")
            machine.send_chars("password")
            machine.send_key("ret")
            machine.wait_until_fails("pgrep swaylock")

    def superkey_screenshot(theme="dark"):
        with subtest(f"Screenshot: {theme}"):
            machine.succeed("su - pjones -c stage-for-screenshot.sh")
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
            machine.succeed("su - pjones -c check-kill-compositor.sh")
  '';
in
withXwininfo.testers.nixosTest {
  name = "superkey-sway-test";
  passthru.testHelpers = testHelpers;

  nodes = {
    machine = { pkgs, ... }: {
      imports = [
        (import ./common.nix { inherit self; })
        ./autologin.nix
      ];

      superkey.compositor = "sway";

      environment.systemPackages = [
        pkgs.fastfetch
      ];

      environment.sessionVariables = {
        # Fixed location for tests:
        SWAYSOCK = "/tmp/compositor-ipc.sock";
      };
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
