FROM ubuntu:24.04

# Use /usr/src/app as our workdir. The following instructions will be executed in this location.
WORKDIR /usr/src/app

# Copy the hello.sh file from this location to /usr/src/app/ creating /usr/src/app/hello.sh.
COPY script.sh .

RUN apt-get update
RUN apt-get -y install curl

CMD ./script.sh