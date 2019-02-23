#
#
# REDIS
#

bash "install_redis" do
  user 'root'
  umask "022"
  environment ({'HOME' => "/home/#{node['cvat']['user']}"})
  cwd "/home/#{node['cvat']['user']}"
  code <<-EOF
      sudo apt install build-essential tcl
      curl -O http://download.redis.io/redis-stable.tar.gz
      tar zxf redis-stable.tar.gz
      cd redis-stable
      make install
      mkdir /etc/redis
      mkdir #{node['install']['dir']}/redis
      chmod 770 #{node['install']['dir']}/redis
      chown -R #{node['cvat']['user']}:#{node['cvat']['group']} #{node['install']['dir']}/redis
      ln -s #{node['install']['dir']}/redis /var/lib/redis
  EOF
  'not_if "systemctl status redis"'
end

template "/etc/redis/redis.conf" do
  source 'redis.conf.erb'
  owner "root"
  group "root"
  mode 0755
end


service_name = "redis"

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
    service service_name
    log_file "/var/log/redis.log"
    web_port 0000
  end
end

