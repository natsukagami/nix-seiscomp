# Nix package for SeiscomP

## Try it out

Since SeiscomP wants to have full access to its installation read-write,the Nix installation would try to copy Seiscomp to `~/seiscomp`
(this can be set by the `SEISCOMP_TARGET` environment variable).

You can set it up simply by calling
```
nix run github:natsukagami/nix-seiscomp
```
