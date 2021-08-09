# sshd
Docker action: sshd

## Usage

Prepare passwd

```sh
cat << 'EOF' > passwd
root:x:0:0:root:/root:/bin/bash
sshd:x:22:22:sshd privilege separation:/var/empty:/bin/false
myuser:x:1000:0:My User:/home/myuser:/bin/bash
EOF
```

Start sshd action container in the foreground
```sh
docker run --rm -it -v $HOME/.ssh/id_rsa.pub:/home/myuser/.ssh/authorized_keys:ro -v $(pwd)/passwd:/etc/passwd -p 2022:22 sshd -D -e
```

Connect
```sh
ssh -l myuser localhost -p 2022
```