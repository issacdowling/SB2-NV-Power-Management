# Surface Book 2 dGPU

## Below this section is some explanation about weird Surface Book 2 Nvidia stuff, but
## This is how to set up my script to handle stuff (AFTER installing driver):


Clone this repo, then put these files in /bin so you can use them without cd'ing into this repo:
```
git clone https://gitlab.com/issacdowling/gpu-optimus-power-control.git
cd gpu-optimus-power-control
chmod +x gpu-*
sudo cp gpu-* /bin/
```

If you want to play games or edit video, no tearing:
`
gpu-hybrid
reboot
`

If you want to use CUDA/compute only, yes tearing but only for apps using the dGPU:
`
gpu-compute
reboot
`

If you want to save battery life, ntegrated only:
`
gpu-integrated
reboot
`

If you want to know what mode you're in, query:
`
gpu-query
`

### Why does this exist?

My laptop has a dedicated NVIDIA GPU, and I wanted to control it since it wastes around 3-4w of power when doing nothing if the driver is loaded (fairly significant percentage-wise, since it took my 6w idle to 10w, a 2/3 increase in power consumption while idling). However, system76-power was doing way more than I wanted, and took quite a while to apply changes before I could restart, and was also not entirely reliable for me. 

This is way simpler than anything else, since those more complicated solutions (Envycontrol and System76-power) break my system and take a while to run.

# NV SB2
Getting the most out of your GTX 1050/60 on a Surface Book 2 is... hard.

In this repo, you'll find Surface Book 2 specific tips, along with general NVIDIA tips since they go hand-in-hand. If you're an Xorg user, this may be of use for you, however I'm Wayland all the way, so I've put no specific thought into anything else.

I've used these tips on GNOME Wayland and Hyprland, running on Fedora Server, on a 15" Surface Book 2 with a GTX 1060.

I'm going to skip over the details of the issues I've had, since that'll probably get a blog post or a video, and get straight to the solutions.

## My GPU is unable to go above ~7W of power consumption when on battery

I have no clue what causes this issue, but at least I know how to solve it.

You're going to need the DKMS NVIDIA drivers, since we need to modify the open parts of them. This isn't a problem on most distros, but Fedora does stuff weirdly (akmods rather than DKMS) by default, so I need to do some extra setup. Skip to the tick emoji if you already have dkms drivers (check by typing `dkms status`, which will show the NVIDIA drivers if you do).

There is no fedora38 repo yet, and we're nearly at fedora 39, which makes me think that NVIDIA might be dropping fedora from their repos. If you'd like a wonkier alternative to what I'm about to go through, incase Fedora IS removed later, use `sudo dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64`, and go through probable dependency hell trying to convince things to work on Fedora. Fedora 37 repos work for me right now. 

### So, here's the method I use as of now

```
sudo dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/fedora37/x86_64
sudo nano /etc/yum.repos.d/developer.download.nvidia.com_compute_cuda_repos_fedora37_x86_64.repo
```
and add `module_hotfixes=1` to the bottom of that file, then save. This disables some newer packages being skipped due to `modular filtering`, which I don't fully understand, but this makes it work and otherwise I get different packages with mismatched versions, causing breakage.

Now, we just run:
```
sudo dnf module install nvidia-driver:latest-dkms --setopt=install_weak_deps=True --setopt=module_stream_switch=True --nogpgcheck
sudo dnf install cuda
```
then reboot your laptop and it's installed.

### Modifications

Assuming you've got the drivers installed (run `dkms status` to check), you'll want to run `sudo nano /usr/src/nvidia-VERSION/nvidia/nv-acpi.c`, go down to the `ac_plugged` line, and change it to `*ac_plugged = NV_TRUE;`

Then, run 
```
sudo dkms remove nvidia/version
sudo dkms install nvidia/version
```
which will rebuild with your change.

Restart, and you should now be good.

## My GPU is not going to sleep (stuck in D0)

This assumes you've got the proprietary drivers in use.

Linux-surface has a [section about this](https://github.com/linux-surface/surface-hotplug/wiki/Runtime-Power-Management), but they recently begun suggesting the use of environment variables which caused issues with some apps for me - something something EGL errors - so I still use the old method.

Run this, which makes your wayland DE unable to use your NVIDIA card, allowing it to sleep. Apps can still be told to run on your card.
```
sudo mv /usr/share/glvnd/egl_vendor.d/10_nvidia.json /usr/share/glvnd/egl_vendor.d/10_nvidia.json.backup
```

Assuming you use `surface-control`, you can just run `surface dgpu get-power-state` to check this, since it's quick, and `nvidia-smi` FALSELY reports high power consumption when in this mode, despite the *whole system* sometimes being as low as 5W of real consumption when idling.

## Weird tearing when using NVIDIA GPU

You need to enable nvidia_drm modesetting.

sudo nano /etc/modprobe.d/gpu.conf

then paste:
```
options nvidia-drm modeset=1
```
and reboot. This'll fix the tearing, but now you might be back to being stuck in D0, even with nothing running on your GPU. THAT is why the start of this guide suggests just using my script.

## I didn't already have prime-run and now need a way to make apps definitely use my GPU

```
echo  '#!/bin/bash
export __NV_PRIME_RENDER_OFFLOAD=1 __VK_LAYER_NV_optimus=NVIDIA_only __GLX_VENDOR_LIBRARY_NAME=nvidia
__EGL_VENDOR_LIBRARY_FILENAMES="/usr/share/glvnd/egl_vendor.d/50_mesa.json"
exec "$@"' >> prime-run

chmod +x prime-run
mv prime-run /bin/
```
Now, just add `prime-run` before the command you run (this can work in .desktop files too), and it'll use your dGPU.
