Ansible developer machine
=========================
This is an Ansible playbook that aims to configure a newly Linux installation with all useful developer tools.
Even if I used this configuration on my Arch Linux system, I want to port this playbook to other Linux distribution like Fedora, Debian, Ubuntu. Feel free to help!

Getting started
===============
To use this playbook you must have Ansible correctly installed. I prefer to use the one available via pip install. First install it on your Arch Linux system then :

	$ pacman -S python2-pip
	$ pip2 install ansible

Now run Ansible orchestration and relax while she does the pleasure:
	
	$ ansible-playbook archlinux-dev.yml --connection=local

What is included
================