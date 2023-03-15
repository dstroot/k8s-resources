FROM python:2-alpine
LABEL maintainer "Dan Stroot <dan.stroot@gmail.com>"

ENV PACKAGES bash libffi openssh-client openssl tini
ENV BUILD_PACKAGES gcc libffi-dev linux-headers musl-dev openssl-dev

RUN apk --no-cache add ${PACKAGES}
RUN adduser -D -H -u 19857 algo
RUN mkdir -p /algo

WORKDIR /algo
COPY requirements.txt .
RUN apk --no-cache add ${BUILD_PACKAGES} && \
    pip --no-cache-dir install -r requirements.txt && \
    apk del ${BUILD_PACKAGES}
COPY . .

# Because of the bind mounting of `configs/`, we need to run as the `root` user
# This may break in cases where user namespacing is enabled, so hopefully Docker 
# sorts out a way to set permissions on bind-mounted volumes (`docker run -v`)
# before userns becomes default
USER root
CMD [ "/algo/algo-docker.sh" ]
ENTRYPOINT [ "/sbin/tini", "--" ]