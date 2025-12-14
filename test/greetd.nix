{ self, pkgs }:
pkgs.testers.nixosTest {
  name = "superkey-greetd-test";

  nodes = {
    machine =
      { ... }:
      {
        imports = [ (import ./common.nix { inherit self; }) ];
      };
  };

  testScript = ''
    with subtest("Start machines and prepare"):
        start_all()
        machine.wait_for_unit("multi-user.target")

    with subtest("Console login"):
        machine.send_chars("pjones")
        machine.send_key("ret")
        machine.send_chars("password")
        machine.send_key("ret")

    with subtest("Wait for compositor to start"):
        machine.wait_for_file("/run/user/1000/wayland-1")
        machine.wait_until_succeeds("pgrep waybar")

    with subtest("Exit compositor"):
        machine.succeed("su - pjones -c check-kill-compositor.sh")
  '';
}
