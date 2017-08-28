# Use Ubuntu
FROM ubuntu:14.04
MAINTAINER TestAutomationGuru

# Install wger & JRE
RUN apt-get clean && \
	apt-get update && \
	apt-get -qy install \
			wget \
			telnet \
			iputils-ping \
			unzip

# Install java

RUN sed 's/main$/main universe/' -i /etc/apt/sources.list && \
    apt-get update && apt-get install -y software-properties-common && \
    add-apt-repository ppa:webupd8team/java -y && \
    apt-get update && \
    echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    apt-get install -y oracle-java8-installer libxext-dev libxrender-dev libxtst-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*


# Install jmeter
RUN   mkdir /jmeter \
	&& cd /jmeter/ \
	&& wget https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-3.1.tgz \
	&& tar -xzf apache-jmeter-3.1.tgz \
	&& rm apache-jmeter-3.1.tgz \
	&& mkdir /jmeter-plugins \
	&& cd /jmeter-plugins/ \
	&& wget https://jmeter-plugins.org/downloads/file/JMeterPlugins-ExtrasLibs-1.4.0.zip \
	&& unzip -o JMeterPlugins-ExtrasLibs-1.4.0.zip -d /jmeter/apache-jmeter-3.1/



# Set Jmeter Home
ENV JMETER_HOME /jmeter/apache-jmeter-3.1/

# Add Jmeter to the Path
ENV PATH $JMETER_HOME/bin:$PATH

#ADD run $JMETER_HOME/bin/jmeter.sh

RUN chmod +x $JMETER_HOME/bin/jmeter.sh

RUN apt-get update && \
    apt-get install -y xorg openbox xauth
# Replace 1000 with your user / group id
RUN export uid=502 gid=502 && \
    mkdir -p /home/ankitbhalla && \
    echo "ankitbhalla:x:${uid}:${gid}:Developer,,,:/home/ankitbhalla:/bin/bash" >> /etc/passwd && \
    echo "ankitbhalla:x:${uid}:" >> /etc/group && \
    echo "ankitbhalla ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/ankitbhalla && \
    chmod 0440 /etc/sudoers.d/ankitbhalla && \
    chown ${uid}:${gid} -R /home/ankitbhalla


USER ankitbhalla
ENV HOME /home/ankitbhalla
WORKDIR /home/ankitbhalla
CMD $JMETER_HOME/bin/jmeter.sh
