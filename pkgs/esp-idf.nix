{ pkgs, fetchFromGitHub, python3, stdenv, gdb, lib }:
let
  python_ovr =
    let
      packageOverrides = self: super: {
        pyparsing = super.pyparsing.overridePythonAttrs (old: rec {
          version = "2.3.1";
          src = fetchFromGitHub {
            owner = "pyparsing";
            repo = "pyparsing";
            rev = "pyparsing_${version}";
            sha256 = "04x7wjf7fhslx95i6361ajfx33x7d1h867xsxvxiq3z38lysz2cv";
          };
        });

        ecdsa = super.ecdsa.overridePythonAttrs (old: rec {
          version = "0.16.1";
          src = super.fetchPypi {
            pname = old.pname;
            inherit version;
            sha256 = "1zsh3rn279m0qgn4a3qwh5bwc98k1mpw9cvq3ayss9flvni4dh6g";
          };
          doCheck = false;
        });

        bitstring = super.bitstring.overridePythonAttrs (old: rec {
          version = "3.1.7";
          src = super.fetchPypi {
            pname = old.pname;
            inherit version;
            sha256 = "0jl6192dwrlm5ybkbh7ywmyaymrc3cmz9y07nm7qdli9n9rfpwzx";
          };
        });

        reedsolo = super.buildPythonPackage rec {
          pname = "reedsolo";
          version = "1.5.4";
          src = super.fetchPypi {
            inherit pname version;
            sha256 = "09q15ji9iac3nmmxrcdvz8ynldvvqanqy3hs6q3cp327hgf5rcmq";
          };
          doCheck = false;
          checkInputs = [ super.nose ];
          checkPhase = ''
            nosetests
          '';
        };

        gdbgui_pkg = super.buildPythonPackage rec {
          pname = "gdbgui";
          version = "0.13.2.0";

          buildInputs = [ gdb ];
          propagatedBuildInputs = with super; [
            flask
            flask-socketio
            flask-compress
            pygdbmi
            pygments
            gevent
            gevent-websocket
            eventlet
          ];

          src = super.fetchPypi {
            inherit pname version;
            sha256 = "0m1fnwafzrpk77yj3p26vszlz11cv4g2lj38kymk1ilcifh4gqw0";
          };

          postPatch = ''
            echo ${version} > gdbgui/VERSION.txt
            # remove upper version bound
            sed -ie 's!, <.*"!"!' setup.py
          '';

          postInstall = ''
            wrapProgram $out/bin/gdbgui \
            --prefix PATH : ${stdenv.lib.makeBinPath [ gdb ]}
          '';

          # tests do not work without stdout/stdin
          doCheck = false;
        };
      };
    in
    python3.override { inherit packageOverrides; };

  python_env = (python_ovr.withPackages (ps: with ps; [
    setuptools
    click
    pyserial
    future
    cryptography
    pyparsing
    pyelftools
    gdbgui_pkg
    pygdbmi
    reedsolo
    bitstring
    ecdsa
  ]));

in
stdenv.mkDerivation rec {
  name = "esp-idf";

  nativeBuildInputs = [ pkgs.makeWrapper ];

  buildInputs = with pkgs; [
    xtensa-esp-32-elf
    ninja
    cmake
    ccache
    dfu-util
  ];

  src = fetchFromGitHub {
    owner = "espressif";
    repo = "esp-idf";
    rev = "v4.2";
    fetchSubmodules = true;
    sha256 = "0h60xnxny0q4m3mqa1ghr2144j0cn6wb7mg3nyn31im3dwclf68h";
  };

  phases = [ "installPhase" ];

  installPhase = ''
    makeWrapper ${python_env}/bin/python $out/bin/idf.py \
    --add-flags ${src}/tools/idf.py \
    --set IDF_PATH ${src} \
    --prefix PATH : "${lib.makeBinPath buildInputs}"
  '';

  shellHook = ''
    export IDF_PATH=${src}
  '';
}
