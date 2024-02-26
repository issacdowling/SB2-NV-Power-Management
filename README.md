# Surface Book 2 dGPU

## Using This Tool:


Clone this repo, then put these files in /usr/bin so you can use them without cd'ing into this repo:
```
git clone https://gitlab.com/issacdowling/sb2-nv.git
cd sb2-nv
chmod +x gpu-*
chmod +x prime-run
sudo cp gpu-* /usr/bin/
sudo cp prime-run /usr/bin/
```

If you want to play games or edit video, no tearing:
`
gpu-hybrid
reboot
`

If you want to save battery life, integrated only:
`
gpu-integrated
reboot
`

If you want to know what mode you're in, query:
`
gpu-query
`

If you want to force an app to use the dGPU:
`
prime-run <command>
`