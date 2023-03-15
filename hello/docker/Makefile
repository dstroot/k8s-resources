#
# Variables
#

DOCKER_NAME=dstroot
IMAGE_NAME=hello
VERSION=1.0.4
PROJECT=splendid-timer-160003

#
# Build
#

all: build version push clean

build:
	docker build -t $(DOCKER_NAME)/$(IMAGE_NAME):latest .

version:
	docker tag $(DOCKER_NAME)/$(IMAGE_NAME):latest $(DOCKER_NAME)/$(IMAGE_NAME):$(VERSION)
	docker tag $(DOCKER_NAME)/$(IMAGE_NAME) us.gcr.io/$(PROJECT)/$(IMAGE_NAME)

push:
	docker push $(DOCKER_NAME)/$(IMAGE_NAME):latest
	docker push $(DOCKER_NAME)/$(IMAGE_NAME):$(VERSION)
	gcloud docker -- push us.gcr.io/$(PROJECT)/$(IMAGE_NAME)