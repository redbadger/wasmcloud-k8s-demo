COLOR ?= always # Valid COLOR options: {always, auto, never}
CARGO = cargo --color $(COLOR)
TARGET = target/wasm32-unknown-unknown
DEBUG = $(TARGET)/debug
RELEASE = $(TARGET)/release
KEYDIR ?= .keys
VERSION = $(shell cargo metadata --no-deps --format-version 1 | jq -r '.packages[].version')
CAPABILITIES = -c wasmcloud:keyvalue -c wasmcloud:logging -c wasmcloud:httpserver

.PHONY: all build check clean doc test update
all: setup-redis setup-nats run

.PHONY: setup-redis
setup-redis: 
	# exit code 0 if redis is already running on the assigned port
	docker run --rm --detach -p 6379:6379 --name todo-backend-store redis; exit 0

.PHONY: setup-nats
setup-nats: 
	docker run --rm --detach --name nats -p 4222:4222 -p 8222:8222 nats; exit 0

.PHONY: run
run:
	TODO_ACTOR=$(shell wash claims inspect $(DEBUG)/todo_backend_s.wasm --output json | jq .module -r) \
	KVCACHE_NATS_URL=0.0.0.0 pnpx -y concurrently "sleep 0; wasmcloud -m manifest.yaml" "sleep 5; wasmcloud -m manifest_actor.yaml" "sleep 10; wasmcloud -m manifest_http.yaml"

.PHONY: build
build:
	@$(CARGO) build
	wash claims sign $(DEBUG)/todo_backend.wasm ${CAPABILITIES} --name "todo-backend" --ver $(VERSION) --rev 0
	
.PHONY: check
check:
	@$(CARGO) check

.PHONY: clean
clean:
	@$(CARGO) clean

.PHONY: doc
doc:
	@$(CARGO) doc

.PHONY: test
test: build
	@$(CARGO) test

.PHONY: update
update:
	@$(CARGO) update

.PHONY: release
release:
	@$(CARGO) build --release	
	wash claims sign $(RELEASE)/todo_backend.wasm ${CAPABILITIES} --name "todo-backend" --ver $(VERSION) --rev 0