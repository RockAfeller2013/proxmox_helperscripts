# Raspberry PI 5 Setup

## Configure M.2

```bash
boot/firmware/config.txt file and adding following parameter:
dtparam=pciex1
dtparam=pciex1_gen=3  # optional
```

```
from gpiozero import LED
import time


uid_led = LED(4)

while True:
    uid_led.on()  # turn on led 
    time.sleep(5)
    uid_led.off() # turn off led 
    time.sleep(5)
```

```bash
For Raspbian and RetroPie OS.
cd ~
git clone https://github.com/DeskPi-Team/deskpi.git
cd ~/deskpi/
chmod +x install.sh
sudo ./install.sh
```
- https://deskpi.com/blogs/learn/getting-start-how-to-install-deskpi-driver
- https://wiki.52pi.com/index.php?title=EP-0234
- https://www.youtube.com/watch?v=ZpW4YHlEElo
