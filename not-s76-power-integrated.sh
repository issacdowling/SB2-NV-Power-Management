sudo rm /etc/modprobe.d/dgpu.conf

echo "Creating dgpu.conf"

touch dgpu.conf
echo "blacklist i2c_nvidia_gpu" >> dgpu.conf
echo "blacklist nouveau" >> dgpu.conf
echo "blacklist nvidia" >> dgpu.conf
echo "blacklist nvidia-drm" >> dgpu.conf
echo "blacklist nvidia-modeset" >> dgpu.conf
echo "alias i2c_nvidia_gpu off" >> dgpu.conf
echo "alias nouveau off" >> dgpu.conf
echo "alias nvidia off" >> dgpu.conf
echo "alias nvidia-drm off" >> dgpu.conf
echo "options nvidia-drm modeset=1" >> dgpu.conf

sudo mv dgpu.conf /etc/modprobe.d/dgpu.conf

echo "Reboot now. NVIDIA disabled."
