# not-s76-power

## Usage:

Clone this repo, then put these files in /bin so you can use them without cd'ing into this repo:
`
git clone https://gitlab.com/issacdowling/not-s76-power.git
cd not-s76-power
chmod +x gpu-*
sudo cp gpu-* /bin/
`

Use optimus:
`
gpu-hybrid
`

Integrated only:
`
gpu-integrated
`

Query:
`
gpu-query
`

### Why does this exist?

My laptop has a dedicated NVIDIA GPU, and I wanted to control it since it wastes around 3-4w of power when doing nothing if the driver is loaded (fairly significant percentage-wise, since it took my 6w idle to 10w, a 2/3 increase in power consumption while idling). However, system76-power was doing way more than I wanted, and took quite a while to apply changes before I could restart, and was also not entirely reliable for me. 

### What does it do?
Here are some bash scripts that with block / unblock the NVIDIA driver from running. If you want NVIDIA on *with* your integrated GPU (NVIDIA optimus) choose hybrid, if you want no NVIDIA, choose integrated. This should be used with the closed-source, official NVIDIA drivers, not nouveau.

Integrated creates rules that stop the nvidia driver from running, Hybrid deletes those. This is way simpler than anything else, since those more complicated solutions (Envycontrol and System76-power break my system and take a while to run.)