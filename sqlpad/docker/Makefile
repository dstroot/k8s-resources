#
# Variables
#

SQLPAD_VERSION?=1.17.2
DOCKER_NAME=dstroot/sqlpad

#
# Build
#

all: template build version push clean

template:
	sed 's/{{SQLPAD_VERSION}}/$(SQLPAD_VERSION)/' Dockerfile.tpl > Dockerfile

build:
	docker build -t $(DOCKER_NAME):latest .

version:
	docker tag $(DOCKER_NAME):latest $(DOCKER_NAME):$(SQLPAD_VERSION)

push:
	docker push $(DOCKER_NAME):latest
	docker push $(DOCKER_NAME):$(SQLPAD_VERSION)

clean:
	rm -f Dockerfile
