#! /bin/sh

ocObsRepo=http://download.opensuse.org/repositories/isv:ownCloud:community:testing/xUbuntu_14.04
ocPackage=$(echo $ocObsRepo | sed -e 's@:\([^/]\)@:/\1@')
releaseKey=$ocObsRepo/Release.key
ocVersion=Owncloud8.0.0-6
imageVersion=xUbuntu14.04
vmBoxName=ubuntu/trusty64
vmBoxUrl=https://vagrantcloud.com/ubuntu/boxes/trusty64/versions/14.04/providers/virtualbox.box


cat > Vagrantfile << EOF
\$script = <<SCRIPT
set -x
echo "admin\nadmin" | sudo passwd
wget $releaseKey
sudo apt-key add - < Release.key 
rm Release.key
sudo sh -c "echo 'deb $ocPackage /' >> /etc/apt/sources.list.d/owncloud.list"
sudo apt-get update -y
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password admin'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password admin'
sudo apt-get install -y owncloud
sudo mkdir /var/scripts
cd /var/www/owncloud/apps
sudo chown -c www-data .
SCRIPT

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
 # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "$vmBoxName"

  # The url from where the 'config.vm.box' box will be fetched if it
  # doesn't already exist on the user's system.
  config.vm.box_url = "$vmBoxUrl"

  config.vm.network :forwarded_port, guest: 80, host: 8888
  config.vm.provider :virtualbox do |vb|
      vb.name = "$imageVersion+$ocVersion"
  end
	config.vm.provision "shell",
	inline: \$script
	config.vm.provision "shell", path: https://raw.githubusercontent.com/owncloud/vm/master/enoch85-testing/welcome.sh
end
EOF
vagrant up
vagrant halt
imagePath=$(VBoxManage list hdds | grep /$imageVersion+$ocVersion/)
#-->Location:       /home/stefan/VirtualBox VMs/xUbuntu14.04/box-disk1.vmdk
imagePath=${imagePath#*/}
imageName=${imagePath##*/}
imagePath=/$imagePath
#/home/stefan/VirtualBox VMs/xUbuntu14.04/box-disk1.vmdk
cp "$imagePath" .
zip $imageVersion+$ocVersion.vmdk.zip $imageName
rm $imageName

if [ "$imagePath" != "" ]
then vagrant destroy -f
fi
