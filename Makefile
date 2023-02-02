
.PHONY: install dist update up down sampledata
SHELL=/bin/bash


help: ## Print this message
	@awk 'BEGIN { FS = ":.*##"; print "Usage:  make <target>\n\nTargets:" } \
/^[-_[:alpha:]]+:.?*##/ { printf "  %-15s%s\n", $$1, $$2 }' $(MAKEFILE_LIST)

install: ## Install ruby dependencies
	bundle install

dist: ## Build docker container
	docker build -t timdex .

update: install ## Update all ruby dependencies
	bundle update

up: ## Startup elasticsearch and timdex
	docker-compose up -d

down: ## Shutdown elasticsearch and timdex containers
	docker-compose down

sampledata: ## Load sample Aleph and Aspace data. Run `up` first then wait for services.
	docker pull mitlibraries/mario:latest
	docker run --network timdex_default --mount type=bind,src=`pwd`/sample_data,dst=/sample_data mitlibraries/mario:latest --url http://elasticsearch:9200 ingest -s aleph --new --auto /sample_data/mit_test_records.mrc
	docker run --network timdex_default --mount type=bind,src=`pwd`/sample_data,dst=/sample_data mitlibraries/mario:latest --url http://elasticsearch:9200 ingest -s aspace --new --auto /sample_data/aspace_samples.xml

refresh_graphiql_deps: ## Updates dependencies for GraphiQL playground
	wget --directory-prefix=./public -N --remote-encoding=UTF-8 --local-encoding=UTF-8 https://unpkg.com/react@17/umd/react.development.js
	wget --directory-prefix=./public -N --remote-encoding=UTF-8 --local-encoding=UTF-8 https://unpkg.com/react-dom@17/umd/react-dom.development.js
	wget --directory-prefix=./public -N --remote-encoding=UTF-8 --local-encoding=UTF-8 https://unpkg.com/graphiql/graphiql.min.css
	wget --directory-prefix=./public -N --remote-encoding=UTF-8 --local-encoding=UTF-8 https://unpkg.com/graphiql/graphiql.min.css.map
	wget --directory-prefix=./public -N --remote-encoding=UTF-8 --local-encoding=UTF-8 https://unpkg.com/graphiql/graphiql.min.js
	wget --directory-prefix=./public -N --remote-encoding=UTF-8 --local-encoding=UTF-8 https://unpkg.com/graphiql/graphiql.min.js.map
