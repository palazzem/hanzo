Vagrant.configure(2) do |config|
    # ArchLinux image
    config.vm.box = "terrywang/archlinux"

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
