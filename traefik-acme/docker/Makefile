#
# Variables
#

DOCKER_NAME=dstroot/oauth2_proxy
VERSION=1.0.4
BINARY=v2.1/oauth2_proxy-2.1

#
# Build
#

all: build version push clean

build:
	# get the binary
	wget -O - https://github.com/bitly/oauth2_proxy/releases/download/$(BINARY).linux-amd64.go1.6.tar.gz | tar xfz - --strip-components 1
	# build the docker image
	docker build -t $(DOCKER_NAME):latest .

version:
	docker tag $(DOCKER_NAME):latest $(DOCKER_NAME):$(VERSION)

push:
	docker push $(DOCKER_NAME):latest
	docker push $(DOCKER_NAME):$(VERSION)
	
clean:
	rm -rf oauth2_proxy
