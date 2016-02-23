=====
Hanzō
=====

    Hattori Hanzō: You must have big rats if you need Hattori Hanzo's steel. 
    The Bride: ...Huge. 

Quick start guide
-----------------

This is an `Ansible`_ playbook that configures a new ArchLinux installation with some development tools.
The easiest way to configure your system with this Ansible script, is to launch the automatic installer::

    $ sh <(curl -L http://j.mp/arch-ansible)

A clean ArchLinux installation is recommended but not required. Anyway, **bear in mind** that this configuration
**will overwrite** your settings.

.. _Ansible: https://www.ansible.com/

Manual installation
-------------------

If you prefer a manual installation because you don't trust *hidden* scripts (and you shouldn't), you have to install
``ansible`` and ``git`` packages using the ArchLinux default package manager (``pacman``). Simply, launch::

	$ pacman -S ansible git

Starting the orchestration
~~~~~~~~~~~~~~~~~~~~~~~~~~

Clone this repository and start the orchestration with::

	$ git clone https://github.com/palazzem/ansible-devel.git
	$ ansible-playbook orchestrate.yml -i inventory --connection=local -e "fullname=<name> email=<email> username=<name>"

The command above, requires the following parameters:

* ``fullname`` is used inside the ``.gitconfig.j2`` template
* ``email`` is used inside the ``.gitconfig.j2`` template
* ``username`` is the name for the created user

**NOTE:** These parameters are mandatory and if you don't provide any value, the Ansible script will not proceed with
the orchestration.

Ansible roles
-------------

The main script will go through the following roles:

* ``system``
* ``shell``
* ``provisioning``
* ``postgresql``
* ``redis``
* ``development``
* ``extras``
* ``editors``
* ``awesome``
* ``dotfiles``

When the orchestration is completed, remember to set the user password through::

    $ passwd <name>

Then you can reboot your system.

Other tools
-----------

The Ansible script doesn't provide any extra tool or applications like IDEs, browsers, or Android SDK/NDK that I use
regularly. Even if it's possible to orchestrate manual installations (for instance: wget the archive, untar, create
applications shortcuts), I prefer to use the AUR repositories that take care of everything. Anyway, it's never a good
idea to install packages from AUR repositories without looking at the ``PKGBUILD`` file, so I leave the installation
to the snippet below::

    $ yaourt -S archey3
    $ yaourt -S firefox-developer google-chrome
    $ yaourt -S awesome-themes-git
    $ yaourt -S downgrade
    $ yaourt -S ttf-ms-fonts
    $ yaourt -S watchman
    $ yaourt -S gradle android-sdk android-sdk-platform-tools android-sdk-build-tools android-platform
    $ yaourt -S --tmp ~/ android-ndk
    $ yaourt -S mbpfan-git # (optional for Macbook laptops)
    $ yaourt -S blueman

**NOTES:**

* ``ttf-ms-fonts`` is used to solve some rendering problems related to ``awesome`` window manager
* ``mbpfan-git`` could be useful only if you install this system in a Macbook notebook
* the ``android-sdk`` package places the Android SDK in ``/opt/android-sdk`` so only the ``root`` user can add
  new SDK platforms. Bear in mind that you can follow these `recommendations`_ to properly configure your SDK
  folder. Furthermore, the ``android-ndk`` installation requires a lot of ``/tmp`` free space and if your
  configuration doesn't fulfill this requirement, you may provide the ``--tmp`` option and build the NDK in
  your home folder.

.. _recommendations: https://wiki.archlinux.org/index.php/android#Android_development

What to do next
---------------

You can follow these advices after the orchestration is finished:

* use ``powertop`` program to activate all required ``Tunables``, fixing eventual battery problems

Known issues
------------

* ``wicd-curses`` crashes with a python exception. To solve this problem, simply use ``downgrade`` to install
  ``wicd`` version 1.7.2

Contribute
----------

Just fork this repository and make pull requests to support other platforms or development tools.
