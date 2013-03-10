Ansible developer machine
=========================
This is an Ansible playbook that aims to configure a newly Linux installation with all useful developer tools.
Even if I used this configuration for my Arch Linux system, I want to port this playbook to other Linux distribution like Fedora, Debian, Ubuntu so it can be as generic as possible. Feel free to help!

Getting started
===============
To use this playbook you must have Ansible correctly installed. I prefer to use the one available in AUR repository. First install Yaourt on your Arch Linux system adding to your `/etc/pacman.conf`:

	# Yaourt repository
	[archlinuxfr]
	Server = http://repo.archlinux.fr/x86_64

Then you are able to install Yaourt and Ansible:

	$ pacman -Sy yaourt sudo
	$ yaourt -S ansible-git
	
Before starting the whole installation, umount /tmp partition because Arch Linux uses a small temporary tmpfs (about 500Mb) and this is insufficient for all compilation and downloads that should be done. Do:
	
	$ umount /tmp

Now you are able to start this Ansible orchestration:
	
	$ ansible-playbook archlinux-dev.yml -i inventory --connection=local

Note
====
Relax while she does the pleasure!

What is included
================