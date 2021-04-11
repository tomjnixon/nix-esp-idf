{ stdenv, fetchFromGitHub, fetchurl, pkgs }: let

  binutils_src = fetchFromGitHub {
    owner = "espressif";
    repo = "binutils-gdb";
    rev = "esp-2020r3-binutils";
    sha256 = "0az64lv5n52x2hkx43y0d82llfk61cxkblm32zzlk2a26lw4916b";
  };

  gdb_src = fetchFromGitHub {
    owner = "espressif";
    repo = "binutils-gdb";
    rev = "esp-2020r3-gdb";
    sha256 = "08s7wilam7h81aba2cgwcc0v9kk5q6h5bsl5hazqv9jckhjh6c8l";
  };

  gcc_src = fetchFromGitHub {
    owner = "espressif";
    repo = "gcc";
    rev = "esp-2020r3";
    sha256 = "0vq9qjqzi2mrvq3fkmrk6ipz628nnj091dbxqmd2ax860vyj4bmb";
  };

  newlib_src = fetchFromGitHub {
    owner = "espressif";
    repo = "newlib-esp32";
    rev = "esp-2020r3";
    sha256 = "1azk8wdx62xpf6jpbxnk21adryyf9airs1xrr0iyhnfm8lhbxir0";
  };

  to_tar = (name: src: 
    pkgs.runCommand "${name}-git-git.tar.bz2" {} ''
      BZIP2=--fast tar cjf $out --transform 's,^\./,${name}-git-git/,S' --mode=u+w -C ${src} .
    ''
  );

in stdenv.mkDerivation {
  name = "xtensa-esp32-elf";
  version = "2020r3";
  src = fetchFromGitHub {
    owner = "espressif";
    repo = "crosstool-NG";
    rev = "4399becb1e67d336d32f7e63cebebeb28e2cca94";
    sha256 = "1xv8klzs7g04rp9r1211ksfjqzv4hf3jkr438zmz6m9y7jhmca09";
    fetchSubmodules = true;
  };

  nativeBuildInputs = with pkgs; [
    autoconf automake aria coreutils curl cvs
    gcc git python which file wget unzip perl
  ];

  # https://unix.stackexchange.com/questions/356232/disabling-the-security-hardening-options-for-a-nix-shell-environment#367990
  hardeningDisable = [ "format" ];

  buildInputs = with pkgs; [
    bison flex gperf help2man libtool ncurses texinfo
  ];

  phases = [ "unpackPhase" "configurePhase" "buildPhase" "installPhase" ];

  configurePhase = ''
    CONFIG=./samples/xtensa-esp32-elf/crosstool.config;
    echo "CT_LOCAL_TARBALLS_DIR=\"\$\{CT_TOP_DIR\}/tars\"" >> $CONFIG
    echo "CT_FORBID_DOWNLOAD=y" >> $CONFIG

    mkdir tars;

    function patch_source() {
      local pkg="$1"
      local tar="$2"

      ln -s "$tar" "tars/''${pkg}-git-git.tar.bz2"

      sed -i "/CT_''${pkg^^}_DEVEL_BRANCH/d" $CONFIG
      echo "CT_''${pkg^^}_DEVEL_REVISION=\"git\"" >> $CONFIG
    }

    patch_source binutils "${to_tar "binutils" binutils_src}"
    patch_source gdb "${to_tar "gdb" gdb_src}"
    patch_source gcc "${to_tar "gcc" gcc_src}"
    patch_source newlib "${to_tar "newlib" newlib_src}"

    $SHELL ./bootstrap;
    ./configure --enable-local;
    make;

    ./ct-ng xtensa-esp32-elf;
  '' +
  toString ( map ( p: "ln -s " + fetchurl { inherit (p) url sha256; } + " ./tars/" + p.name + ";\n" ) [
    {
      name = "autoconf-2.69.tar.xz";
      url = "https://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.xz";
      sha256 = "113nlmidxy9kjr45kg9x3ngar4951mvag1js2a3j8nxcz34wxsv4";
    }
    {
      name = "automake-1.16.1.tar.xz";
      url = "https://ftp.gnu.org/gnu/automake/automake-1.16.1.tar.xz";
      sha256 = "08g979ficj18i1w6w5219bgmns7czr03iadf20mk3lrzl8wbn1ax";
    }
    {
      name = "gmp-6.1.2.tar.xz";
      url = "https://gmplib.org/download/gmp/gmp-6.1.2.tar.xz";
      sha256 = "04hrwahdxyqdik559604r7wrj9ffklwvipgfxgj4ys4skbl6bdc7";
    }
    {
      name = "mpfr-4.0.1.tar.xz";
      url = "https://ftp.gnu.org/gnu/mpfr/mpfr-4.0.1.tar.xz";
      sha256 = "0vp1lrc08gcmwdaqck6bpzllkrykvp06vz5gnqpyw0v3h9h4m1v7";
    }
    {
      name = "isl-0.19.tar.xz";
      url = "http://isl.gforge.inria.fr/isl-0.19.tar.xz";
      sha256 = "19dqyvngwj51fw2nfshr3r2hrbwkpsfrlvd4kx8gqv9a1sh1lv3d";
    }
    {
      name = "mpc-1.1.0.tar.gz";
      url = "http://ftp.gnu.org/gnu/mpc/mpc-1.1.0.tar.gz";
      sha256 = "0biwnhjm3rx3hc0rfpvyniky4lpzsvdcwhmcn7f0h4iw2hwcb1b9";
    }
    {
      name = "expat-2.2.5.tar.bz2";
      url = "http://downloads.sourceforge.net/project/expat/expat/2.2.5/expat-2.2.5-RENAMED-VULNERABLE-PLEASE-USE-2.3.0-INSTEAD.tar.bz2";
      sha256 = "1xpd78sp7m34jqrw5x13bz7kgz0n6aj15wn4zj4gfx3ypbpk5p6r";
    }
    {
      name = "ncurses-6.1.tar.gz";
      url = "http://ftp.gnu.org/pub/gnu/ncurses/ncurses-6.1.tar.gz";
      sha256 = "05qdmbmrrn88ii9f66rkcmcyzp1kb1ymkx7g040lfkd1nkp7w1da";
    }
  ]);

  buildPhase = ''
    unset CC;
    unset CXX;
    ./ct-ng build;
  '';

  installPhase = ''
    cp -avr ./builds/xtensa-esp32-elf/ $out
  '';
}
