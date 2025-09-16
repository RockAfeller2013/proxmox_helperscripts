```

cd /var/lib/vz/template/iso && wget -qO kali.iso "$(wget -qO- https://cdimage.kali.org/kali-images/current/ | grep -oP 'kali-linux-\d+\.\d+-installer-amd64\.iso' | head -1 | xargs -I{} echo https://cdimage.kali.org/kali-images/current/{})" 
```
