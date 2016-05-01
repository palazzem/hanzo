=====
Hanzō
=====

    | Hattori Hanzō: You must have big rats if you need Hattori Hanzo's steel.
    | The Bride: ...Huge.

This `Ansible`_ playbook configures a new ArchLinux installation with some development tools. The goal of the
playbook is to *inspire developers* that want to prepare programmatically their development machine. Obviously,
this repository fits my current needs and it's unlikely that fits others requirements; for this reason feel free
to provision a virtual machine, but be aware that you should forge your own playbook using this one only as a base.

.. _Ansible: https://www.ansible.com/

Quick start guide
-----------------

If you like living on the bleeding edge and *curlbombs* don't scare you, the automatic installer is the easiest
way to configure your system::

    $ sh <(curl -L http://j.mp/hattori-hanzo)

A clean ArchLinux installation is recommended but not required. Anyway, **bear in mind** that this configuration
**will overwrite the system**.

You can split the above command using an MD5 hash check::

    $ curl -L http://j.mp/hattori-hanzo -o hanzo.sh
    $ echo adc74b3af2deddac5e8d1c91b7c2a167  hanzo.sh | md5sum -c -

    # outputs:
    # hanzo.sh: OK

Manual installation
-------------------

If you prefer a manual installation because you don't like *curlbombs* (and you shouldn't), you have to install ``ansible`` and
``git`` packages using the ArchLinux default package manager (``pacman``). Simply, launch::

    $ pacman -S ansible git base base-devel --noconfirm

Starting the orchestration
~~~~~~~~~~~~~~~~~~~~~~~~~~

Clone this repository and start the orchestration with::

    $ git clone https://github.com/palazzem/hanzo.git
    $ ansible-playbook orchestrate.yml -i inventory --connection=local -e "fullname='<name>' username='<name>' email='<email>'"

The command above, requires the following parameters:

* ``fullname`` is used inside the ``.gitconfig.j2`` template
* ``email`` is used inside the ``.gitconfig.j2`` template
* ``username`` is the created username

**NOTE:** These parameters are mandatory and if you don't provide any value, the Ansible playbook will not proceed with
the provisioning.

Testing the provisioning
------------------------

If you want to apply the playbook changes without touching your current configuration, a ``Vagrantfile``
is available in the repository. It uses the ``ogarcia/archlinux-x64`` box and provisions the running instance
with this Ansible playbook. To launch the test, simply::

    $ vagrant up

At the ``SUDO password`` prompt, answer ``vagrant``. You may use this box even for testing some changes on the playbook.
To repeat the provisioning, just::

    $ vagrant provision

Ansible roles
-------------

The playbook will go through the following roles:

* ``system``
* ``shell``
* ``development``
* ``editors``
* ``postgresql``
* ``redis``
* ``vm``
* ``provisioning``
* ``cluster``
* ``bspwm``
* ``fonts``
* ``extras``
* ``dotfiles``

When the orchestration is completed, remember to set the user password through::

    $ passwd <username>

Then you can reboot the system.

Other tools
-----------

The Ansible playbook doesn't provide any extra tool or applications like IDEs, browsers, or Android SDK/NDK that I use
regularly. Even if it's possible to orchestrate manual installations (for instance: wget the archive, untar, create
applications shortcuts), I prefer to use the AUR repositories that take care of everything. Anyway, it's never a good
idea installing packages from AUR repositories without looking at the ``PKGBUILD`` file, so I leave the last setup
to the snippet below::

    # add Infinality Bundle key with key fingerprint
    # A924 4FB5 E93F 11F0 E975 337F AE68 66C7 962D DE58
    $ pacman-key -r 962DDE58
    $ pacman-key -f 962DDE58
    $ pacman-key --lsign-key 962DDE58
    $ pacman -Sy

    # window manager (required)
    $ yaourt -S xdo-git lemonbar-xft-git sutils-git

    # generic stuff
    $ yaourt -S downgrade
    $ yaourt -S mbpfan-git # (optional for Macbook laptops)

    # browsers
    $ yaourt -S firefox-developer google-chrome

    # terminal
    $ yaourt -S rxvt-unicode-256xresources urxvt-perls urxvt-resize-font-git urxvt-vtwheel

    # fonts
    $ yaourt -S ttf-ms-fonts ttf-font-awesome infinality-bundle
    $ fc-cache -fr

    # audio manager
    $ yaourt -S mopidy-spotify

    # Android
    $ yaourt -S gradle android-sdk android-sdk-platform-tools android-sdk-build-tools android-platform
    $ yaourt -S --tmp ~/ android-ndk

    # Google Cloud SDK
    $ gcloud init
    $ gcloud components install kubectl

**NOTES:**

* ``ttf-ms-fonts`` is used to solve some rendering problems related to window manager
* ``infinality-bundle`` requires adding a new key to Pacman KEYRING. you can find further information in the
  `Infinality official page`_
* ``mbpfan-git`` could be useful only if you install this system in a Macbook notebook
* the ``android-sdk`` package places the Android SDK in ``/opt/android-sdk`` so only the ``root`` user can add
  new SDK platforms. Bear in mind that you can follow these `recommendations`_ to properly configure your SDK
  folder. Furthermore, the ``android-ndk`` installation requires a lot of ``/tmp`` free space and if your
  configuration doesn't fulfill this requirement, you may provide the ``--tmp`` option and build the NDK in
  your home folder.

.. _Infinality official page: https://wiki.archlinux.org/index.php/Infinality#Infinality-bundle
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

This playbook provisions a machine with my current configuration. Because it's unlikely that you use exactly my
current environment, you may use this repository as a base to forge your own configuration. Indeed, I'll be glad
to accept any Pull Request that:

* fixes the current playbook execution
* improves the playbook styles or Ansible best practices
* enhances or makes me aware of different methods to distribute the playbook
* improves the ``README`` and the written English

I will not accept any Pull Request that adds new development tools, but I will be grateful if you can discuss
about it in the `issues tracker`_.

.. _issues tracker: https://github.com/palazzem/hanzo/issues
