{ pkgs, ... }:
{
  home.packages = [
    (pkgs.llm.withPlugins {
      llm-gemini = true;
      llm-jq = true;
      llm-cmd = true;
      llm-git = true;
      llm-docs = true;
    })
  ];
}

