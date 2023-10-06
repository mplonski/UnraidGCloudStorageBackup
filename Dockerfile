FROM alpine:3
LABEL AUTHOR="vinid223@gmail.com"

RUN apk add --no-cache python3 curl gcc python3-dev py3-setuptools py3-pip musl-dev

# install crc32 using a workaround
RUN curl -L -o crcmod.tar.gz "https://downloads.sourceforge.net/project/crcmod/crcmod/crcmod-1.7/crcmod-1.7.tar.gz"
RUN tar -xzf crcmod.tar.gz && cd crcmod-1.7/ && python3 setup.py install && cd ..

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
