## Running a CUPS Print Server on Synology NAS for Old USB HP P1006 Laser Printer Using Docker
So I have this old USB only printer at home that I use every once in a blue moon. I used to have a Raspberry Pi hooked up to it that served as a print server and the same Pi had OctoPrint running on it for my 3d printer as well. But the Pi's WiFi was on the verge of failing and would frequently drop its network connection so I figured I'd connect the printer to my Synology NAS and let it manage my laser printer instead. Sounds simple enough right?

It would've been awesome if it was plug-and-play but of course these things are never as straightforward as they should be. As it turns out, the Synology NAS only supports a select few printers out of the box and the only way that I can think of to get my printer to work with it is to pretty much duplicate the CUPS setup I had with the Raspberry Pi but with a docker container (and for x86 arch instead of ARM, of course). 

The same thing has been done for a [different printer](http://www.theghostbit.com/2016/10/setting-up-cups-server-with-docker-on.html), and an older version of the DSM. As of this writing, I am running DSM 7.0.1. So parts of that guide don't really apply anymore.


## Dockerfile

Writing the dockerfile itself was very straightforward. I started with Debian Jessie as the base, and installed some basic utilities and build-essentials to build the driver from source. The P1006 is one of those annoying printers that require a firmware to be loaded on power up and that's the reason installing the god damned driver is so much more complicated than it needs to be. Details on the installation steps for the foo2zjs driver can be found [here](https://github.com/koenkooi/foo2zjs). The steps can vary depending on the distro it's to be installed on. Again, much more complicated than it needs to be. 
Finally Add the user, set a password, run the CUPS daemon, easy peasy. 

```console
docker build . -t leokuan/p1006cups
docker push leokuan/p1006cups
```

Synology DSM runs cupsd under the hood for its print service. To run the docker image, first check to see if cupsd is running, if so, use synosystemctl stop cupsd to terminate it (synoservice is deprecated). Don't try to kill the process by ID as it will just respawn. 
You could also write a start-up script to automate the process. But I only needed to print a few pages at home so there wasn't much of a reason to bother.

```console
sudo netstat -pna | grep 631
sudo synosystemctl stop cupsd
sudo docker run -d -p 631:631 -p 5353:5353 --privileged -t -i --name p1006cups --device=/dev/bus/usb/001/001 leokuan/p1006cups:latest
```

Of particular note, DSM now comes with `lsusb`, but it's a strange Python implementation of `lsusb` that doesn't really tell you the device numbers of your connected devices. 

```console
$ lsusb
|__usb1          1d6b:0002:0404 09  2.00  480MBit/s 0mA 1IF  (Linux 4.4.180+ xhci-hcd xHCI Host Controller 0000:00:15.0) hub
  |__1-2         03f0:3e17:0100 00  2.00  480MBit/s 98mA 1IF  (Hewlett-Packard HP LaserJet P1006 AC2DFF6)
  |__1-4         f400:f400:0100 00  2.00  480MBit/s 200mA 1IF  (Synology DiskStation 7F00147B9D345A50)
|__usb2          1d6b:0003:0404 09  3.00 5000MBit/s 0mA 1IF  (Linux 4.4.180+ xhci-hcd xHCI Host Controller 0000:00:15.0) hub
  |__2-1         0bc2:ab34:0100 00  3.00 5000MBit/s 0mA 1IF  (Seagate Backup+  Desk NA7H3L4F)
```

Anyhow, I was able to pass the printer as `device=/dev/bus/usb/001/001` to the container and that did the trick.

The rest is no different than setting up CUPS normally. 

If you have more than a couple containers running on your NAS like I do, I recommend using portainer to manage them. 
