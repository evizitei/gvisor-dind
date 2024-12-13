# play with gvisor in a local docker container

## Build

```bash
docker build -t dind-gvisor .
```

## Run

```bash
docker run --privileged -d --name dind-gvisor-ctn dind-gvisor
```
