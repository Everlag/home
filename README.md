DEPRECATED: succeeded by the appropriately named [home2](https://github.com/Everlag/home2) which uses salt instead

# home

Top level directory is portable dotfiles.

`workspace/` contains a Vagrantfile which will build an i3
based workspace. For detailed configuration information, see [workspace/Vagrantfile](./workspace/VagrantFile)

1. Install dependendencies [virtualbox](https://www.virtualbox.org/) and [vagrant](https://www.vagrantup.com/)
1. `vagrant up`  and wait

---

Depending on what version of virtualbox you're using, you may have to manually install guest additions:

1. Attach an optical drive through the VirtualBox GUI
1. Insert the guest additions cd through the VirtualBox GUI
1. `sudo mount /dev/cdrom /media/cdrom`
1. `sudo /media/cdrom/VBoxLinuxAdditions.run` and say 'yes' if required.

This is the first step if your workspace is not properly resizing in response to the host window.

---

The workspace should look something like this on first-boot

![Workspace 1](images/ws1.jpg)
![Workspace 2](images/ws2.jpg)
![Workspace 3](images/ws3.jpg)
