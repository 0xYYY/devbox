Build the image.
```
docker build -t devbox .
```

Start the container.
```
docker run -it -h box -v "$HOME"/Projects:/home/dev/Projects devbox
```
