## FS atomicity / durability tests using dm log writes

### How to run

X86-64:

`docker run -ti --rm --privileged -v /dev:/dev alephan/dm-log-writes-test:latest-amd64`

ARMv7:

`docker run -ti --rm --privileged -v /dev:/dev alephan/dm-log-writes-test:latest-armv7`

This runs the script with no arguments. To check all the options, run:

`docker run -ti --rm --privileged -v /dev:/dev alephan/dm-log-writes-test:latest-amd64 dm-log-writes-test.sh -h`
