# foundrix's power10k module lists oh-my-zsh's `github` plugin, which announces
# its own deprecation on every shell start. What it offers is a wrapper around
# the legacy `hub` CLI, which nothing here installs, and a `git.io` function
# that only prints a second deprecation notice. The successor it points to, the
# `gh` plugin, generates the completion that nixpkgs' gh already ships in
# share/zsh/site-functions, which home-manager puts on fpath for every Nix
# profile - so installing gh is all that replacement takes.
#
# The entry is dropped through the option's `apply` because foundrix writes the
# list out in full and home-manager merges list definitions by concatenation: a
# module downstream can transform the result but cannot take one element out of
# the merge. Drop this module once foundrix no longer lists the plugin, which is
# also when the check below fails.
{ applyHomeManagerShared, ... }:
{
  home-manager = applyHomeManagerShared (
    { lib, ... }:
    let
      deprecated = "github";
    in
    {
      options.programs.zsh.plugins = lib.mkOption {
        apply =
          plugins:
          lib.throwIf (plugins != [ ] && !lib.any (plugin: plugin.name == deprecated) plugins)
            "foundrix no longer lists oh-my-zsh's ${deprecated} plugin: remove modules/shell/zsh-drop-github-plugin.nix"
            (lib.filter (plugin: plugin.name != deprecated) plugins);
      };
    }
  );
}
