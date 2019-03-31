=====
Hanzō
=====

    | Hattori Hanzō: You must have big rats if you need Hattori Hanzo's steel.
    | The Bride: ...Huge.

.. image:: https://circleci.com/gh/palazzem/hanzo/tree/master.svg?style=svg
    :target: https://circleci.com/gh/palazzem/hanzo/tree/master

This `Ansible`_ playbook configures a new ArchLinux installation with some development tools. The goal of the
playbook is *inspiring developers* to prepare programmatically their development environment. This repository targets
my requirements and it's very unlikely it can be used in a general purpose sense.

.. _Ansible: https://www.ansible.com/

Quickstart
----------

If you like living on the bleeding edge and *curlbombs* don't scare you, the automatic installer is the easiest
way to configure your system::

    $ sh <(curl -L http://j.mp/hattori-hanzo)

A clean ArchLinux installation is recommended but not required. Anyway, bear in mind it **WILL OVERWRITE ENTIRELY**
your system.

If you use this approach, nothing else is required and you can enjoy your new system!

ChromeOS Installer
~~~~~~~~~~~~~~~~~~

If you're not using a ChromeOS device, you can skip this section.
ChromeOS installer will replace the default LXC container with a new ArchLinux container configured with Hanzo. If
you're using actively the default ChromeOS container, bear in mind it **WILL BE REMOVED** from your system

To start the configuration, follow these steps:

* Enable Linux support on your ChromeOS system
* Open ``crosh`` using ``CTRL`` + ``ALT`` + ``T``
* Access the ``termina`` VM and launch the ChromeOS installer::

   $ vsh termina
   $ sh <(curl -L http:/j.mp/hattori-hanzo-chromeos)

* Hanzo is launched automatically and nothing else is required. Enjoy your new system!

**NOTE**: Your Google account username MUST be your Gmail account (without ``@gmail.com``) otherwise the integration will not work.

Manual installation
-------------------

To use this playbook the following requirements must be installed::

   $ pacman -Syy
   $ pacman -S sudo git ansible --noconfirm
   $ mkdir -p /usr/share/ansible/plugins/modules

   # Enables AUR Ansible module
   $ git clone https://github.com/kewlfft/ansible-aur.git /usr/share/ansible/plugins/modules/aur

Starting the orchestration
~~~~~~~~~~~~~~~~~~~~~~~~~~

Clone this repository and start the orchestration with::

   # Mandatory Environment Variables
   $ export HANZO_FULLNAME test
   $ export HANZO_USERNAME test
   $ export HANZO_EMAIL test@example.com
   $ export HANZO_SSH_PASSWORD som3th!ng

   # Starts the provisioning
   $ git clone https://github.com/palazzem/hanzo.git
   $ ansible-playbook orchestrate.yml --connection=local

The command above, requires the following parameters:

* ``HANZO_FULLNAME`` is used inside the ``.gitconfig.j2`` template
* ``HANZO_EMAIL`` is used inside the ``.gitconfig.j2`` template
* ``HANZO_USERNAME`` is the created username
* ``HANZO_SSH_PASSWORD`` is used to encrypt your newly generated SSH private key

**NOTE:** These parameters are mandatory and if you don't provide any value, Ansible aborts the provisioning.

Testing
-------

If you want to apply the playbook changes without touching your current configuration, or you want to test any
change of the current configuration, a ``Dockerfile`` is available to build an ArchLinux container. To start the
provisioning, just::

   $ docker build . -t hanzo:latest && docker run -ti --rm hanzo:latest

Contribute
----------

The playbook provisions a machine with my current configuration. Because it's unlikely that you use exactly my
current environment, you may use this repository as a base to create your own configuration. Indeed, I'll be glad
to accept any PR that:

* Fixes the current playbook execution
* Improves the playbook styles or Ansible best practices
* Enhances or makes me aware of different methods to distribute the playbook

I will not accept any PR that adds new development tools, but I will be grateful if you can discuss about it in
the `issues tracker`_.

.. _issues tracker: https://github.com/palazzem/hanzo/issues
