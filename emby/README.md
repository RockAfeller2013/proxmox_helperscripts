# Permisions

1. If Ember means Emby
1. Open the Emby web dashboard.
2. Go to Dashboard → Library.
3. Edit your Music library and check its folder path.
4. Use the local path where the Synology music share is mounted, for example /mnt/music, rather than an SMB URL containing credentials.
2. Check the Synology credentials and permissions
On the Synology, open Control Panel → Shared Folder → music → Edit → Permissions. Ensure the account used by your SMB mount has read access. If Emby runs directly on Synology DSM 7, also grant the internal emby system user access to the music folder.
