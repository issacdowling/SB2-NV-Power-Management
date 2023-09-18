# not-s76-power

## Usage:

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