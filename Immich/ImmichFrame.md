```
- bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/immichframe.sh)"

```

After installation, edit /opt/immichframe/Config/Settings.yml and set ImmichServerUrl and ApiKey. Then restart the service with systemctl restart immichframe.

## Setup API Key
- http://192.168.1.52:2283/user-settings?isOpen=sharing+api-keys
- Profile | Account Settings | API Keys | Select All
- http://192.168.1.48:8080/admin
- http://192.168.1.52:2283

http://192.168.1.52:2283/photos


systemctl cat immichframe

```bash
Accounts:
  - ImmichServerUrl: 'http://192.168.1.52:2283'
    # Exactly one of ApiKey or ApiKeyFile must be set.
    ApiKey: 'jFCmDVikbmtsmTg8i9PuiP04yLCRpGVBQPAduanDko'
    # ApiKeyFile: "/path/to/api.key"

    ImagesFromDate: null
    ShowMemories: false
    ShowFavorites: false
    ShowArchived: false
    ShowVideos: false
    ImagesFromDays: null
    ImagesUntilDate: null
    Rating: null
    Albums:
    ExcludedAlbums:
    People:
    Tags:
```

```bash
curl -i http://192.168.1.52:2283/api/server/ping

curl -i \
  -H 'x-api-key: NtRgbBwd3KAKLN1RW68L569akrjgcuG05t6nPBsU' \
  http://192.168.1.52:2283/api/users/me
```
