# General Info

Greetings! If you want to add an auto-migrate dataes after clear install and auto-optimization for your GNU/Linux distribution **based by Arch Linux** to slightly improve performance for everyday usege you can use this project.
I built this project for my system with pre-requires below and my love apps:

- OS: `Arch Linux x86_64`
- Audio: `pipewire`
- Session: `wayland`
- GPU: Hybrid = `Intel TigerLake-H GT1 [UHD Graphics]` + `NVIDIA GeForce RTX 3070 Mobile / Max-Q 8 GiB`
- Storage: `NVMe 1 TB`
- CPU: `11th Gen Intel i7-11800H (16) @ 4.600GHz`
- RAM: `16 GiB`
- Swap: `zswap 8 GiB`
- Kernel: `linux`
- DE: `GNOME` or `MangoWM + Noctalia Shell`
- Flatpak: `yes`
- FS: `btrfs`

## Specificity

- The `fstab` settings for FS partitions are available in the `child/files` folder.
- The user's configs live in outside of project and need to copy to `child/files/user` its before starting job.
- The apps describe in `main_p1.sh` and `yay_p2.sh`, system settings in `sys_optimize_p3.sh`, user settings in `user_optimize_p4.sh`

## Installation

1. Go to the folder `ArchLinuxPostOptimize`;
2. Open a terminal and run commands from the file `Start_Post_install.txt`;
3. Follow the on-screen instructions.

## Sources

- **MAIN:** [project ARU](https://ventureo.codeberg.page/)
- **Helpers:** LLMs like `DeepSeek`, `Claude` and etc.
