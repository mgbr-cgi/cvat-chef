############################ BEGIN GLOBAL ATTRIBUTES #######################################
include_attribute "kagent"

default['cvat']['version']                      = "0.3.0"

default['cvat']['user']                         = node['install']['user'].empty? ? 'cvat' : node['install']['user']
default['cvat']['group']                        = node['install']['user'].empty? ? 'cvat' : node['install']['user']

default['cvat']['dir']                          = node['install']['dir'].empty? ? "/srv/hops/cvat" : node['install']['dir'] + "/cvat"

default['cvat']['home']                         = "#{node['cvat']['dir']}/cvat-#{node['cvat']['python']}-#{node['cvat']['version']}"
default['cvat']['base_dir']                     = "#{node['cvat']['dir']}/cvat"

default['cvat']['openvino']                     = "false"
default['cvat']['cuda']                         = "false"

default['cvat']['django_config']                = "development" # base, development, staging
