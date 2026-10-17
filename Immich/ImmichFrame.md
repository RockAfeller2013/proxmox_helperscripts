```
- bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/immichframe.sh)"

```

After installation, edit /opt/immichframe/Config/Settings.yml and set ImmichServerUrl and ApiKey. Then restart the service with systemctl restart immichframe.

## Setup API Key
- http://192.168.1.52:2283/user-settings?isOpen=sharing+api-keys
- Profile | Account Settings | API Keys | Select All

NtRgbBwd3KAKLN1RW68L569akrjgcuG05t6nPBsU
http://192.168.1.52:2283/photos

```bash
Accounts:
  - ImmichServerUrl: "http://192.168.1.52:2283"
    piKey: "NtRgbBwd3KAKLN1RW68L569akrjgcuG05t6nPBsU"
    ImagesFromDate: null
    ImagesUntilDate: null
    ImagesFromDays: null
    ShowMemories: false
    ShowFavorites: false
    ShowArchived: false
    ShowVideos: true
    Rating: null
    Albums: []
    ExcludedAlbums: []
    People: []
    Tags: []
```

```bash
curl -i http://192.168.1.52:2283/api/server/ping

curl -i \
  -H 'x-api-key: NtRgbBwd3KAKLN1RW68L569akrjgcuG05t6nPBsU' \
  http://192.168.1.52:2283/api/users/me
```
