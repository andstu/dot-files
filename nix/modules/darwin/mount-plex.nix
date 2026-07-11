{ ... }:

# Mount personal NAS media share at boot (root required for resvport).
{
  launchd.daemons.mount-plex-nfs = {
    script = ''
      set -euo pipefail

      NFS_SHARE="10.0.0.15:/mnt/media/plex"
      MOUNT_POINT="/Volumes/plex"
      OPTS="vers=3,resvport,nolocks,locallocks"

      mkdir -p "$MOUNT_POINT"

      if /sbin/mount | /usr/bin/grep -q " on $MOUNT_POINT "; then
        exit 0
      fi

      # Network / NAS may not be ready yet at boot.
      for _ in $(/usr/bin/seq 1 36); do
        if /sbin/ping -c 1 -W 1000 10.0.0.15 >/dev/null 2>&1; then
          if /sbin/mount -t nfs -o "$OPTS" "$NFS_SHARE" "$MOUNT_POINT"; then
            exit 0
          fi
        fi
        sleep 5
      done

      echo "failed to mount $NFS_SHARE on $MOUNT_POINT" >&2
      exit 1
    '';

    serviceConfig = {
      Label = "com.andstu.mount-plex-nfs";
      RunAtLoad = true;
      # Re-check periodically (no-op if already mounted) after sleep/wake or NAS blips.
      StartInterval = 300;
      StandardOutPath = "/var/log/mount-plex-nfs.log";
      StandardErrorPath = "/var/log/mount-plex-nfs.log";
    };
  };
}
