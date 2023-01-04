sudo rm /etc/modprobe.d/dgpu.conf

touch dgpu.conf
echo "blacklist i2c_nvidia_gpu" >> dgpu.conf
echo "alias i2c_nvidia_gpu off" >> dgpu.conf
echo "options nvidia NVreg_DynamicPowerManagement=0x02" >> dgpu.conf
echo "options nvidia-drm modeset=1" >> dgpu.conf

sudo mv dgpu.conf /etc/modprobe.d/dgpu.conf

echo "Reboot now."
