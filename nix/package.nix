{
  lib,
  stdenv,
  writeText,
  src,
  cmake,
  ninja,
  pkg-config,
  kdePackages,
  mpv-unwrapped,
  ffmpeg,
  lz4,
  libglvnd,
  vulkan-headers,
  vulkan-loader,
  alsa-lib,
  libpulseaudio,
}:

stdenv.mkDerivation {
  pname = "wallpaper-engine-kde-plugin";
  version = "0-unstable";
  inherit src;

  # Keep Nix-specific runtime import paths out of the upstream sources.
  patches = [
    (writeText "nix-qml-imports.patch" ''
      diff --git a/src/CMakeLists.txt b/src/CMakeLists.txt
      --- a/src/CMakeLists.txt
      +++ b/src/CMakeLists.txt
      @@ -35,2 +35,4 @@
       set_target_properties(''${PROJECT_NAME} PROPERTIES CXX_VISIBILITY_PRESET hidden)
      +target_compile_definitions(''${PROJECT_NAME}
      +    PRIVATE WEKDE_QML_IMPORT_PATH="''${WEKDE_QML_IMPORT_PATH}")
       set_target_properties(''${PROJECT_NAME}
      diff --git a/src/plugin.cpp b/src/plugin.cpp
      --- a/src/plugin.cpp
      +++ b/src/plugin.cpp
      @@ -20,1 +20,9 @@
       public:
      +    void initializeEngine(QQmlEngine* engine, const char* uri) override {
      +        const auto paths = QStringLiteral(WEKDE_QML_IMPORT_PATH).split(':', Qt::SkipEmptyParts);
      +        for (const auto& path : paths) {
      +            engine->addImportPath(path);
      +        }
      +        QQmlExtensionPlugin::initializeEngine(engine, uri);
      +    }
      +
    '')
  ];

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    kdePackages.extra-cmake-modules
    kdePackages.wrapQtAppsHook
  ];

  buildInputs = [
    kdePackages.qtbase
    kdePackages.qtdeclarative
    kdePackages.kpackage
    kdePackages.libplasma
    mpv-unwrapped
    ffmpeg
    lz4
    libglvnd
    vulkan-headers
    vulkan-loader
  ];

  # This is loaded by plasmashell, not a standalone executable to wrap.
  dontWrapQtApps = true;

  cmakeFlags = [
    (lib.cmakeBool "USE_PLASMAPKG" false)
    (lib.cmakeFeature "KDE_INSTALL_QMLDIR" "lib/qt-6/qml")
    (lib.cmakeFeature "WEKDE_QML_IMPORT_PATH" (
      lib.makeSearchPath "lib/qt-6/qml" [
        kdePackages.qtmultimedia
        kdePackages.qtwebchannel
        kdePackages.qtwebengine
      ]
    ))
  ];

  # miniaudio opens these at runtime; bare sonames aren't resolved on NixOS.
  postPatch = ''
    substituteInPlace src/backend_scene/third_party/miniaudio/miniaudio.h \
      --replace-fail '"libasound.so.2"' '"${lib.getLib alsa-lib}/lib/libasound.so.2"' \
      --replace-fail '"libpulse.so.0"' '"${lib.getLib libpulseaudio}/lib/libpulse.so.0"'
  '';

  meta = {
    description = "Wallpaper Engine scene, video and web wallpapers for KDE Plasma 6";
    homepage = "https://github.com/CoutHi/wallpaper-engine-kde-plugin";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
  };
}
