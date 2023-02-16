FROM --platform=linux/x86_64 centos/python-36-centos7

USER root 

# Create a dev directory
RUN mkdir /home/qbie

# Install packages
RUN yum install -y wget vim
RUN wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
RUN rpm -ivh epel-release-latest-7.noarch.rpm
RUN yum -y install rlwrap vim

# Copy across the q binary, license file and q.k bootstrap file
COPY q /kdb

# Set env variables
ENV QHOME /kdb/
ENV PATH ${PATH}:${QHOME}l64/
ENV QLIC /kdb

# Upgrade pip
#RUN /opt/app-root/bin/python3.8 -m pip install --upgrade pip 
RUN /opt/app-root/bin/python3.6 -m pip install --upgrade pip 

# Pull embedpy & tar zip it
RUN wget -P /etc/embedPy/ https://github.com/KxSystems/embedPy/releases/download/1.5.0/embedPy_linux-1.5.0.tgz && \
    cd /etc/embedPy/ && \
    tar -zxvf embedPy_linux-1.5.0.tgz && \
    mv p.k p.q $QHOME && mv l64/p.so $QHOME/l64/ && \ 
    rm embedPy_linux-1.5.0.tgz

# Pull jupyterQ, install requirements and run install.sh
RUN wget -P /etc/jupyterq/ https://github.com/KxSystems/jupyterq/releases/download/1.1.14/jupyterq_linux-1.1.14.tgz && \
    cd /etc/jupyterq/ && \
    tar -zxvf jupyterq_linux-1.1.14.tgz && rm jupyterq_linux-1.1.14.tgz && \
    pip install -r /etc/jupyterq/requirements.txt && \
    ./install.sh 

WORKDIR /home/qbie

# Copy Requirements.txt
COPY requirements.txt .

# Install the required modules
RUN pip install -r requirements.txt
