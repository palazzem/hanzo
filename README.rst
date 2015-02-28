=============
Ansible devel
=============

This is an Ansible playbook that configures a newly ArchLinux installation with many development tools.
Even if I used this configuration for my system, I want to port this playbook to other Linux distributions
like Ubuntu, Fedora and Debian so it can be as generic as possible. **Feel free to help**!

Installation
------------

Ansible is available using the default OS package manager. Furthermore we need ``git`` VCS to download
this repository and ``ssh`` to let Ansible work properly. To install these dependencies, simply:

.. code-block:: bash

	$ pacman -S ansible git openssh

Getting started
---------------

First, clone this repository then start with orchestration:

.. code-block:: bash

	$ git clone https://github.com/palazzem/ansible-devel.git
	$ ansible-playbook devel-machine.yml -i inventory --connection=local -K

**However**, if you want to select only some developer tools, you can select them with this command:

.. code-block:: bash

	$ ansible-playbook devel-machine.yml -i inventory --connection=local -K --tags "``<some packages>``"

These are the available packages:

* system
* virtualization
* browser
* development
* ide
* extra-development
* postgresql
* extras

Usage example
-------------

This command:

.. code-block:: bash

	$ ansible-playbook archlinux-dev.yml -i inventory --connection=local --tags "development,ide"

will only install ``development`` and ``ide`` package.

Contribute
----------

Just fork this repository and make pull requests to support other platforms / development tools!
