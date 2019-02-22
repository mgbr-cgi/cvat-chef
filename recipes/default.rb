#include_recipe "java"

# User anaconda needs access to bin/hadoop to install Pydoop
# This is a hack to get the hadoop group.
# Hadoop group is created in hops::install *BUT*
# Karamel does NOT respect dependencies among install recipies
# so it has to be here and it has to be dirty (Antonis)
hops_group = "hadoop"
if node.attribute?("hops")
  if node['hops'].attribute?("group")
    hops_group = node['hops']['group']
  end
end

group hops_group do
  action :modify
  members ["#{node['cvat']['user']}"]
  append true
end

home="/home/#{node['cvat']['user']}"
cvat="/home/#{node['cvat']['user']}/cvat"

DJANGO_CONFIGURATION=node['cvat']['django_config']



bash "create_cvat_env" do
  user node['conda']['user']
  group node['conda']['group']
  cwd "/home/#{node['conda']['user']}"
  code <<-EOF
       #{node['conda']['base_dir']}/bin/conda create -n cvat -q python=3.6 -y
       #{node['conda']['base_dir']}/envs/cvat/bin/pip install --no-cache-dir -r /tmp/requirements/#{DJANGO_CONFIGURATION}.txt             
  EOF
  not_if "test -d #{node['conda']['base_dir']}/envs/cvat", :user => node['conda']['user']
end

bash "django_apt_update" do
    user 'root'
    code <<-EOF
    apt-get update
    apt-get install -y ssh netcat-openbsd curl zip 
    wget -qO /dev/stdout https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash
    apt-get install -y git-lfs
    git lfs install
    rm -rf /var/lib/apt/lists/*
    # if [ -z ${socks_proxy} ]; then 
    #     echo export "GIT_SSH_COMMAND=\"ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30\"" >> ${HOME}/.bashrc; 
    # else 
    #     echo export "GIT_SSH_COMMAND=\"ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 -o ProxyCommand='nc -X 5 -x ${socks_proxy} %h %p'\"" >> ${HOME}/.bashrc;
    # fi
    EOF
end


bash "openvino_update" do
  user node['cvat']['user']
  group node['cvat']['group']
  code <<-EOF
        mkdir ${HOME}/reid
        wget https://download.01.org/openvinotoolkit/2018_R5/open_model_zoo/person-reidentification-retail-0079/FP32/person-reidentification-retail-0079.xml -O reid/reid.xml
        wget https://download.01.org/openvinotoolkit/2018_R5/open_model_zoo/person-reidentification-retail-0079/FP32/person-reidentification-retail-0079.bin -O reid/reid.bin
  EOF
  only_if { "#{node['cvat']['openvino']}" == "true" }
end    


# execute 'copy_ssh' do
#   user node['cvat']['user']
#   command "cp -r ssh #{home}/.ssh"
#   action :run
# end

# execute 'copy_cvat' do
#   user node['cvat']['user']
#   cwd "/tmp"
#   command "cp -r cvat #{home}/cvat"
#   action :run
# end


# execute 'copy_tests' do
#   user node['cvat']['user']
#   cwd "/tmp"
#   command "cp -r tests #{home}/tests"
#   action :run
# end

execute 'patch' do
  user node['cvat']['user']
  cwd "/home/#{node['cvat']['user']}/cvat"
  command "patch -p1 < cvat/apps/engine/static/engine/js/3rdparty.patch"
  action :run
end


execute 'chown' do
  user 'root'
  cwd "/home/#{node['cvat']['user']}"  
  command "chown -R #{node['cvat']['user']}:#{node['cvat']['group']} cvat"
  action :run
end


execute 'mkdir_supervisord' do
  user node['cvat']['user']
  cwd "/home/#{node['cvat']['user']}/cvat"  
  command "mkdir data share media keys logs /tmp/supervisord"
  action :run
end


execute 'collectstatic' do
  user node['cvat']['user']
  cwd "/home/#{node['cvat']['user']}/cvat"  
  command "#{node['conda']['base_dir']}/envs/cvat/bin/python manage.py collectstatic"
  action :run
end

#EXPOSE 8080 8443
#ENTRYPOINT ["/usr/bin/supervisord"]
