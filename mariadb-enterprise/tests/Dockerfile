FROM centos:7

CMD ["mkdir /root/ssb"]
COPY ./ssb/ /root/ssb
RUN ln -s /root/ssb /ssb-tests

RUN yum -y  install \
            mysql \
            mysql-devel\
            which \
            libtool \
            make \
            automake \
            #numactl \
            #sysstat\
            && yum clean all

RUN cd /ssb-tests/ && make clean && make 
RUN cd /ssb-tests && ./dbgen -s 2   -T s
RUN cd /ssb-tests && ./dbgen -s 2   -T p
RUN cd /ssb-tests && ./dbgen -s 2   -T d
RUN cd /ssb-tests && ./dbgen -s 2   -T c
RUN cd /ssb-tests && ./dbgen -s 2   -T l

ENTRYPOINT ["top", "-b"]

CMD ["-c"]
