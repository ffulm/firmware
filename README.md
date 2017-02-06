Firmware for Freifunk Bodensee
=========================

The firmware turns a common wireless router into a mesh networking device.
It connects to similar routers in the area and builds a Wifi-mesh network
but also opens an access point for computers to connect over Wifi.
Included is Internet connectivity and a web interface.

Please talk to us on IRC if anything does not work!

[Precompiled firmware images](https://vpn1.ffbsee.de/freifunk/firmware/ "Precompiled firmware images") are available on our server. All other released versions here on github are out-of-date.

To build the firmware yourself you need a Unix console to enter commands into.
Install dependencies for the build environment (Debian/Ubuntu):

```bash
    sudo apt-get update; sudo apt-get upgrade
    sudo apt-get install subversion g++ zlib1g-dev build-essential git python
    sudo apt-get install libncurses5-dev gawk gettext unzip file libssl-dev wget
```
Build commands for the console:

```bash
    git clone https://github.com/openwrt/openwrt.git
    cd openwrt
    git reset --hard 0f757bd2606971252f901ef3faf4dbd0086315f7
    
    ./scripts/feeds update -a
    ./scripts/feeds install -a
    
    git clone https://github.com/ffbsee/firmware.git
    cp -rf firmware/files firmware/package .
    chmod -R a+rX firmware/files/www
    git am --whitespace=nowarn firmware/patches/openwrt/*.patch
    cd feeds/routing && git am --whitespace=nowarn ../../firmware/patches/routing/*.patch && cd -
    cd feeds/packages && git am --whitespace=nowarn ../../firmware/patches/packages/*.patch && cd -
    rm -rf firmware tmp
    
    make defconfig
    make menuconfig
```
Now select the right "Target System" and "Target Profile" for your AP model:

For example, for the TL-WR841ND, select:
* `Target System => Atheros AR7xxx/AR9xxx`
* `Target Profile => TP-LINK TL-WR841ND`

Or in case you have the DIR-300, select:
* `Target System => <*> AR231x/AR5312`
* `Target Profile => <*> Default`

For other models you can lookup the "Target System" in the OpenWrt
[hardware table](http://wiki.openwrt.org/toh/start). Your AP model
should now be visible in the "Target Profile" list.

Now start the build process. This takes some time:

```bash
    make
```
*You have the opportunity to compile the firmware at more CPU threats to speed up the process.*
*e.g. to run 3 jobs (commands) simultaneously use the following option:* `make -j 3` 

The **firmware image files** will be stored in the `bin`-folder. These images can now directly be used to update your router. Please note, that two differnt image types (per router) will be provided:

* Use `openwrt-[chip]-[model]-squashfs-factory.bin` for the initial flash (for routers running stock/vendor firmware).
* Use `openwrt-[chip]-[model]-squashfs-sysupgrade.bin` for futher updates (for routers having already another Freifunk FW flashed).

**Many routers have not been tested yet, but may work.**
***Give it a try! :-) ...and tell us about your experiences***

To build all images for all supported models see [github.com/freifunk-bielefeld](https://github.com/freifunk-bielefeld/docs/blob/master/release_howto.md#images-bauen)
