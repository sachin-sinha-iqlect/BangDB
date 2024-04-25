#!/bin/bash
## find os type
osv=0
x=$(awk -F= '/^ID/{print $2;exit}' /etc/os-release)
if [ "$x" = '"centos"' ]; then
	echo "installing for centos"
	osv=1
elif [ "$x" = 'ubuntu' ]; then
	echo "installing for ubuntu"
	osv=2
elif [ "$x" = '"rhel"' ]; then
	echo "installing for red hat"
	osv=3
else
	echo "unkown os [ $x ] , quitting..."
	osv=0
	exit
fi

alias brc='source ~/.bashrc'

#### installing necessary packages and libs
if [ $osv -eq 2 ]
then
	sudo apt-get install -y build-essential

	lib=libopenssl
	v=$(ldconfig -p | grep $lib)
	if [ -z "$v" ]
	then
		echo "$lib is not installed, installing ... "
		sudo apt-get install -y $lib
	else
		echo "$lib is installed"
	fi
	lib=libcurl4-openssl-dev
	v=$(ldconfig -p | grep $lib)
	if [ -z "$v" ]
	then
		echo "$lib is not installed, installing ... "
		sudo apt-get install -y $lib
		sudo apt-get install -y libcurl
	else
		echo "$lib is installed"
	fi
	lib=sysstat
	v=$(ldconfig -p | grep $lib)
	if [ -z "$v" ]
	then
		echo "$lib is not installed, installing ... "
		sudo apt-get install -y $lib
	else
		echo "$lib is installed"
	fi
	lib=snmp
	v=$(ldconfig -p | grep $lib)
	if [ -z "$v" ]
	then
		echo "$lib is not installed, installing ... "
		sudo apt-get install -y $lib
	else
		echo "$lib is installed"
	fi
	lib=libreadline-dev
	v=$(ldconfig -p | grep $lib)
	if [ -z "$v" ]
	then
        	echo "$lib is not installed, installing ... "
	        sudo apt-get install -y $lib
	else
        	echo "$lib is installed"
	fi


#else for centos and rhel
else
	sudo yum -y group install 'Development Tools'
	sudo yum -y install curl-devel
	lib=openssl
	v=$(ldconfig -p | grep $lib)
	if [ -z "$v" ]
	then
		echo "$lib is not installed, installing ... "
		sudo yum -y install $lib
	else
		echo "$lib is installed"
	fi
	lib=curl
	v=$(ldconfig -p | grep $lib)
	if [ -z "$v" ]
	then
		echo "$lib is not installed, installing ... "
		sudo yum -y install $lib
	else
		echo "$lib is installed"
	fi
	lib=sysstat
	v=$(ldconfig -p | grep $lib)
	if [ -z "$v" ]
	then
		echo "$lib is not installed, installing ... "
		sudo yum -y install $lib
	else
		echo "$lib is installed"
	fi
	lib=net-snmp
	v=$(ldconfig -p | grep $lib)
	if [ -z "$v" ]
	then
		echo "$lib is not installed, installing ... "
		sudo yum -y install $lib
		sudo yum -y install net-snmp-devl
	else
		echo "$lib is installed"
	fi
	lib=readline-devel
	v=$(ldconfig -p | grep $lib)
	if [ -z "$v" ]
	then
        	echo "$lib is not installed, installing ... "
	        sudo yum -y install $lib
	else
        	echo "$lib is installed"
	fi
fi

#binary=bangdb-agent_s-2.0
ubuntu16=https://github.com/sachin-sinha/BangDB/raw/master/agent/all/bangdb-agent-ubuntu16.tar.gz
ubuntu18=https://github.com/sachin-sinha/BangDB/raw/master/agent/all/bangdb-agent-ubuntu18.tar.gz
ubuntu20=https://github.com/sachin-sinha/BangDB/raw/master/agent/all/bangdb-agent-ubuntu20.tar.gz
ubuntu22=https://github.com/sachin-sinha/BangDB/raw/master/agent/all/bangdb-agent-ubuntu22.tar.gz
rhel9=https://github.com/sachin-sinha/BangDB/raw/master/agent/all/bangdb-agent-rhel9.tar.gz
rhel8=https://github.com/sachin-sinha/BangDB/raw/master/agent/all/bangdb-agent-rhel8.tar.gz
rhel7=https://github.com/sachin-sinha/BangDB/raw/master/agent/all/bangdb-agent-rhel7.tar.gz
centos9=https://github.com/sachin-sinha/BangDB/raw/master/agent/all/bangdb-agent-centos9.tar.gz
centos8=https://github.com/sachin-sinha/BangDB/raw/master/agent/all/bangdb-agent-centos8.tar.gz
centos7=https://github.com/sachin-sinha/BangDB/raw/master/agent/all/bangdb-agent-centos7.tar.gz


# install key and certificate
ssl_configure() {
	openssl req -nodes -newkey rsa:2048 -keyout example.key -out example.csr -subj "/C=IN/ST=Bangalore/L=Bangalore/O=Global Security/OU=BangDB/CN=bangdb.com"
	openssl x509 -req -in example.csr -signkey example.key -out example.crt
	openssl rsa -in example.key -text > key.pem
	openssl x509 -inform PEM -in example.crt > cert.pem
	mkdir certificate
	mv key.pem cert.pem certificate
	mv certificate bin	
	# cleanup
	rm example.crt example.csr example.key
}

