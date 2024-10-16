# NixOS-Config
语言: CN -> [EN](README.md)

Rikki 的 NixOS 配置

# Nix 语言学习
## 如何在不同的模块之间共享 集合/变量
你可以将 `_module.args` 或 `specialArgs` 视作一种不错的解决方案。  

两者的不同之处:  

- `specialArgs` 仅在 `flake.nix` 中使用

    ```nix
    {
      description = "description";

      inputs = {
        
      };

      outputs = {
        self,
        nixpkgs,
        ...
      } @ inputs: {
        nixosConfigurations = {
          "<sub-config-name>" = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {inherit inputs;}; # <- here
            modules = [

            ];
          };
        };
      };
    }
    ```

    在本例中，将输入集作为额外参数继承，那么所有模块都能获取输入集中的变量。

    可以使用以下方法使模块获取变量：

    ```nix
    {
      self,
      nixpkgs,
      ...
    }: {

    }
    ```

    只需在文件头部列出变量，模块就可以获取。

- `_module.args` 必须在模块中使用

    ```nix
    {...} @ upstream: let
      trackerList = import ./aria2-tracker;
    in {
      _module.args = {inherit trackerList;};
      imports = [
      ];
    }
    ```

    在这个例子中，我们创建了一个名为 `trackerList` 的变量。

    我们使用 `_module.args = {inherit trackerList;};` (等价于
    `_module.args.trackerList = trackerList;`) 来将变量
    `trackerList` 暴露给其他模块。

    如果我们想要引入 `trackerList`, 可以使用和第一段一致的代码.

    附: 如果你想要用 `_module.args` 来代替 `specialArgs`

    你可以使用下面的代码来达成目的

    ```nix
    {
      description = "description";

      inputs = {
        
      };

      outputs = {
        self,
        nixpkgs,
        ...
      } @ inputs: {
        nixosConfigurations = {
          "<sub-config-name>" = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              {
                _module.args = {inherit inputs;}; # <- here
              }
            ];
          };
        };
      };
    }
    ```

    你会不难发现，我们创建了一个内联(行内)模块，而这并不违反规则。

- [nixos-module-imports-with-arguments](https://stackoverflow.com/questions/47650857/nixos-module-imports-with-arguments)
- [nixos-flake-and-module-system](https://nixos-and-flakes.thiscute.world/zh/nixos-with-flakes/nixos-flake-and-module-system)


# Nix Code Formatter

Use [alejandra](https://github.com/kamadorueda/alejandra) as the official formatter for this repo.

You can try it in your browser. [here](https://kamadorueda.com/alejandra/)
