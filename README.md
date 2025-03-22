# Lights

The Lights project supports toggling terminal applications between light and
dark appearances via the following setup:

- `~/.lights/off` and `~/.lights/on` hold whatever config files you need.
- `~/.lights/current` is a symlink to one of those directories.
- `~/.lights/hooks` holds whatever executable hook files you need.

From there, it's up to you to populate the `on` and `off` directories with
reasonable contents, include them in higher-level configurations through the
`current` symlink, and write any hooks you need to reload configurations.

The project provides two ways to manage your `~/.lights` setup:

- The **Lighter** menu bar app for macOS, which continuously syncs `~/.lights`
  with the system-wide appearance setting, and lets you toggle dark mode
  without opening System Settings.
- The cross-platform<sup>†</sup> `lights` CLI, with `on` and `off` subcommands
  that perform the switch on demand.

<sup>†</sup> I've managed to build `lights` with Swift's static Linux SDK, but
the resulting binary is over 140 MB in size. The glibc build currently has
issues with strict concurrency in Swift 6; future implementation work may
naturally fix this.

Lights is an unstable personal project intended partly to meet my own minimal
requirements, and partly as an excuse to learn Swift and get a basic handle on
development for Apple platforms.
