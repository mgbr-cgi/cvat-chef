name              "cvat"
maintainer        "Jim Dowling"
maintainer_email  'jim@logicalclocks.com'
license           'AGPL v3'
description       'Installs/Configures cvat'
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           "0.9.0"

supports 'ubuntu', '= 16.04'
supports 'centos', '= 7.5'

depends           'java'
depends            'kagent'
depends            'hops'
depends            'tensorflow'
depends            'ndb'

recipe "cvat::install", "Installs  cvat"
recipe "cvat::default", "Configures cvat"
recipe "cvat::redis", "Installs and configures redis (for cvat)"


################################ Begin installation wide attributes ########################################

attribute "cvat/dir",
          :description => "Base installation directory for Cvat",
          :type => 'string'

attribute "cvat/user",
          :description => "User that runs cvat",
          :type => 'string'

attribute "cvat/group",
          :description => "Group that runs cvat",
          :type => 'string'

attribute "cvat/openvino",
          :description => "set to 'true' to install openvino",
          :type => 'string'

attribute "cvat/cuda",
          :description => "set to 'true' to install cuda",
          :type => 'string'

attribute "cvat/django_config",
          :description => "default: 'production'. Options: 'development', 'base', 'staging'",
          :type => 'string'

attribute "cvat/admin_user",
          :description => "Admin username for cvat",
          :type => 'string'

attribute "cvat/admin_password",
          :description => "Admin password for cvat",
          :type => 'string'

attribute "django/db_password",
          :description => "MySQL database password for the 'django' user",
          :type => 'string'

attribute "cvat/branch",
          :description => "Default 'develop'",
          :type => 'string'
