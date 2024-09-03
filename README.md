# Linux Laptop (Surface Book 2) dGPU Power Management Automation

## What's involved?

Firstly, as of yet, I've only had experience doing this on a Surface Book 2. Different laptop? Different problems, presumably.

One _very_ unique issue with this laptop is that the GPU is limited to 7W-ish of power consumption on battery unless you patch the NVIDIA driver to always believe it's running on AC power. We'll be addressing this first, but you should not follow these steps on your non-Surface-Book-2 laptop. After that, we'll get to what I do to solve the other power management issues.

When we get to those, you'll need to use `system76-power` to "handle" the power management (over something like `TLP` or `power-profiles-daemon`). If you're on Fedora, use the COPR repo, that's what I do. You're going to need to remove conflicting tools, System76 has docs on this. Get `system76-power` installed, which didn't involve installing any firmware things, but did involve enabling the copr [which can be found here](https://support.system76.com/articles/system76-driver/), then [installing](https://support.system76.com/articles/system76-software/) _JUST_ `system76-power` and no other packages, then continue here.

## Surface Book 2 Power Limit Removal

### `.run` Installation
If you wish to keep your sanity, you'll be using NVIDIA's `.run` driver package instead of your package manager's. On a distro that typically uses `DKMS`, this will simply be to prevent updates from removing your changes unexpectedly (but you could also just lock the version and leave it at that), but Fedora uses `Akmods`, which I had trouble messing with in this way, so I need to use the `.run` drivers instead so that I'm using `DKMS` on Fedora.

Their [graphics driver download page](https://www.nvidia.com/Download/index.aspx)

Their [CUDA download page](https://developer.nvidia.com/cuda-downloads?target_os=Linux)

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
For some reason, these don't seem to include the files necessary to register your GPU as available to run `Vulkan` programs. Due to this, I download `nvidia-utils` [from the Arch repos](https://archlinux.org/packages/extra/x86_64/nvidia-utils/) with the "Download From Mirror" button, extract it, and copy over the whole `/usr/share/` directory from it to fill all missing files (mainly focused on `/usr/share/vulkan`'s ICDs, but there are some other files not otherwise filled in too).

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

### We've now removed the power limit

## Fixing power management

### The problem
With `system76-power` installed, you can just run `system76-power graphics integrated` to disable the NVIDIA GPU, and `system76-power graphics hybrid` to enable it again. Job done.

No.

I mean, not no, that works, but not _fully_, for me at least. In what way? Well, if you run `lscpi | grep NVIDIA`, take the PCIE device ID on the left (something like `02:00.0`), and place it into this path `/sys/bus/pci/devices/ID/power_state`, then `cat` that, you'll get the power state of your GPU. Ideally, `D0` when doing something graphically demanding, `D3cold` when not. Sadly, when in `hybrid` mode (no matter the `DRM` setting or anything like that), I'm stuck in `D0`, even with nothing utilising the GPU. That's 2-3W of power just being wasted, which is very significant in the context of a laptop's power consumption when doing light work. Weirdly, this issue is solved if the laptop _starts up_ in `integrated` mode, then _moved_ into `hybrid` mode. With that, regular apps will leave the dGPU alone (fully powered off), and intensive ones will power it up just as necessary.

### What do I need?
Therefore, I need three things:

* A way to force programs to use the GPU I want, so games can be shoved onto the NVIDIA card if they don't automatically cooperate, and lighter apps onto Intel
* A way to automatically enable `hybrid` mode on boot, and `integrated` mode on shutdown, so my laptop is always in a state where the GPU will dynamically turn on and off
* A way to see the current power state conveniently without running the `cat power_state` command manually, since I'd like to know whether the GPU's in use or not easily

### Force use of a specific GPU

#### Force NVIDIA:

For this, just use `prime-run`, it's available as `nvidia-prime` in the Arch repos, but - if you're using the `.run` driver, you can easily just take the script from [this repo](https://gitlab.archlinux.org/archlinux/packaging/packages/nvidia-prime) and be happy without any extra packages. To automate this (though you should obviously double-check the contents of the file before downloading it, as blindly executing files from the web isn't smart), just run the below commands:

```
curl -O -L https://gitlab.archlinux.org/archlinux/packaging/packages/nvidia-prime/-/raw/main/prime-run

echo "File contents:"
cat prime-run

chmod +x prime-run
mv prime-run /usr/bin/
```

#### Force Intel:

For this, I've made a 2-line text file called `unprime-run`, which currently only applies to Vulkan programs, but that's better than nothing.

```
curl -O -L https://gitlab.com/issacdowling/sb2-nv/-/raw/main/unprime-run

echo "File contents:"
cat unprime-run

chmod +x unprime-run
mv unprime-run /usr/bin
```

### Automatically handle changing between `hybrid` / `integrated` on boot
All I need to do is run `system76-power graphics integrated` on shutdown, and `system76-power graphics hybrid` on bootup. For this, it makes sense to use a service that handles this. It also sleeps before enabling the card (because otherwise there were issues), and runs `nvidia-smi` once in the background to make sure the card is actually fully up (it may not appear in Vulkan apps as an option without this step).

```
curl -O -L https://gitlab.com/issacdowling/sb2-nv/-/raw/main/dgpu-toggle-on-boot.service
sudo mv dgpu-toggle-on-boot.service /etc/systemd/system/
sudo chown root:root /etc/systemd/system/dgpu-toggle-on-boot.service
sudo chmod 644 /etc/systemd/system/dgpu-toggle-on-boot.service

# This is relevant for users on distros with SELinux
sudo restorecon /etc/systemd/system/dgpu-toggle-on-boot.service

sudo systemctl enable dgpu-toggle-on-boot.service --now
```

This does slow shutdown by around 30s, but does not slow boot.

### Showing the current mode constantly
I use Waybar, and - if you use waybar too - just go into your Waybar config, replace ID below with the PCIE ID you got when originally checking the power state, and add this:
```
"custom/pciepowerstate": {
    "exec": "cat /sys/bus/pci/devices/ID/power_state",
    "format": "{}  󰢮",
    "interval": 10
},
```
You need a nerdfont for the GPU icon to appear.

![Waybar showing the text d3cold](waybarpower.png)

## Closing notes:

### What's my power consumption like now? (checked with `upower -d`       )
* 4.8W - 15% brightness (perfectly comfortable for me indoors), web browser and a few terminals open, full resolution.

### Big `Distrobox` user? 
If you needn't mess with NVIDIA drivers within the container, and just want something seamless, create a container with the `--nvidia` flag for it to integrate with your host. If you want more flexibility to change files within the container, you can also install the `.run` drivers directly into your container (though they must be the same version that's on the host).

Here's what I did:

#### Install deps:
```
sudo pacman -S gcc make which acpid libglvnd pkgconfig --noconfirm
```

#### Remove X locks so the installer will run
```
sudo rm /tmp/.X*-lock
```

#### Install without kernel module
```
# Where did I get those arguments from? This repo: https://github.com/Docmine17/distrobox-nvidia
sudo nvidia-driver.run -a -N --ui=none --no-kernel-module
```

#### Restart the Distrobox.

### This all seems unnecessary, I'm having a much easier time
My laptop has a Pascal (1000 series) GPU, so it supports less modern driver features, and it's in a weird laptop. I _expect_ that other people's devices are behaving much more nicely.