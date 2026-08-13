{ pkgs, ... }:
{
  home.packages = with pkgs; [
    llm
    python314Packages.llm-jq
    python314Packages.llm-cmd
    python313Packages.llm-git
    python313Packages.llm-docs
    python314Packages.llm-gemini
  ];
}

