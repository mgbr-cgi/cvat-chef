include_recipe "java"

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

group node['conda']['group'] do
  action :modify
  members ["#{node['cvat']['user']}"]
  append true
end

home="/home/#{node['cvat']['user']}"
cvat="/home/#{node['cvat']['user']}/cvat"

DJANGO_CONFIGURATION=node['cvat']['django_config']


template "/home/#{node['cvat']['user']}/create-superuser.sh" do
  source 'create-superuser.sh.erb'
  owner node['cvat']['user']
  group node['cvat']['group']
  mode 0750
end


bash "create_cvat_env" do
  user node['conda']['user']
  group node['conda']['group']
  umask "022"
  environment ({'HOME' => "/home/#{node['conda']['user']}"})
  cwd "/home/#{node['conda']['user']}"
  code <<-EOF
    set -e
    #{node['conda']['base_dir']}/bin/conda create -n cvat python==3.6
  EOF
  not_if "test -d #{node['conda']['dir']}/envs/cvat", :user => node['conda']['user']
end


bash "python_reqs_install" do
  user "root"
  umask "022"
  code <<-EOF
    set -e
    export CONDA_DIR=#{node['conda']['base_dir']}
    su #{node['conda']['user']} -c "export HADOOP_HOME=#{node['hops']['base_dir']}; yes | ${CONDA_DIR}/envs/cvat/bin/pip install pydoop==#{node['pydoop']['version']}"
    # su #{node['conda']['user']} -c "export HADOOP_HOME=#{node['hops']['base_dir']}; yes | ${CONDA_DIR}/envs/cvat/bin/pip install hops
    su #{node['conda']['user']} -c "yes | #{node['conda']['dir']}/envs/cvat/bin/pip install -r /tmp/requirements/#{DJANGO_CONFIGURATION}.txt"
    EOF
end


bash "django_apt_update" do
    user 'root'
    code <<-EOF
    apt-get update
    apt-get install -y ssh netcat-openbsd curl zip 
#    wget -qO /dev/stdout https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash
#    apt-get install -y git-lfs
#    git lfs install
#    rm -rf /var/lib/apt/lists/*
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
  ignore_failure true
  action :run
end


execute 'chown' do
  user 'root'
  cwd "/home/#{node['cvat']['user']}"  
  command "chown -R #{node['cvat']['user']}:#{node['cvat']['group']} cvat"
  action :run
end


execute 'install_mysql' do
  user node['conda']['user']
  cwd "/home/#{node['cvat']['user']}"  
  command "#{node['conda']['dir']}/envs/cvat/bin/pip install mysqlclient"
  action :run
end


execute 'mkdir_supervisord' do
  user node['cvat']['user']
  cwd "/home/#{node['cvat']['user']}/cvat"  
  command "mkdir -p data share media keys logs /tmp/supervisord"
  action :run
  not_if { File.directory?("/tmp/supervisord") }
end


execute 'collectstatic' do
  user node['cvat']['user']
  cwd "/home/#{node['cvat']['user']}/cvat"  
  command "#{node['conda']['dir']}/envs/cvat/bin/python manage.py collectstatic --noinput"
  action :run
end


mysql_ip  = private_recipe_ip("ndb", "mysqld")

template "/home/#{node['cvat']['user']}/cvat/development.py" do
  source "development.py.erb"
  owner node['cvat']['user']
  group node['cvat']['group']
  mode 0751
  action :create
  variables({ :mysql_ip => mysql_ip })
end


execute 'create_db' do
  user 'root'
  cwd "/home/#{node['cvat']['user']}/cvat"
  command "#{node['ndb']['scripts_dir']}/mysql-client.sh -e 'CREATE DATABASE IF NOT EXISTS django'"
  action :run
end

execute 'create_db_user' do
  user 'root'
  cwd "/home/#{node['cvat']['user']}/cvat"
  command "#{node['ndb']['scripts_dir']}/mysql-client.sh -e \"GRANT ALL PRIVILEGES ON django.* TO 'django'@'%' IDENTIFIED BY #{node['django']['db_password']}\""
  action :run
end


execute 'turn_off_pks_bug_django' do
  user 'root'
  cwd "/home/#{node['cvat']['user']}/cvat"
  command "#{node['ndb']['scripts_dir']}/mysql-client.sh -e 'SET GLOBAL FOREIGN_KEY_CHECKS=0'"
  action :run
end

execute 'migrate' do
  user node['cvat']['user']
  cwd "/home/#{node['cvat']['user']}/cvat"  
  command "#{node['conda']['dir']}/envs/cvat/bin/python manage.py migrate"
  action :run
end

execute 'turn_on_pks_bug_django' do
  user 'root'
  cwd "/home/#{node['cvat']['user']}/cvat"
  command "#{node['ndb']['scripts_dir']}/mysql-client.sh -e 'SET GLOBAL FOREIGN_KEY_CHECKS=1'"
  action :run
end

execute 'createsuperuser' do
  user node['cvat']['user']
  cwd "/home/#{node['cvat']['user']}"    
  command "/home/#{node['cvat']['user']}/create-superuser.sh"
  action :run
end

template "/home/#{node['cvat']['user']}/cvat-stop.sh" do
  source 'cvat-stop.sh.erb'
  owner node['cvat']['user']
  group node['cvat']['group']
  mode 0755
end

service_name = "cvat"

service service_name do
  provider Chef::Provider::Service::Systemd
  supports :restart => true, :stop => true, :start => true, :status => true
  action :nothing
end

case node['platform_family']
when "rhel"
  systemd_script = "/usr/lib/systemd/system/#{service_name}.service"
else
  systemd_script = "/lib/systemd/system/#{service_name}.service"
end

file systemd_script do
  action :delete
  ignore_failure true
end

template systemd_script do
  source "#{service_name}.service.erb"
  owner "root"
  group "root"
  mode 0664
  variables({
              :java_home => node['java']['java_home']
            })
  
  if node['services']['enabled'] == "true"
    notifies :enable, resources(:service => "#{service_name}")
  end
  notifies :restart, resources(:service => service_name)
end

kagent_config "#{service_name}" do
  action :systemd_reload
  not_if "systemctl status #{service_name}"
end


if node['kagent']['enabled'] == "true"
  kagent_config service_name do
    service "cvat"
    log_file "#{node['cvat']['base_dir']}/logs/cvat_server.log"
    web_port 8000
  end
end


include_recipe "cvat::redis"
