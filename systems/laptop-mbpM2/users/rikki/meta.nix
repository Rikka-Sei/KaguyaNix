{
  enable = true;
  admin = true;
  shell = "fish";
  capabilities = [
    "identity/rikki"
    "development/base"
    "software/workstation"
    "software/network-access"
    "business/common"
    "lifetime/common"
  ];

  overrides = {
    kaguya.development.base.vscode.enable = false;
    kaguya.software.browser.enable = false;
  };
}
