############################ BEGIN GLOBAL ATTRIBUTES #######################################
include_attribute "conda"
include_attribute "kagent"
include_attribute "hops"
include_attribute "tensorflow"
include_attribute "ndb"

default['cvat']['version']                      = "0.3.0"

default['cvat']['user']                         = node['install']['user'].empty? ? 'cvat' : node['install']['user']
default['cvat']['group']                        = node['install']['user'].empty? ? 'cvat' : node['install']['user']

default['cvat']['dir']                          = node['install']['dir'].empty? ? "/srv/hops/cvat" : node['install']['dir'] + "/cvat"

default['cvat']['home']                         = "#{node['cvat']['dir']}/cvat-#{node['cvat']['python']}-#{node['cvat']['version']}"
default['cvat']['base_dir']                     = "#{node['cvat']['dir']}/cvat"

default['cvat']['pid_file']                     = "#{node['cvat']['dir']}/cvat/cvat.pid"

default['cvat']['openvino']                     = "false"
default['cvat']['cuda']                         = "false"

default['cvat']['django_config']                = "development" # base, development, staging

default['cvat']['admin_user']                   = "admin"

default['cvat']['admin_password']               = "cvat2019"

default['django']['db_password']                = "django2019"

default['redis']['dir']                         = node['install']['dir'].empty? ? "/srv/hops" : node['install']['dir'] 
default['redis']['base_dir']                    = "#{node['redis']['dir']}/redis"

default['cvat']['branch']                       = "develop"
