# direnv

## update pinned version

```
mv .nixpkgs-version.json nixpkgs-version.json.previous
nix-prefetch-git https://github.com/nixos/nixpkgs.git refs/heads/nixos-unstable >.nixpkgs-version.json
```

## troubleshooting

If you get `./.envrc:109: Sourcing: command not found`, the most likely cause
is some part of the build process spitting something onto stdout when it either
shouldn't have been spit out at all or should have been on stderr. Take a look
at the dump.env file, which will be located somewhere like

```
./.direnv/wd-86452ccdf0879f88e537141a4809226d/dump.env
```

to see whether there's content there that doesn't belong.
