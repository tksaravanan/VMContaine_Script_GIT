class yamlfilecreation inherits yamlfilecreation::var {

file{   "/opt/MaaS":
	ensure => directory,
		}
->
file{   "/opt/MaaS/DockerContainer":
	ensure => directory,
		}
->
file{   "/opt/MaaS/DockerContainer/$mysql_container_name.yaml":
	ensure => file,
	content => template ("yamlfilecreation/mysqldocker.yaml.erb"),
		}

}
