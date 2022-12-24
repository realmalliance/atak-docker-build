# atak-docker-build

Build ATAK from source with one command.

See [talentedbrute/buildTAK](https://github.com/talentedbrute/buildTAK)
for a similar build script that does not use Docker.

## Building the APK
_Because there are several large file downloads and compilation takes
a while, we recommend running this in a screen session on a cloud
machine._

Make sure Docker is installed (see https://docs.docker.com/get-docker/).

Run:
```
docker build --progress=plain -t atak-build . 2>&1 | tee -a out.log
```

Copy the APK out of built image:
```
docker cp `docker create atak-build`:/AndroidTacticalAssaultKit-CIV/atak/ATAK/app/build/outputs/apk/civ/debug .
```

The APK will be in `debug`.
