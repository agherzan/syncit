FROM ubuntu:16.04

RUN apt-get update
RUN apt-get install -y git gcc make dmsetup btrfs-tools dosfstools
RUN mkdir -p ~/.ssh
RUN echo "Host github.com\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config
ENV SYNCIT_TAG v0.0.2
RUN cd /tmp/ && git clone https://github.com/agherzan/syncit.git && cd syncit && git checkout $SYNCIT_TAG && make && make install
RUN cd /tmp/ && git clone https://github.com/josefbacik/log-writes.git && cd log-writes && make && cp /tmp/log-writes/replay-log /bin

ADD ./dm-log-writes-test.sh /bin
RUN chmod a+x /bin/dm-log-writes-test.sh

CMD /bin/dm-log-writes-test.sh ext4
