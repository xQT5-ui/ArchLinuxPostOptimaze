# General Info

Greetings! If you want to add an auto-optimization for your GNU/Linux distribution to improve performance for everyday use (like creating/mixing/mastering music; gaming; video works; etc.) you can use this project. I built this project for my system with pre-requires below and my love apps:

- OS: `Arch Linux x86_64`
- Audio: `pipewire`
- Session: `wayland`
- GPU: Hybrid = `Intel TigerLake-H GT1 [UHD Graphics]` + `NVIDIA GeForce RTX 3070 Mobile / Max-Q`
- Storage: `NVMe SSD 1TB`
- CPU: `11th Gen Intel i7-11800H (16) @ 4.600GHz`
- Memory: `16GB`
- Swap: `yes`
- Kernel: `linux`
- DE: `GNOME`
- Flatpak: `yes`
- FS: `ext4`

## Specificity

- The `fstab` settings for FS partitions are available in the `child/files` folder.
- If you don't want to use some packages from the project you can modify scripts in `main_p1.sh` and `yay_p2.sh` with adding symbol `#` before the package line to comment it out.
- The user's configs live in outside of project and need to copy to `child/files/user` its before starting job.

## Installation

1. Go to the folder `cmd`;
2. Open a terminal and run commands from the file `Start_Post_install.txt`;
3. Follow the on-screen instructions.

## Sources

I use many instructions from the following sources:

- **MAIN:** [project ARU](https://ventureo.codeberg.page/)
- **Helpers:** open source LLMs
