
version ?= latest

build:
	docker build --tag nrlabcruk/nrlabtap:${version} .

release: build
	docker push nrlabcruk/nrlabtap:${version}

