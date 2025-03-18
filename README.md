`lights` is a barebones color scheme switcher for terminal users:

- `~/.lights/off` and `~/.lights/on` hold whatever config files you need.
- `~/.lights/current` is a symlink to one of those directories.
- `~/.lights/hooks` holds whatever executable hook files you need.
- `lights on` and `lights off` switch the symlink target and spawn each hook.

From there, it's up to you to populate the `on` and `off` directories with
reasonable contents, include them in higher-level configurations through the
`current` symlink, and write any hooks you need to reload configurations.

`lights` is an unstable personal project intended partly to meet my own minimal
requirements, and partly as an excuse to learn Swift. It's currently written
for and tested mainly on macOS, though I've managed to build it with Swift's
static Linux SDK (producing a binary over 100 MB 😬).
