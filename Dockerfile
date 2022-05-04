FROM debian:jessie

RUN apt-get update \
&& apt-get install -y \
  sudo \
  whois \
  usbutils \
  build-essential \
  tix \
  foomatic-filters \
  groff \
  dc \
  vim
RUN apt-get install -y cups samba
RUN apt-get clean \
&& rm -rf /var/lib/apt/lists/*

COPY foo2zjs /root/foo2zjs

WORKDIR /root/foo2zjs
RUN make
RUN make install install-hotplug cups

# Add user and disable sudo password checking
RUN useradd \
  --groups=sudo,lp,lpadmin \
  --create-home \
  --home-dir=/home/print \
  --shell=/bin/bash \
  --password=$(mkpasswd print) \
  print \
&& sed -i '/%sudo[[:space:]]/ s/ALL[[:space:]]*$/NOPASSWD:ALL/' /etc/sudoers

# Copy the default configuration file
COPY --chown=root:lp cupsd.conf /etc/cups/cupsd.conf
RUN echo 'root:sometemppassword' | chpasswd

WORKDIR /root/

# Default shell
CMD ["/usr/sbin/cupsd", "-f"]
