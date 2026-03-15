FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    gcc python3 python3-pip gdb wget socat \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir pwntools

RUN wget -O /home/ctf/.gdbinit-gef.py -q https://gef.blah.cat/py && \
    echo "source /home/ctf/.gdbinit-gef.py" >> /home/ctf/.gdbinit

RUN useradd -m ctf
WORKDIR /home/ctf
COPY challenge.c flag.txt ./

RUN gcc challenge.c -o challenge -fno-stack-protector

RUN chown -R ctf:ctf /home/ctf && \
    chmod 750 /home/ctf/challenge && \
    chmod 440 /home/ctf/flag.txt

USER ctf
EXPOSE 1337

CMD ["socat", "TCP-LISTEN:1337,reuseaddr,fork", "EXEC:./challenge,stderr"]