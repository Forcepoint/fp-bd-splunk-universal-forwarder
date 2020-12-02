FROM splunk/universalforwarder:8.0.4.1

WORKDIR /app

COPY container-files container-files/

USER root

RUN mkdir -p /app/forcepoint-logs \
    && chmod 700 container-files/entrypoint.sh
    
ENTRYPOINT ["./container-files/entrypoint.sh"]
