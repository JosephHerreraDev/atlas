{config, pkgs, ...}:

{
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;

    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  }; 

  hardware.graphics = {
    enable = true;
  };
  
  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];
  };
}
