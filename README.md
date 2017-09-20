# stroebs/simple-vsftpd

Minimal Alpine Linux Docker container with `vsftpd` exposed, supports PASV connections.

The entry script uses Augeas to configure VSFTPd and at the time of compiling this, `seccomp_sandbox` was missing from the Augeas lenses, so it had to be included manually.

Will only chroot users if `SYMLINK` is not set.

## Environment Options

- `PASV_ADDRESS` - *Required* - Reachable IP/hostname for your FTP
- `PASV_MIN` - *Required* - Minimum port for PASV connections
- `PASV_MAX` - *Required* - Maximum port for PASV connections
- `FTP_USERS` - *Required* - Create user accounts. eg `FTP_USERS=bob:pass:1000:1000,joe:secure:1001:1001`
- `SYMLINK` - Symlink directories for all users home directories, for ease of access. eg `SYMLINK=/data:data,/media:media`
- `FTP_BANNER` - Set a banner for your FTP service
- `DEBUG` - For debugging

## Example run usage
```
docker run \
  --name ftp \
  -d \
  -e FTP_USERS=user:pass:1000:1000,joe:secret:1001:1001 \
  -e PASV_ADDRESS=1.2.3.4 \
  -e PASV_MIN=21000 \
  -e PASV_MAX=21010 \
  -e SYMLINK=/data:data,/media:media \
  -p 21:21 \
  -p 21100-21110:21100-21110 \
  -v ./data:/data \
  -v ./media:/media \
  stroebs/simple-vsftpd
```

## Example usage in a docker-compose file
```
version: '3'
services:
  ftp:
   image: stroebs/simple-vsftpd
   ports:
     - "2121:21/tcp"
     - "21000-21010:21000-21010/tcp"
   volumes:
    - ./data:/data
    - ./media:/media
   environment:
    - FTP_USERS=user:pass:1000:1000,joe:secret:1001:1001
    - PASV_ADDRESS=1.2.3.4
    - PASV_MIN=21000
    - PASV_MAX=21010
    - SYMLINK=/data:data,/media:media
```
