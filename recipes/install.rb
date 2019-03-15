if node['kernel']['machine'] != 'x86_64'
   Chef::Log.fatal!("Unrecognized node.kernel.machine=#{node['kernel']['machine']}; Only x86_64", 1)
end

package "bzip2"

group node['cvat']['group']
user node['cvat']['user'] do
  gid node['cvat']['group']
  manage_home true
  home "/home/#{node['cvat']['user']}"
  shell "/bin/bash"
  action :create
  system true
  not_if "getent passwd #{node['cvat']['user']}"
end

directory node['install']['dir'] do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
  not_if { ::File.directory?(node['install']['dir']) }
end

directory node['cvat']['dir']  do
  owner node['cvat']['user']
  group node['cvat']['group']
  mode '755'
  recursive true
  action :create
  not_if { File.directory?(node['cvat']['dir']) }
end

package "python-software-properties"
package "software-properties-common"

apt_repository 'xerus-media' do
  uri "ppa:mc3man/xerus-media"
  action :add
end

apt_repository 'ffmpeg' do
  uri "ppa:mc3man/gstffmpeg-keep"
  action :add
end

package "apache2"
package "apache2-dev"
package "libapache2-mod-xsendfile"
package "supervisor"
package "ffmpeg"
package "gstreamer0.10-ffmpeg"
package "libldap2-dev"
package "libsasl2-dev"
package "python3-dev"
package "python3-pip"
package "unzip"
package "unrar"
package "p7zip-full"
package "git"
package "expect"


apt_repository 'xerus-media' do
  uri "ppa:mc3man/xerus-media"
  action :remove
end

apt_repository 'ffmpeg' do
  uri "ppa:mc3man/gstffmpeg-keep"
  action :remove
end
                             
home="/home/#{node['cvat']['user']}"

cvat="#{home}/cvat"
git cvat do
   repository 'https://github.com/logicalclocks/cvat.git'
   #   revision "v" + node['cvat']['version']
   checkout_branch "miguel"
   action :sync
   user node['cvat']['user']
   group node['cvat']['group']
end

execute 'copy_components' do
  user node['cvat']['user']
  command "cp -r #{cvat}/components /tmp"
  action :run
end


execute 'run_openvino' do
  user node['cvat']['user']
  command "/tmp/components/openvino/install.sh"
  action :run
  environment ({'OPENVINO_TOOLKIT' => 'yes'})
  only_if { "#{node['cvat']['openvino']}" == "true"}
end

execute 'run_cuda' do
  user node['cvat']['user']
  command "/tmp/components/cuda/install.sh"
  action :run
  environment ({'CUDA_SUPPORT' => 'yes'})  
  only_if { "#{node['cvat']['cuda']}" == "true" }
end

execute 'run_tf_annotation' do
  user node['cvat']['user']
  command "bash -i /tmp/components/tf_annotation/install.sh"
  action :run
  environment ({'TF_ANNOTATION' => 'yes', 'TF_ANNOTATION_MODEL_PATH'=>"#{home}/rcnn/inference_graph"})  
  only_if { "#{node['cvat']['tf_annotation']}" == "true"}
end

execute 'copy_requirements' do
  user node['cvat']['user']
  command "cp -r #{cvat}/cvat/requirements/ /tmp/requirements/"
  action :run
end

execute 'copy_supervisord' do
  user node['cvat']['user']
  command "cp #{cvat}/supervisord.conf #{home}"
  action :run
end

execute 'copy_wsgi' do
  user node['cvat']['user']
  command "cp #{cvat}/mod_wsgi.conf #{home}"
  action :run
end

execute 'copy_wait_for_it' do
  user node['cvat']['user']
  command "cp #{cvat}/wait-for-it.sh #{home}"
  action :run
end

execute 'copy_wait_for_it' do
  user node['cvat']['user']
  command "cp #{cvat}/manage.py #{home}"
  action :run
end

