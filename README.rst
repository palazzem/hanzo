=============
Ansible devel
=============

This is an Ansible playbook that configures a newly ArchLinux installation with some development tools.

Installation
------------

Ansible is available using the default OS package manager (``pacman``). ``git`` is also required to download
this repository and you can install both dependencies simply:

.. code-block:: bash

	$ pacman -S ansible git

Getting started
---------------

First, clone this repository and then start the orchestration:

.. code-block:: bash

	$ git clone https://github.com/palazzem/ansible-devel.git
	$ ansible-playbook orchestrate.yml -i inventory --connection=local -e "username=<name> desktop=<desktop_environment>"

The command above, requires the following parameters list:

* ``username`` is the name of created user
* ``desktop`` is the name of the desktop environment or window manager. Examples are: ``awesome``, ``gnome``, ``lxde``, etc.
  You can find more information in the ArchLinux `Desktop Environment`_ documentation.

.. _Desktop Environment: https://wiki.archlinux.org/index.php/Desktop_environment

**NOTE:** This parameters are mandatory and if you don't provide any value, the Ansible script will not proceed with
the orchestration.

Script roles
~~~~~~~~~~~~

The Ansible script will go through the following roles:

* system
* shell
* containers
* postgresql
* redis
* development
* extras
* editors

After the local orchestration is completed, remember to set the password for your user:

.. code-block:: bash

        $ passwd <name>

Then you can reboot the system.

Other tools
-----------

The Ansible script doesn't provide any extra tools and applications like IDEs, browsers, or Android SDK/NDK that I use
regularly. Even if it's possible to orchestrate manual installations (for instance: wget the archive, untar, create
applications shortcuts), I prefer to use the AUR repositories that take care of everything. Anyhow, it's never a good
idea to install packages from AUR repositories without looking at the PKGBUILD file, so I leave these manual installations
to the snippet below:

.. code-block:: bash

        $ yaourt -S firefox-developer
        $ yaourt -S google-chrome
        $ yaourt -S vim-youcompleteme-git
        $ yaourt -S android-sdk android-sdk-platform-tools android-sdk-build-tools android-platform android-ndk

**NOTE:** the last command will install Android SDK in ``/opt/android-sdk`` so only the ``root`` user can add
new SDK platforms. Bear in mind that you can follow these `reccomendation`_ to properly configure your SDK
folder.

.. _reccomendation: https://wiki.archlinux.org/index.php/android#Android_development

Roadmap
-------

The following are some missing features:

* provide a good ``.zshrc``
* provide a good ``.vimrc`` so ``VIM`` can be used as a default code editor
* provide an ``awesome`` template (I use Awesome as a window manager)
* provide a default ``.xinitrc``

Contribute
----------

Just fork this repository and make pull requests to support other platforms or development tools.
