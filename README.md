`lights` is a barebones color scheme switcher for terminal users:

- `~/.lights/off` and `~/.lights/on` hold whatever config files you want.
- `~/.lights/hooks` holds whatever executable files you want.
- `~/.lights/current` is a symlink to one of the config directories.
- `lights on` and `lights off` switch the symlink target and spawn each hook.

From there, it's up to you to add reasonable config snippets to the `on` and
`off` directories, include those snippets in some higher-level configuration
through the `current` symlink, and write any hooks you need to force a
configuration reload.

`lights` is an unstable personal project intended partly to meet my own
bare-minimum requirements, and partly as an excuse to learn Swift. It's
currently written for and tested exclusively on macOS, but in theory should run
on Linux.
