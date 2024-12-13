# play with gvisor in a local docker container

## Build

```bash
docker build -t dind-gvisor .
```

## Run

```bash
docker run --privileged --cgroupns=host -v /sys/fs/cgroup:/sys/fs/cgroup:rw -d --name dind-gvisor-ctn dind-gvisor
```

## Enter a running container

```bash
docker ps
docker exec -it {the container id} /bin/bash
```

## Test gvisor

Run this mounted into the debian container that has docker
```bash
docker run --runtime=runsc hello-world
```
Should get a hello-world message^

Now to play with a shell in the gvisor container
```bash
docker run --runtime=runsc -it ubuntu bash
```