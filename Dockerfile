FROM splunk/universalforwarder:8.2.0

WORKDIR /app

COPY container-files container-files/

USER root

RUN mkdir -p /app/forcepoint-logs \
    && chmod 700 container-files/entrypoint.sh
    
ENTRYPOINT ["./container-files/entrypoint.sh"]
