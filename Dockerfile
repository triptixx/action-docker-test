FROM docker:stable

COPY *.sh label /usr/local/bin/
RUN apk add --no-cache coreutils jq curl xmlstarlet grep; \
    chmod 755 /usr/local/bin/*.sh;

ENTRYPOINT [ "/usr/local/bin/test.sh" ]
