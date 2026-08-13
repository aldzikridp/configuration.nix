{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "term-llm";
  version = "0.0.388";

  src = fetchFromGitHub {
    owner = "SamSaffron";
    repo = "term-llm";
    rev = "v${version}";
    hash = lib.fakeHash;
  };

  vendorHash = lib.fakeHash;

  subPackages = [ "." ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/samsaffron/term-llm/cmd.Version=v${version}"
  ];

  meta = with lib; {
    description = "Terminal-first AI runtime for commands, chat, editing, tools, jobs, agents, and local workflows";
    homepage = "https://github.com/SamSaffron/term-llm";
    license = licenses.mit;
    mainProgram = "term-llm";
    platforms = platforms.linux ++ platforms.darwin;
  };
}
