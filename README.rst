=====
Hanzō
=====

    | Hattori Hanzō: You must have big rats if you need Hattori Hanzo's steel.
    | The Bride: ...Huge.

.. image:: https://github.com/palazzem/hanzo/workflows/test/badge.svg
    :target: https://github.com/palazzem/hanzo/actions?query=workflow%3Atest
.. image:: https://github.com/palazzem/hanzo/workflows/release/badge.svg
    :target: https://github.com/palazzem/hanzo/actions?query=workflow%3Arelease

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

Manual Installation
-------------------

In case you don't want to use the `curl` command above, you can clone or download this
repository, using either `git` or the [release page](https://github.com/palazzem/hanzo/releases).
After the checkout, run the following commands::

    $ cd hanzo/
    $ HANZO_FOLDER=$(pwd) bash bin/bootstrap.sh

Unattended Installer
~~~~~~~~~~~~~~~~~~~~

If you don't want to use the interactive shell to configure Hanzo, you can set the
following environment variables:

* ``HANZO_FOLDER``: if specified, that folder is used as Hanzo root. If not specified, the
  bootstrap script fetches Hanzo from GitHub.
* ``HANZO_FULLNAME``: your full name used in the ``.gitconfig``.
* ``HANZO_EMAIL``: your email address used in the ``.gitconfig``.
* ``HANZO_USERNAME``: username used to create the main user.
* ``TAGS``: sets Ansible tags. Available options are ``[chromeos]``. If not tags are set,
  a standard Archlinux toolbox is configured.
* ``EXTRA_ARGS``: sets Ansible extra arguments. Use this variable if you want to set options
  such as ``--verbose`` or ``--check``.

Testing
-------

If you want to apply the playbook changes without touching your current configuration, or you want to test any
change of the current configuration, a ``Dockerfile`` is available to build an ArchLinux container. To start the
provisioning, just::

   $ docker build . -t hanzo:test \
       --build-arg HANZO_FULLNAME=test \
       --build-arg HANZO_USERNAME=test \
       --build-arg HANZO_EMAIL=test@example.com && \
       docker rmi hanzo:test

Contribute
----------

The playbook provisions a machine with my current configuration. Because it's unlikely that you use exactly my
current environment, you may use this repository as a base to create your own configuration. Indeed, I'll be glad
to accept any PR that:

* Fixes the current playbook execution
* Improves the playbook styles or Ansible best practices
* Enhances or makes me aware of different methods to distribute the playbook

I will not accept any PR that adds new development tools, but I will be grateful if you can discuss about it in
the `issue tracker`_.

.. _issue tracker: https://github.com/palazzem/hanzo/issues
