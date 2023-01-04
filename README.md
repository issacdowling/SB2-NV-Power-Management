# not-s76-power


### Why does this exist?

My laptop has a dedicated NVIDIA GPU, and I wanted to control it since it wastes around 3-4w of power when doing nothing if the driver is loaded (fairly significant percentage-wise, since it took my 6w idle to 10w, a 2/3 increase in power consumption while idling). However, system76-power was doing way more than I wanted, and took quite a while to apply changes before I could restart, and was also not entirely reliable for me. 

### What does it do?
Here are some bash scripts that with block / unblock the NVIDIA driver from running. If you want NVIDIA on *with* your integrated GPU (NVIDIA optimus) choose hybrid, if you want no NVIDIA, choose integrated. If I choose integrated, I must - after the reboot - run `sudo surface dgpu set-runtime-pm on` to actually make the GPU go idle (otherwise it actually uses *more* energy, so I assume on other devices you may need to find a way to enable runtime pm.)