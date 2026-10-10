# Older version of ssh in a container

A docker container with an older version of SSH to allow ssh access to embedded systems

The current version of openssh no longer supports RSA server keys <1024 bit which many embedded systems don't support

## Usage

```
docker run \
    -v $SSH_AUTH_SOCK:/var/run/ssh-agent.sock \
    -e SSH_AUTH_SOCK=/var/run/ssh-agent.sock \ 
    -it --rm timjdfletcher/oldssh <user>@<host>
```
or add to your shell aliases with:

alias oldssh='docker run -v $SSH_AUTH_SOCK:/var/run/ssh-agent.sock -it --rm timjdfletcher/oldssh'
