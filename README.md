Mini Firmware for Freifunk Ulm
==============================

The firmware turns a common wireless router into a mesh networking device.
It connects to similar routers in the area and builds a Wifi-mesh network.
For the Mini Firmware 4mb flash and 16mb memory required.

Note: The Mini Firmware extends only the Wifi-mesh network. There is no web interface, no client access point function and no connection to the internet over the wan interface. 

To build the firmware you need a Unix console to enter commands into.
Install dependencies for the build environment (Debian/Ubuntu):

    sudo apt-get install subversion g++ zlib1g-dev build-essential
    sudo apt-get install git libncurses5-dev gawk gettext unzip file

Build commands for the console:

    git clone git://git.openwrt.org/14.07/openwrt.git
    cd openwrt
    
    ./scripts/feeds update -a
    ./scripts/feeds install -a
    
    git clone -b mini https://github.com/ffulm/firmware.git
    cp -rf firmware/files firmware/package .
    git am --whitespace=nowarn firmware/patches/openwrt/*.patch
    cd feeds/routing && git am --whitespace=nowarn ../../firmware/patches/routing/*.patch && cd -
    rm -rf firmware tmp
    
    make defconfig
    make menuconfig

Now select the right "Target System" and "Target Profile" for your AP model:

For example, for the Linksys WRT54GS v1.1, select:
* `Target System => Broadcom BCM47xx/53xx (MIPS)`
* `Target Profile => Legacy`

For other models you can lookup the "Target System" in the OpenWrt
[hardware table](http://wiki.openwrt.org/toh/start). Your AP model
should now be visible in the "Target Profile" list.

Now start the build process. This takes some time:

    make

The firmware images are now in the `bin`-folder. Use the firmware update
functionality of your router and upload the factory image. The sysupgrade
images are for further updates.

* Use `openwrt-[chip]-[model]-squashfs-factory.bin` for the initial flash.
* Use `openwrt-[chip]-[model]-squashfs-sysupgrade.bin` for futher updates.

Note: After the firmware upload wait about 10 minutes. The router reboots multible times and the firmware configuration takes a long time.

The router configuration can be done in the file /etc/config/freifunk. Insert or change the following options:

    option name 'Name of the router'
    option contact 'Your eMail Adresse'
    option geo 'Enter your cordinated her'

Many routers have not been tested yet, but may work.
Give it a try! :-)
