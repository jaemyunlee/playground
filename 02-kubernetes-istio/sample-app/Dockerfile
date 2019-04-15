FROM python:3.7.2-alpine3.8
LABEL maintainer="jaemyunlee"

COPY requirements.txt /tmp
RUN apk add --update --no-cache --virtual .build-deps  \
        build-base gcc libffi-dev jpeg-dev linux-headers && \
    pip install --upgrade -r /tmp/requirements.txt && \
    find /usr/local \
        \( -type d -a -name test -o -name tests \) \
        -o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
        -exec rm -rf '{}' + && \
    runDeps="$( \
        scanelf --needed --nobanner --recursive /usr/local \
                | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
                | sort -u \
                | xargs -r apk info --installed \
                | sort -u \
    )" && \
    apk add --virtual .rundeps $runDeps && \
    apk del .build-deps && \
    rm -rf /var/cache/apk/* && \
    rm /tmp/requirements.txt && \
    adduser -D -u 1001 noroot

ARG SERVICE_TYPE
ENV SERVICE_TYPE $SERVICE_TYPE

RUN mkdir -p app
COPY app.py /app
WORKDIR /app
RUN chown -R noroot:noroot /app
USER noroot

ENTRYPOINT ["/usr/local/bin/python"]

CMD ["app.py"]