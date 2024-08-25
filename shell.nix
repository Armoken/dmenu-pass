{ pkgs ? import <nixpkgs>{} }:
with import <nixpkgs>{};
let
  python-with-packages = ((pkgs.python310Full.withPackages(ps: [
    ps.pygobject3  # Python bindings for Glib.
    ps.dbus-python # A zero-dependency DBus library for Python with asyncio support.

    ps.ipython
  ])).overrideAttrs (args: { ignoreCollisions = true; doCheck = false; }));
in pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    python-with-packages

    nodePackages.pyright                 # Type checker for the Python language.
    vscode-extensions.ms-pyright.pyright # VS Code static type checking for Python.

    fish
  ];
  shellHook = ''
    PYTHONPATH=${python-with-packages}/${python-with-packages.sitePackages}
    # maybe set more env-vars
  '';

  runScript = "fish";
}
