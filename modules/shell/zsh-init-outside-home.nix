# foundrix's power10k module ends its part of .zshrc with `return` unless zsh
# started in the home directory, which also ends the file: everything
# home-manager orders after it never runs. A shell opened in a project directory
# gets no direnv hook, syntax highlighting or history substring search, so a
# directory's devshell does not load in it.
#
# The block is rewritten in the finished file because home-manager merges
# programs.zsh.initContent from every module, and one module's lines cannot be
# removed from that merge. The jump to the last working directory keeps its
# conditions. Drop this module once foundrix no longer uses `return` there, which
# is also when the check below fails.
{ applyHomeManagerShared, ... }:
{
  home-manager = applyHomeManagerShared (
    { config, lib, ... }:
    let
      zshrc = config.programs.zsh.initContent;
      endsFileOutsideHome = ''
        [[ -z "$ZSH_LAST_WORKING_DIRECTORY" ]] || return
        [[ "$PWD" == "$HOME" ]] || return

        if lwd 2>/dev/null; then
          ZSH_LAST_WORKING_DIRECTORY=1
        fi
      '';
      jumpsOnlyFromHome = ''
        if [[ -z "$ZSH_LAST_WORKING_DIRECTORY" && "$PWD" == "$HOME" ]] && lwd 2>/dev/null; then
          ZSH_LAST_WORKING_DIRECTORY=1
        fi
      '';
    in
    lib.mkIf config.programs.zsh.enable {
      home.file."./.zshrc".text = lib.mkForce (
        lib.throwIfNot (lib.hasInfix endsFileOutsideHome zshrc)
          "foundrix changed the early return in its zsh setup: check whether modules/shell/zsh-init-outside-home.nix is still needed"
          (lib.replaceStrings [ endsFileOutsideHome ] [ jumpsOnlyFromHome ] zshrc)
      );
    }
  );
}
