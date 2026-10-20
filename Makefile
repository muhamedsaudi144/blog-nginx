.PHONY: build run stop soft_clean clean logs shell

build:
	docker compose build --no-cache

run:
	docker compose up

stop:
	docker compose stop 

soft_clean:
	docker compose down

clean:
	docker compose down --remove-orphans --volumes

logs:
	docker compose logs nginx --tail 10 --follow

shell:
	docker compose exec nginx /bin/bash
