{
  lib,
  cmake,
  flex,
  swig,
  cryptopp,
  boost,
  openssl,
  libxml2,
  jdk21,
  gsoap,
  netcdf,
  v4l-utils,
  libjpeg-tools,
  shapelib,
  libusb1,
  gfortran,
  rrdtool,
  lapack,
  mariadb,
  libmysqlclient,
  ncurses,
  sass,
  python3,
  kdePackages,
  qt6,
  git,
  wrapQtAppsHook,
  makeBinaryWrapper,
  stdenv,
  fetchFromGitHub,
  runCommandLocal,
  writeShellScriptBin,

  enablePostgresql ? true,
  libpq,
  postgresql,
  enableSqlite ? true,
  sqlite,
  ...
}:
let
  version = "7.0.3";

  src-root = fetchFromGitHub {
    owner = "SeisComP";
    repo = "seiscomp";
    rev = version;
    hash = "sha256-fK+/KCmQC4J6DNjNByKuCpXnXuCIK987JgXVaWnLBYw=";
  };
  src-seedlink = fetchFromGitHub {
    owner = "SeisComP";
    repo = "seedlink";
    rev = version;
    hash = "sha256-HpaPYX+sMcHkRP7wMi7sYefXONoxO9b+VExBbR2lYYg=";
  };
  src-common = fetchFromGitHub {
    owner = "SeisComP";
    repo = "common";
    rev = version;
    hash = "sha256-0auL4MhRAQ+eFvXZStMlNL7T+mNuhxJlvui2sACCOD4=";
  };
  src-main = fetchFromGitHub {
    owner = "SeisComP";
    repo = "main";
    rev = version;
    hash = "sha256-DX/SUQTyJNZmKsofPd6Y+h/yx6w+ZGAi0DfO64pbExo=";
  };
  src-mainx = fetchFromGitHub {
    owner = "SeisComP";
    repo = "mainx";
    rev = version;
    hash = "sha256-VtT9dFRF7tsTZjSgaDCIq/lyTDvv8bfm9+nRmAwGNHE=";
  };
  src-extras = fetchFromGitHub {
    owner = "SeisComP";
    repo = "extras";
    rev = version;
    hash = "sha256-3REbpuqEix7JwXVtioyLRKcrR5qhKGCULrDoEffL5eQ=";
  };
  src-contrib-gns = fetchFromGitHub {
    owner = "SeisComP";
    repo = "contrib-gns";
    rev = version;
    hash = "sha256-hgUT1m3akzaJeT+MDNtELp0d9jcxpD2G+BgiDipMMKg=";
  };
  src-contrib-ipgp = fetchFromGitHub {
    owner = "SeisComP";
    repo = "contrib-ipgp";
    rev = version;
    hash = "sha256-vYniA1AcsbPURmAo2TmXTGgXb7wpZGwsIzceOUPfgYI=";
  };

  src = runCommandLocal "seiscomp-src-${version}" { } ''
    cp -r ${src-root} $out
    chmod -R +w $out
    cd $out/src/base
    cp -r ${src-seedlink} seedlink
    cp -r ${src-common} common
    cp -r ${src-main} main
    cp -r ${src-mainx} mainx
    cp -r ${src-extras} extras
    cp -r ${src-contrib-gns} contrib-gns
    cp -r ${src-contrib-ipgp} contrib-ipgp
  '';

  python = python3.withPackages (
    python3Packages: with python3Packages; [
      distutils
      numpy
      sphinx
      sphinx-mdinclude
      sphinxcontrib-bibtex
    ]
  );

  unwrapped = stdenv.mkDerivation (final: {
    pname = "seiscomp-unwrapped";
    inherit version;

    src = src;

    buildInputs = [
      cmake
      flex
      swig
      cryptopp
      boost
      openssl
      libxml2
      jdk21
      gsoap
      netcdf
      v4l-utils
      libjpeg-tools
      shapelib
      libusb1
      gfortran
      rrdtool
      lapack
      mariadb
      libmysqlclient.dev
      ncurses
      sass
      python
      git
    ]
    ++ lib.optional enablePostgresql libpq
    ++ lib.optional enableSqlite sqlite
    ++ (with kdePackages; [
      qt6.qttools
      qwt
      qtsvg
      # qtwebkit
      qtwebengine
    ]);

    nativeBuildInputs = [
      wrapQtAppsHook
      makeBinaryWrapper
    ];

    runtimeDependencies = [
      mariadb
      python
      git
      jdk21
    ]
    ++ lib.optional enablePostgresql postgresql
    ++ lib.optional enableSqlite sqlite;

    cmakeFlags = [
      "-DCMAKE_BUILD_TYPE=Release"
      "-DSC_GLOBAL_GUI_QT5=off"
      "-DSC_GLOBAL_GUI_QT6=on"
      "-DSC_DOC_GENERATE=on"
    ]
    ++ lib.optional enablePostgresql "-DSC_TRUNK_DB_POSTGRESQL=on"
    ++ lib.optional enableSqlite "-DSC_TRUNK_DB_SQLITE3=on";

    hardeningDisable = [ "format" ];

    postFixup = ''
      cd $out/bin
      wrapProgram ./seiscomp \
        --suffix PATH : ${lib.makeBinPath final.runtimeDependencies}
    '';
  });
in
(writeShellScriptBin "setup-seiscomp" ''
  set -e
  TARGET=''${SEISCOMP_TARGET:-"$HOME/seiscomp"}
  echo "Copying seiscomp files into $TARGET..."
  cp -r ${unwrapped} "$TARGET"
  echo "Updating permissions..."
  chown -R "$USER" "$TARGET"
  chmod -R u+rw "$TARGET"
  echo "Done! Once '$TARGET/bin/' is added to PATH, you can start seiscomp"
'').overrideAttrs
  (
    final: prev: {
      passthru.unwrapped = unwrapped;

      meta = {
        description = "A seismological software for data acquisition, processing, distribution and interactive analysis";
        homepage = "https://www.seiscomp.de/";
        license = lib.licenses.agpl3Only;
        maintainers = with lib.maintainers; [ natsukagami ];
        mainProgram = "setup-seiscomp";
      };
    }
  )
