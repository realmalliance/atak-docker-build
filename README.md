# atak-docker-build

Build ATAK from source with one command.

We recommend running this in a screen session on a cloud machine
because there are several large file downloads and compilation takes a
while.

## Building the APK
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
