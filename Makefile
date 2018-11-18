RELEASE?=1.1.27


clean:
	rm -rf public test data/releases.yml data/functions.json

run: deps
	# CSS gets mashed if we don't use --disableFastRender
	hugo server --disableFastRender

run-docker: deps
	# Runs hugo server in a docker container, container is automatically destroyed when stopped
	bash run-hugo-docker.sh

data:
	mkdir data/

data/releases.yml: data
	curl -fs https://repo.humio.com/repository/maven-releases/com/humio/server/$(RELEASE)/server-$(RELEASE).releases.yml > data/releases.yml

data/functions.json:
	curl -fs https://repo.humio.com/repository/maven-releases/com/humio/docs/queryfunctions/$(RELEASE)/queryfunctions-$(RELEASE).json > data/functions.json

deps: data/releases.yml data/functions.json

build: deps
	hugo

public: deps
	hugo
	docker build --tag="humio/docs:latest" .

test: public
	docker rm -f humio-docs || true
	docker run -d --name=humio-docs humio/docs
	mkdir -p test
	docker run --rm --user 1 -v ${PWD}/test:/data --link=humio-docs:humio-docs praqma/linkchecker linkchecker --no-status -ocsv http://humio-docs/ > test/report.csv
	docker rm -f humio-docs
