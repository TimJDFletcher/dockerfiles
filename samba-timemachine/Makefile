all: status
update: update_docker

DC := /usr/bin/docker-compose
update_docker:
	${DC} pull
	${DC} up -d
status:
	${DC} ps
	${DC} exec samba-timemachine smbstatus
logs:
	${DC} logs --follow  --tail="100"
clean:
	${DC} down