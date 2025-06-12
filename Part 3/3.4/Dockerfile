FROM docker:stable-git

WORKDIR /app

COPY ./dockerized_deploy.sh /usr/local/bin/dockerized_deploy.sh

RUN chmod +x /usr/local/bin/dockerized_deploy.sh

ENTRYPOINT ["/usr/local/bin/dockerized_deploy.sh"]
