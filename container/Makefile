
version ?= 2.0.0
image ?= nrlabtap-${version}.sif

build:
	docker build --tag nrlabcruk/nrlabtap:${version} .

release: build
        # Cannot push to Dockerhub because the image contains Agent.
	# docker push nrlabcruk/nrlabtap:${version}

singularity: build
	rm -f ${image}
	singularity build ${image}.sif docker-daemon://nrlabcruk/nrlabtap:${version}
	chmod a-x ${image}

