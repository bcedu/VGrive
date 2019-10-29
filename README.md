# VGrive

VGrive is a client (back-end and front-end) for Google Drive made in vala.

<ul>
<li>Start VGrive and sync your files with Google Drive through a clean and minimalist gui.</li>
<li>Automaticlly detects changes in local and remote files and sync them.</li>
<li>Choose the local path where VGrive syncs your files.</li>
</ul>

<p float="left">
  <img src="/data/imgs/init.png" width="49%" />
  <img src="/data/imgs/login.png" width="49%" />
</p>
<p float="left">
  <img src="/data/imgs/sync.png" width="49%" />
  <img src="/data/imgs/conf.png" width="49%" />
</p>

## Installation

### Elementary AppCenter

Install VGrive through the elementary AppCenter. It's always updated to lastest version.
Easy and fast.

<p align="center">
  <a href="https://appcenter.elementary.io/com.github.bcedu.vgrive"><img src="https://appcenter.elementary.io/badge.svg" alt="Get it on AppCenter" /></a>
</p>

### Debiand and Debian and Derivatives: Install from .deb file 

For debian based distributions (ubuntu, linux mint, elementary, ...) you can install VGrive directlly with the .deb file attached to the newest release of VGrive. 

### Manual Instalation

Download last release (zip file), extract files and enter to the folder where they where extracted.

Install the 'build' pre-requisites ( eg on ubuntu, something like this ):
- sudo apt install meson
- sudo apt install valac
- sudo apt-get install build-essential libgtk-3-dev
- sudo apt install libgranite*
- sudo apt install libjson-glib*
- sudo apt install libsoup*
- sudo apt install libunity-dev

Install your application with the following commands:
- meson build --prefix=/usr
- cd build
- ninja
- sudo ninja install

DO NOT DELETE FILES AFTER MANUAL INSTALLATION, THEY ARE NEEDED DURING UNINSTALL PROCESS

To uninstall type from de build folder:
- sudo ninja uninstall

