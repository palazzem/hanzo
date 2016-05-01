# inline script that fulfills the requirement of python
# and allows vagrant user to execute sudo commands without
# a password
$script = <<SCRIPT
pacman -Sy
pacman -S python2 python3 git --noconfirm
sudo grep -q '^%vagrant' /etc/sudoers || sudo echo "%vagrant ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
SCRIPT

Vagrant.configure(2) do |config|
    # ArchLinux image
    config.vm.box = "ogarcia/archlinux-x64"

    # shell provisioning
    config.vm.provision "shell", inline: $script

    # Ansible provisioning
    config.vm.provision :ansible do |ansible|
        ansible.playbook = "orchestrate.yml"
        ansible.ask_sudo_pass = true
        ansible.host_vars = {
            "default" => {"ansible_python_interpreter": "/usr/bin/python2"}
        }
        ansible.extra_vars = {
            fullname: "Hattori Hanzo",
            username: "hanzo",
            email: "noone@nowhere.com"
        }
    end
end
