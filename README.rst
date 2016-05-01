=====
Hanzō
=====

    | Hattori Hanzō: You must have big rats if you need Hattori Hanzo's steel.
    | The Bride: ...Huge.

Quick start guide
-----------------

This is an `Ansible`_ playbook that configures a new ArchLinux installation with some development tools.
If you like living on the bleeding edge and *curlbombs* don't scare you, the automatic installer is the easiest
way to configure your system with this playbook::

    $ sh <(curl -L http://j.mp/hattori-hanzo)

A clean ArchLinux installation is recommended but not required. Anyway, **bear in mind** that this configuration
**will overwrite your system**.

You can split the above command using an MD5 hash check::

    $ curl -L http://j.mp/hattori-hanzo -o hanzo.sh
    $ echo 86b0cd98c20dbbdb285160145897840d  hanzo.sh | md5sum -c -

    # outputs:
    # hanzo.sh: OK

.. _Ansible: https://www.ansible.com/

Manual installation
-------------------

If you prefer a manual installation because you don't like *curlbombs* (and you shouldn't), you have to install ``ansible`` and
``git`` packages using the ArchLinux default package manager (``pacman``). Simply, launch::

    $ pacman -S ansible git base base-devel

Starting the orchestration
~~~~~~~~~~~~~~~~~~~~~~~~~~

Clone this repository and start the orchestration with::

    $ git clone https://github.com/palazzem/ansible-devel.git
    $ ansible-playbook orchestrate.yml -i inventory --connection=local -e "fullname=<name> username=<name> email=<email>"

The command above, requires the following parameters:

* ``fullname`` is used inside the ``.gitconfig.j2`` template
* ``email`` is used inside the ``.gitconfig.j2`` template
* ``username`` is the name for the created user

**NOTE:** These parameters are mandatory and if you don't provide any value, the Ansible playbook will not proceed with
the orchestration.

Testing the provisioning
------------------------

If you want to apply the playbook changes without touching your current configuration, a ``Vagrantfile``
is available in the repository. It uses the ``ogarcia/archlinux-x64`` box and provisions the running instance
with this Ansible playbook. To launch the test, simply::

    $ vagrant up

At the ``SUDO password`` prompt, answer ``vagrant``. You may use this box even for testing some changes on the playbook.

Ansible roles
-------------

The playbook will go through the following roles:

* ``system``
* ``shell``
* ``vm``
* ``provisioning``
* ``postgresql``
* ``redis``
* ``development``
* ``extras``
* ``editors``
* ``bspwm``
* ``fonts``
* ``dotfiles``

When the orchestration is completed, remember to set the user password through::

    $ passwd <username>

Then you can reboot your system.

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

Just fork this repository and make pull requests to support other platforms or development tools.
