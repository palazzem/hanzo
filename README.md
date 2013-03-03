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

	$ pacman -Sy yaourt
	$ yaourt -S ansible-git
	
Now run Ansible orchestration and relax while she does the pleasure:
	
	$ ansible-playbook archlinux-dev.yml --connection=local

What is included
================