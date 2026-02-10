{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # Инструменты разработки
    gcc
    gnumake
    cmake # GLFW часто проще собирать через cmake

    glfw
    glew
    libGL
    freeglut # Оставим для совместимости с вашим старым кодом
    libGLU
    glm

    xorg.libX11
    xorg.libXrandr
    xorg.libXinerama
    xorg.libXcursor
    xorg.libXi
  ];

  shellHook = ''
    export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath [ pkgs.libGL pkgs.glfw pkgs.glew ]}:$LD_LIBRARY_PATH
    echo "OpenGL / GLFW environment loaded!"
  '';
}
