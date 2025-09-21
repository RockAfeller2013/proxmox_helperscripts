# Wow to download and install macOS on Promox
- How to download and install macOS - http://updates-http.cdn-apple.com/2019/cert/061-39476-20191023-48f365f4-0015-4c41-9f44-39d3d2aca067/InstallOS.dmg


```

# 1. Download installer DMG
curl -O http://updates-http.cdn-apple.com/2019/cert/061-39476-20191023-48f365f4-0015-4c41-9f44-39d3d2aca067/InstallOS.dmg

# 2. Mount the DMG
hdiutil attach InstallOS.dmg

# 3. Create a temporary empty image
hdiutil create -o /tmp/Sonoma -size 15000m -layout SPUD -fs HFS+J

# 4. Mount the temporary image
hdiutil attach /tmp/Sonoma.dmg -noverify -mountpoint /Volumes/Sonoma

# 5. Copy installer contents
rsync -av /Volumes/InstallOS/ /Volumes/Sonoma/

# 6. Detach both
hdiutil detach /Volumes/InstallOS
hdiutil detach /Volumes/Sonoma

# 7. Convert to ISO
hdiutil convert /tmp/Sonoma.dmg -format UDTO -o /tmp/Sonoma.iso

# 8. Rename to .iso
mv /tmp/Sonoma.iso.cdr ~/Desktop/Sonoma.iso

```
