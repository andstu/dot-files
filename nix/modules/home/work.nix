{ pkgs, ... }:

# Work identity and work-specific tools — import on work-mac only.
{
  programs.git = {
    userName = "Andrew Teeter";
    userEmail = "ateeter@dstillery.com";
  };

  home.packages = with pkgs; [
    # Add work-specific CLI tools here
  ];
}
