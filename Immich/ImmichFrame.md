```
- bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/immichframe.sh)"

```


## Setup API Key

- After installation, edit /opt/immichframe/Config/Settings.yml and set ImmichServerUrl and ApiKey. Then restart the service with systemctl restart immichframe.
- Get API Key - http://192.168.1.52:2283/user-settings?isOpen=sharing+api-keys
- Profile | Account Settings | API Keys | Select All
- http://192.168.1.48:8080/admin
- http://192.168.1.52:2283
- nano  /opt/immichframe/Config/Settings.yml
- Enter the exactly below
- Get the Admin password and set the same again, Save then test connection. this seems to work, you need to insert the password in the .xml and the UI as well. 



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
systemctl cat immichframe
curl -i http://192.168.1.52:2283/api/server/ping

curl -i \
  -H 'x-api-key: NtRgbBwd3KAKLN1RW68L569akrjgcuG05t6nPBsU' \
  http://192.168.1.52:2283/api/users/me

read -rsp "Immich API key: " IMMICH_API_KEY
echo
curl -sS -o /dev/null -w "HTTP %{http_code}\n" \
  -H "x-api-key: ${IMMICH_API_KEY}" \
  http://192.168.1.52:2283/api/users/me
unset IMMICH_API_KEY
```

```bash
systemctl edit immichframe

[Service]
Environment="IMMICHFRAME_ADMIN_PASSWORD=ReplaceWithYourNewStrongPassword"

systemctl daemon-reload
systemctl restart immichframe
```
