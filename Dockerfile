FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    gdb \
    python3 \
    python3-pip \
    python3-dev \
    git \
    libssl-dev \
    libffi-dev \
    build-essential \
    wget \
    curl \
    netcat \
    socat \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir pwntools

RUN git clone https://github.com/pwndbg/pwndbg /opt/pwndbg && \
    cd /opt/pwndbg && \
    ./setup.sh

RUN useradd -m ctf
WORKDIR /home/ctf

COPY challenge.c .
COPY flag.txt .

RUN gcc challenge.c -o challenge -fno-stack-protector -no-pie

RUN echo "source /opt/pwndbg/gdbinit.py" >> /home/ctf/.gdbinit && \
    chown ctf:ctf /home/ctf/.gdbinit

RUN chown -R root:ctf /home/ctf && \
    chmod 750 /home/ctf/challenge && \
    chmod 440 /home/ctf/flag.txt

USER ctf
EXPOSE 1337

CMD ["socat", "TCP-LISTEN:1337,reuseaddr,fork", "EXEC:./challenge,stderr"]