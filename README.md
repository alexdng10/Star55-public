# Star55

Star55 is a 2D/3D game engine designed to make game creation easier to start.

Instead of spending hours learning a large engine before building anything,
Star55 lets users create gameplay from simple visual building blocks:

**Event → Conditions → Actions**

Example:

- When Space is pressed
- → Player can jump
- → Jump

## Install

Star55 currently ships as a binary release for macOS Apple Silicon.

```sh
git clone https://github.com/alexdng10/star55-public
cd star55-public
./install.sh
```

Then launch the editor:

```sh
star55
```

The installer downloads the application from GitHub Releases, verifies its
SHA-256 checksum, installs `Star55.app` into `~/Applications`, and creates a
per-user `star55` launcher. If the selected launcher directory is not already
on `PATH`, the installer prints the one-line shell command needed to enable it.

## Status

Star55 is under active development. The public release contains the currently
stable distribution for creating and editing projects with Star55.

## License

Star55 releases are distributed under the MIT License.

The development source repository is currently not publicly distributed.
This repository contains public distribution materials only; it does not
contain the source used to build Star55.
