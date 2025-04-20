# General Info

Greetings! If you want to add auto optimization for your GNU/Linux distribution to improve performance for everyday use (like creating/mixing/mastering music; gaming; video works; etc.) you can use this project. I built this project for my system with pre-requires below and my love apps:

- OS: `Arch Linux x86_64`
- Audio: `pipewire`
- Session: `wayland`
- GPU: `Intel TigerLake-H GT1 [UHD Graphics]` + `NVIDIA GeForce RTX 3070 Mobile / Max-Q` (set NVIDIA by `envycontrol` as prime GPU)
- Storage: `NVMe SSD 1TB`
- CPU: `11th Gen Intel i7-11800H (16) @ 4.600GHz`
- Memory: `16GB`
- Kernel: `linux-zen`
- DE: `GNOME`
- Flatpak: `yes`
- FS: `btrfs`

Optimization time: *~42 minutes* on a VM (it may be faster on more powerful hardware).

## Specificity

- The `fstab` settings for BTRFS partitions are available in the `files` folder.
- The list of officially supported Flatpak applications is also located in the `files` folder.
- If you don't want to use some apps from the project you can modify scripts in `main_p1.sh` and `yay_p2.sh` with adding symbol `#` before the package line to comment it out.

## Installation

1. Go to the folder `cmd/main`
2. Open a terminal and run commands from the file `Start_Post_install.txt`
3. Follow the on-screen instructions
4. After the work is completed `Postinstall_start.sh` and restart the system, run `After_reboot.sh` to complete the optimization

## Sources

I use many instructions from the following sources:

- **MAIN:** [project ARU](https://ventureo.codeberg.page/)
- **Helpers:** `DeepSeek R1`, `Grok 3 Think`, `Claude Sonnet 3.7 Thinking` -- all with "Search" option
