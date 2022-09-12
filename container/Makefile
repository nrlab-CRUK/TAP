
version ?= latest

build:
	docker build --tag nrlabcruk/nrlabtap:${version} .

release: build
	docker push nrlabcruk/nrlabtap:${version}


singularity: build
	singularity build nrlabtap-${version}.sif docker-daemon://nrlabcruk/nrlabtap:${version}

