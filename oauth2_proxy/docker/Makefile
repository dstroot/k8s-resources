#
# Variables
#

DOCKER_NAME=dstroot
IMAGE_NAME=oauth2_proxy
VERSION=1.0.4
BINARY=v2.1/oauth2_proxy-2.1
PROJECT=splendid-timer-160003

#
# Build
#

all: build version push clean

build:
	# get the binary
	wget -O - https://github.com/bitly/oauth2_proxy/releases/download/$(BINARY).linux-amd64.go1.6.tar.gz | tar xfz - --strip-components 1
	# build the docker image
	docker build -t $(DOCKER_NAME)/$(IMAGE_NAME):latest .

version:
	docker tag $(DOCKER_NAME)/$(IMAGE_NAME):latest $(DOCKER_NAME)/$(IMAGE_NAME):$(VERSION)
	docker tag $(DOCKER_NAME)/$(IMAGE_NAME) us.gcr.io/$(PROJECT)/$(IMAGE_NAME)

push:
	docker push $(DOCKER_NAME)/$(IMAGE_NAME):latest
	docker push $(DOCKER_NAME)/$(IMAGE_NAME):$(VERSION)
	gcloud docker -- push us.gcr.io/$(PROJECT)/$(IMAGE_NAME)

clean:
	rm -rf oauth2_proxy
