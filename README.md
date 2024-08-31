# Linux Laptop (Surface Book 2) dGPU Power Management Automation

## What's involved?

Firstly, as of yet, I've only had experience doing this on a Surface Book 2. Different laptop? Different problems, presumably.

One _very_ unique issue with this laptop is that the GPU is limited to 7W-ish of power consumption on battery unless you patch the NVIDIA driver to always believe it's running on AC power. We'll be addressing this first, but you should not follow these steps on your non-Surface-Book-2 laptop. After that, we'll get to what I do to solve the other power management issues.

When we get to those, you'll need to use `system76-power` to "handle" the power management (over something like `TLP` or `power-profiles-daemon`). If you're on Fedora, use the COPR repo, that's what I do. You're going to need to remove conflicting tools, System76 has docs on this. Get `system76-power` installed, which didn't involve installing any firmware things, but did involve enabling the copr (which can be found here)[https://support.system76.com/articles/system76-driver/], then (installing)[https://support.system76.com/articles/system76-software/] _JUST_ `system76-power` and no other packages, then continue here.

## Surface Book 2 Power Limit Removal

### `.run` Installation
If you wish to keep your sanity, you'll be using NVIDIA's `.run` driver package instead of your package manager's. On a distro that typically uses `DKMS`, this will simply be to prevent updates from removing your changes unexpectedly (but you could also just lock the version and leave it at that), but Fedora uses `Akmods`, which I had trouble messing with in this way, so I need to use the `.run` drivers instead so that I'm using `DKMS` on Fedora.

Their (graphics driver download page)[https://www.nvidia.com/Download/index.aspx]

Their (CUDA download page)[https://developer.nvidia.com/cuda-downloads?target_os=Linux]

I install these dependencies to make sure the installation can complete:
```
sudo dnf upgrade --refresh
sudo dnf install kernel-headers kernel-devel gcc make dkms acpid libglvnd-glx libglvnd-opengl libglvnd-devel pkgconfig 
```

Then, as I've had issues installing it while the system's up, I reboot to a TTY.
```
systemctl set-default multi-user.target  
reboot
```

I then just run their `.run` package as root, following defaults other than rejecting their offer to back-up xorg configs, before (optionally) installing `CUDA` things and moving back to a graphical session.

```
systemctl set-default graphical.target
reboot
```

At this point, also run a `flatpak update` to get the flatpak NVIDIA runtimes installed (they're auto-detected).

### Making Vulkan work
For some reason, these don't seem to include the files necessary to register your GPU as available to run `Vulkan` programs. Due to this, I download `nvidia-utils` (from the Arch repos)[https://archlinux.org/packages/extra/x86_64/nvidia-utils/] with the "Download From Mirror" button, extract it, and copy over the whole `/usr/share/` directory from it to fill all missing files (mainly focused on `/usr/share/vulkan`'s ICDs, but there are some other files not otherwise filled in too).

### Removing the power limit
At this point, you've got a working driver, but you've also got a working power limit. To remove it, run
```
sudo nano /usr/src/nvidia-VERSION/nvidia/nv-acpi.c
```
where VERSION can be found by using terminal autocomplete or with `nvidia-smi --version`.

Search for this section within the file:
```
// AC Power Source Plug State
...
*ac_plugged = some_value
```
and replace `some_value` with NV_TRUE.

If your driver was often being updated, this would constantly be being undone.

Now, every driver update (which you'll be doing manually, so it shouldn't ever sneak up on you), you'll need to run
```
sudo dkms remove nvidia/VERSION  
sudo dkms install nvidia/VERSION
```
which removes the one that was built when you first installed it, then "installs" (it gets rebuilt with the replaced code, not just reinstalled) the updated version.