install_agentcmd() {
	grp=bangdb
	if [ $(getent group $grp) ]; then
		echo "group $grp exists."
	else
		echo "group $grp does not exist, creating"
		sudo useradd $grp
		sudo usermod -aG $USER $grp
	fi

	sudo mkdir /opt/bangdb-agent
	sudo mkdir /opt/bangdb-agent/bin
	sudo mkdir /opt/bangdb-agent/cli
	sudo mv bangdb-agent-ssl /opt/bangdb-agent/
	sudo mv bin/bangdb-agent_s-2.0 /opt/bangdb-agent/bin/
	sudo cp cli/bdbagent-2.0 /opt/bangdb-agent/cli/
	sudo ln -sf /opt/bangdb-agent/cli/bdbagent-2.0 /usr/local/bin/bdbagent
	certdir=/opt/bangdb-agent/bin/certificate
	if [ -d $certdir ]; then
		echo "certificates already existing"
	else
		sudo cp -r bin/certificate /opt/bangdb-agent/bin/
	fi
	agentfile=agent.conf
	if [ -f $agentfile ]; then
		echo "agent.conf file exists"
	else
		sudo cp bin/agent.conf /opt/bangdb-agent/bin/
	fi
	bangdbcfg=bangdb.config
	if [ -f $bangdbcfg ]; then
		echo "bangdb.config file exists"
	else
		sudo cp bin/bangdb.config /opt/bangdb-agent/bin/
	fi
	cd ..
	rm -rf bangdb-agent-* bangdb-agent-*.tar.gz
	sudo chown -R $USER:bangdb /opt/bangdb-agent
}

#get the agent now
v=$(awk -F= '/^VERSION_ID/{print $2;exit}' /etc/os-release)

if [ $osv -eq 2 ]
then
	if [ $v = '"16.04"' ]; then
		echo "installing for ubuntu 16 ..."
		wget --no-check-certificate $ubuntu16
		tar -xzvf bangdb-agent-ubuntu16.tar.gz
		cd bangdb-agent-ubuntu16
		ssl_configure
		install_agentcmd
		#bangdb-agent-ssl start
	fi
	if [ $v = '"18.04"' ]; then
		echo "installing for ubuntu 18 ..."
		wget --no-check-certificate $ubuntu18
		tar -xzvf bangdb-agent-ubuntu18.tar.gz
		cd bangdb-agent-ubuntu18
		ssl_configure
		install_agentcmd
		#bangdb-agent-ssl start
	fi
	if [ $v = '"20.04"' ]; then
		echo "installing for ubuntu 20 ..."
		wget --no-check-certificate $ubuntu20
		tar -xzvf bangdb-agent-ubuntu20.tar.gz
		cd bangdb-agent-ubuntu20
		ssl_configure
		install_agentcmd
		#bangdb-agent-ssl start
	fi
	if [ $v = '"22.04"' ]; then
		echo "installing for ubuntu 22 ..."
		wget --no-check-certificate $ubuntu22
		tar -xzvf bangdb-agent-ubuntu22.tar.gz
		cd bangdb-agent-ubuntu22
		ssl_configure
		install_agentcmd
		#bangdb-agent-ssl start
	fi
fi
if [ $osv -eq 3 ]
then
	if [ $v = '"9.3"' ] || [ $v = '"9.2"' ] || [ $v = '"9.1"' ] || [ $v = '"9.0"' ] || [ $v = '"9"' ]; then
		echo "installing for rhel 9 ..."
		wget --no-check-certificate $rhel9
		tar -xzvf bangdb-agent-rhel9.tar.gz
		cd bangdb-agent-rhel9
		ssl_configure
		install_agentcmd
		#bangdb-agent-ssl start
	fi
	if [ $v = '"8.9"' ] || [ $v = '"8.8"' ] || [ $v = '"8.7"' ] || [ $v = '"8.6"' ] || [ $v = '"8.5"' ] || [ $v = '"8.4"' ] || [ $v = '"8.3"' ] || [ $v = '"8.2"' ] || [ $v = '"8.1"' ] || [ $v = '"8.0"' ] || [ $v = '"8"' ]; then
		echo "installing for rhel 8 ..."
		wget --no-check-certificate $rhel8
		tar -xzvf bangdb-agent-rhel8.tar.gz
		cd bangdb-agent-rhel8
		ssl_configure
		install_agentcmd
		#bangdb-agent-ssl start
	fi
	if [ $v = '"7.9"' ] || [ $v = '"7.8"' ] || [ $v = '"7.7"' ] || [ $v = '"7.6"' ] || [ $v = '"7.5"' ] || [ $v = '"7.4"' ] || [ $v = '"7.3"' ] || [ $v = '"7.2"' ] || [ $v = '"7.1"' ] || [ $v = '"7.0"' ] || [ $v = '"7"' ]; then
		echo "installing for rhel7 ..."
		wget --no-check-certificate $rhel7
		tar -xzvf bangdb-agent-rhel7.tar.gz
		cd bangdb-agent-rhel7
		ssl_configure
		install_agentcmd
		#bangdb-agent-ssl start
	fi
fi
if [ $osv -eq 3 ]
then
	if [ $v = '"9"' ]; then
		echo "installing for centos 9 ..."
		wget --no-check-certificate $centos9
		tar -xzvf bangdb-agent-centos9.tar.gz
		cd bangdb-agent-rhel9
		ssl_configure
		install_agentcmd
		#bangdb-agent-ssl start
	fi
	if [ $v = '"8"' ]; then
		echo "installing for centos 8 ..."
		wget --no-check-certificate $centos8
		tar -xzvf bangdb-agent-centos8.tar.gz
		cd bangdb-agent-centos8
		ssl_configure
		install_agentcmd
		#bangdb-agent-ssl start
	fi
	if [ $v = '"7"' ]; then
		echo "installing for centos 7 ..."
		wget --no-check-certificate $centos7
		tar -xzvf bangdb-agent-centos7.tar.gz
		cd bangdb-agent-centos7
		ssl_configure
		install_agentcmd
		#bangdb-agent-ssl start
	fi
fi
echo "bangdb-agent install done!"
