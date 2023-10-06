FROM alpine:3
LABEL AUTHOR="vinid223@gmail.com"

RUN apk add --no-cache python3 curl gcc python3-dev py3-setuptools py3-pip
RUN pip3 uninstall crcmod
RUN pip3 install --no-cache-dir -U crcmod

RUN curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-396.0.0-linux-x86_64.tar.gz

RUN tar -xf google-cloud-cli-396.0.0-linux-x86_64.tar.gz

RUN ./google-cloud-sdk/install.sh --usage-reporting false -q

RUN rm google-cloud-cli-396.0.0-linux-x86_64.tar.gz

RUN mkdir -p /data

ADD run.sh /opt
ADD boto.config /root/.boto

RUN chmod +x /opt/run.sh

ENTRYPOINT [ "sh", "/opt/run.sh" ]

CMD ["setup"]
