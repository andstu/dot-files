{ config, dotfilesRoot, ... }:

let
  repo = dotfilesRoot;
in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [ "git" ];
    };

    sessionVariables = {
      EDITOR = "nvim";
    };

    initExtra = ''
      export PATH="$PATH:/opt/nvim-linux64/bin"
      export PATH="$HOME/.local/bin:$PATH"
      export PATH="$HOME/.opencode/bin:$PATH"

      [[ -f "$HOME/.zshrc_local" ]] && source "$HOME/.zshrc_local"

      fpath=($HOME/.docker/completions $fpath)
      autoload -Uz compinit
      compinit

      [[ -f "$HOME/.zellij-agents.zsh" ]] && source "$HOME/.zellij-agents.zsh"
    '';
  };

  home.file.".zellij-agents.zsh".source = repo + "/zsh/.zellij-agents.zsh";

  home.file.".oh-my-zsh/custom/aliases.zsh".source =
    repo + "/zsh/.oh-my-zsh/custom/aliases.zsh";
}
