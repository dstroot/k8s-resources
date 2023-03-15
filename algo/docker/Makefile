#
# Variables
#

DOCKER_NAME=dstroot/algo
VERSION=0.0.2

#
# Build
#

all: build version push clean

build:
	docker build -t $(DOCKER_NAME):latest .

version:
	docker tag $(DOCKER_NAME):latest $(DOCKER_NAME):$(VERSION)

push:
	docker push $(DOCKER_NAME):latest
	docker push $(DOCKER_NAME):$(VERSION)
	
clean:
	echo "Completed"
