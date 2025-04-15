APP_NAME=dev_env

.PHONY: build up down shell logs restart prune

build:
	docker compose build

up:
	docker compose up -d

down:
	docker compose down

shell:
	docker exec -it $(APP_NAME) zsh

logs:
	docker compose logs -f

restart:
	docker compose down && docker compose up -d

prune:
	docker system prune -af --volumes
