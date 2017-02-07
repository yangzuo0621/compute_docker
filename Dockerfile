FROM debian:jessie

MAINTAINER bjyangzuo <bjyangzuo@corp.netease.com>
RUN echo "deb http://mirrors.aliyun.com/debian/ jessie main contrib non-free" > /etc/apt/sources.list
RUN apt-get update
RUN apt-get upgrade -y

RUN apt-get purge -y python.*

ENV PYTHON_VERSION 2.7.13
ENV PYTHON_URL https://www.python.org/ftp/python/2.7.13/Python-$PYTHON_VERSION.tar.xz

RUN buildDeps=' \
              ca-certificates \
              wget \
              xz-utils \
              gcc \
              g++ \
              libsasl2-dev \
              libpcre++-dev \
              libssl-dev \
              make \
    ' \
    set -x \
    && apt-get install -y --no-install-recommends $buildDeps \
    && rm -r /var/lib/apt/lists/* \
    \
    && wget -c "$PYTHON_URL" -O python.tar.xz \
    && mkdir -p /usr/src/python \
    && tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz \
    && rm python.tar.xz \
    \
    && cd /usr/src/python \
    && ./configure --enable-shared --enable-unicode=ucs4 \
    && make -j$(nproc) \
    && make install \
    && ldconfig \
    && wget https://bootstrap.pypa.io/ez_setup.py -O - | python \
    && easy_install pip \
    && find /usr/local -depth \
         \( \
             \( -type d -a -name test -o -name tests \) \
             -o \
             \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
         \) -exec rm -rf '{}' + \
    && rm -rf /usr/src/python ~/.cache \
    && rm -rf *.zip

RUN mkdir /apitmp
ADD mining-api.tar.gz /apitmp/
RUN cd /apitmp/mining-api-master-*/storage-py && python setup.py install
RUN rm -rf /apitmp

RUN mkdir /py
ADD ComputingFramework/ /py/
RUN cd /py && pip install -r requirements.txt

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y --no-install-recommends sasl2-bin libsasl2-2 libsasl2-dev libsasl2-modules

RUN buildDeps=' \
              wget \
              xz-utils \
              gcc \
              g++ \
              libsasl2-dev \
              libpcre++-dev \
              libssl-dev \
              make \
    ' \
    set -x \
    && apt-get purge -y --auto-remove $buildDeps

RUN mkdir /log
VOLUME ["/log"]

WORKDIR /py/framework
CMD ["python", "computing_framework.py"]
