{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ brightnessctl ];
  services.upower.enable = true;
}
