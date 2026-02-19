# Install Gitlab

In order to install GitLab on Proxmox, you can use either Docker and/or TurnKey via GUI / CT Templates https://www.linkedin.com/in/barry-smith-200b0052/

## Docker
- https://hub.docker.com/r/gitlab/gitlab-ce/?_gl=1*yyf43q*_gcl_au*Nzk5MDYxNjA3LjE3NzAwODkxNzM.*_ga*MTA3MjQ3MzAwLjE3NzAwODkxNzI.*_ga_XJWPQMJYHQ*czE3NzE0OTEzMTgkbzYkZzEkdDE3NzE0OTEzMTgkajYwJGwwJGgw
```
docker pull gitlab/gitlab-ce:nightly

```

## Turnkey

Steps to Enable and Use CT Templates
Enable Template Content Type:
Navigate to Datacenter in the left menu.
Select Storage and click on your storage device (usually local or pve).
Click Edit.
In the Content dropdown, ensure CT Template is selected.
Download a Template:
Select the storage (e.g., local) under your node.
Click on CT Templates in the menu.
Click the Templates button in the top menu bar.

```
```
