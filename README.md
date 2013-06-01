Ansible developer machine
=========================
This is an Ansible playbook that aims to configure a newly Ubuntu installation with many development tools.
Even if I used this configuration for my Ubuntu system, I want to port this playbook to other Linux distributions like Arch Linux, Fedora and Debian so it can be as generic as possible. **Feel free to help**!

Ansible installation
====================

As I'm a python software developer, I use `pip` to install Ansible with all requirements:

	$ sudo apt-get install git python-pip python-dev -y
	$ sudo pip install virtualenvwrapper
	$ source virtualenvwrapper.sh
	$ mkvirtualenv ansible
	$ pip install ansible

After you finish all orchestration, you can delete ansible virtualenv.

Starting orchestration
======================

First, clone this repository then start with orchestration:

	$ git clone git@github.com:emanuele-palazzetti/ansible-devel.git
	$ ansible-playbook devel-machine.yml -i inventory --connection=local -K

**However**, if you want to select only some developer tools, you can select them with this command:

	$ ansible-playbook devel-machine.yml -i inventory --connection=local -K --tags "`<some packages>`"

These are the available packages:

* system
* virtualization
* browser
* development
* ide
* extra-development
* postgresql
* extras

Example
=======

This command:

	$ ansible-playbook archlinux-dev.yml -i inventory --connection=local --tags "development,ide"

will only install `development` and `ide` package.

Contribute
==========

Just fork this repository and make pull requests to support other platforms / development tools!