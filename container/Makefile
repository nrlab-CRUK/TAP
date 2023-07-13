version ?= 2.2.0
image ?= nrlabtap-${version}.sif

build:
	docker build --tag nrlabcruk/nrlabtap:${version} .

release: build
	# Cannot push to Dockerhub because the image contains Agent.
	# docker push nrlabcruk/nrlabtap:${version}

singularity: build
	rm -f ${image}
	singularity build ${image} docker-daemon://nrlabcruk/nrlabtap:${version}
	chmod a-x ${image}

deploy: singularity
	scp ${image} clust1-headnode:/mnt/scratcha/bioinformatics/rosenfeld_containers
	scp ${image} clust1-sub:/mnt/scratchc/bioinformatics/rosenfeld_containers
