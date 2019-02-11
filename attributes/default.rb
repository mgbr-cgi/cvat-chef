############################ BEGIN GLOBAL ATTRIBUTES #######################################
include_attribute "kagent"

default['cvat']['version']                      = "0.3.0"

default['cvat']['user']                         = node['install']['user'].empty? ? 'anacvat' : node['install']['user']
default['cvat']['group']                        = node['install']['user'].empty? ? 'anacvat' : node['install']['user']

default['cvat']['dir']                          = node['install']['dir'].empty? ? "/srv/hops/anacvat" : node['install']['dir'] + "/anacvat"

default['cvat']['home']                         = "#{node['cvat']['dir']}/anacvat-#{node['cvat']['python']}-#{node['cvat']['version']}"
default['cvat']['base_dir']                     = "#{node['cvat']['dir']}/anacvat"

default['cvat']['openvino']                     = "false"
default['cvat']['cuda']                         = "false"

default['cvat']['django_config']                = "production" # base, development, staging
