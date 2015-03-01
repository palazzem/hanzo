=============
Ansible devel
=============

This is an Ansible playbook that configures a newly ArchLinux installation with many development tools.
Even if I used this configuration for my system, I want to port this playbook to other Linux distributions
like Ubuntu, Fedora and Debian so it can be as generic as possible. **Feel free to help**!

Installation
------------

Ansible is available using the default OS package manager (``pacman``). ``git`` is also required to download
this repository and you can install both dependencies simply:

.. code-block:: bash

	$ pacman -S ansible git

Getting started
---------------

First, clone this repository then start the orchestration:

.. code-block:: bash

	$ git clone https://github.com/palazzem/ansible-devel.git
	$ ansible-playbook orchestrate.yml -i inventory --connection=local -e username=<your_name>

The ``username`` variable is used to create your default user.

Ansible will go through the following roles:

* system
* shell
* containers
* postgresql
* redis
* development
* extras
* editors

Last commands
-------------

Because some extra tools are required but are only available in AUR repositories, the following
commands should be launched manually:

.. code-block:: bash

        $ yaourt -S firefox-developer
        $ yaourt -S google-chrome
        $ yaourt -S vim-youcompleteme-git
        $ yaourt -S android-sdk android-sdk-platform-tools android-sdk-build-tools android-platform android-ndk

**NOTE:** the last command will install Android SDK in ``/opt/android-sdk`` so only the ``root`` user can add
new SDK platforms. Bear in mind that you can follow these `reccomendation`_ to properly configure your SDK
folder.

.. _reccomendation: https://wiki.archlinux.org/index.php/android#Android_development

Missing features
----------------

The following are the missing features I need to work on:

* provide a good ``.zshrc``
* provide a good ``.vimrc`` so ``VIM`` can be used as a default code editor
* provide an ``awesome`` template
* provide a default ``.xinitrc`` so ``awesome`` will start automatically after login

Contribute
----------

Just fork this repository and make pull requests to support other platforms or development tools.
