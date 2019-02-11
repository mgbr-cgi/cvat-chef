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
package "vi"
package "git"

#    rm -rf /var/lib/apt/lists/*


apt_repository 'xerus-media' do
  uri "ppa:mc3man/xerus-media"
  action :remove
end

apt_repository 'ffmpeg' do
  uri "ppa:mc3man/gstffmpeg-keep"
  action :remove
end
                             



home="/home/#{node['cvat']['user']}"

git home do
   repository 'https://github.com/opencv/cvat.git'
   revision "v" + node['cvat']['version']
   action :sync
   user node['cvat']['user']
   group node['cvat']['group']
end


execute 'copy_components' do
  user node['cvat']['user']
  command "cp -r #{home}/components /tmp"
  action :run
end

/home/#{node['cvat']['user']}"

git home do
   repository 'https://github.com/opencv/cvat.git'
   revision "v" + node['cvat']['version']
   action :sync
   user node['cvat']['user']
   group node['cvat']['group']
end


execute 'copy_components' do
  user node['cvat']['user']
  command "cp -r #{home}/components /tmp"
  action :run
end

execute 'run_openvino' do
  user node['cvat']['user']
  command "/tmp/components/openvino/install.sh"
  action :run
  environment ({'OPENVINO_TOOLKIT' => 'yes'})
  only_if node['cvat']['openvino'] == "true"  
end

execute 'run_cuda' do
  user node['cvat']['user']
  command "/tmp/components/cuda/install.sh"
  action :run
  only_if node['cvat']['cuda'] == "true"
  environment ({'CUDA_SUPPORT' => 'yes'})  
end

execute 'run_tf_annotation' do
  user node['cvat']['user']
  command "bash -i /tmp/components/tf_annotation/install.sh"
  action :run
  only_if node['cvat']['tf_annotation'] == "true"
  environment ({'TF_ANNOTATION' => 'yes', 'TF_ANNOTATION_MODEL_PATH'=${home}/rcnn/inference_graph})  
end

execute 'copy_requirements' do
  user node['cvat']['user']
  command "cp -r cvat/requirements/ /tmp/requirements/"
  action :run
end

execute 'copy_supervisord' do
  user node['cvat']['user']
  command "cp supervisord.conf #{home}"
  action :run
end

execute 'copy_wsgi' do
  user node['cvat']['user']
  command "cp mod_wsgi.conf #{home}"
  action :run
end

execute 'copy_wait_for_it' do
  user node['cvat']['user']
  command "cp wait-for-it.sh #{home}"
  action :run
end

execute 'copy_wait_for_it' do
  user node['cvat']['user']
  command "cp manage.py #{home}"
  action :run
end


DJANGO_CONFIGURATION=node['cvat']['django_config']

bash "django_pip_install" do
    user node['cvat']['user']
    group node['cvat']['group']
    code <<-EOF
      pip3 install --no-cache-dir -r /tmp/requirements/#{DJANGO_CONFIGURATION}.txt             
    EOF
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
    if [ -z ${socks_proxy} ]; then 
        echo export "GIT_SSH_COMMAND=\"ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30\"" >> ${HOME}/.bashrc; 
    else 
        echo export "GIT_SSH_COMMAND=\"ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 -o ProxyCommand='nc -X 5 -x ${socks_proxy} %h %p'\"" >> ${HOME}/.bashrc;
    fi

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
  only_if node['cvat']['openvino'] == "true"
end    


execute 'copy_ssh' do
  user node['cvat']['user']
  command "cp -r ssh #{home}/.ssh"
  action :run
end

execute 'copy_cvat' do
  user node['cvat']['user']
  command "cp -r cvat #{home}/cvat"
  action :run
end

execute 'copy_tests' do
  user node['cvat']['user']
  command "cp -r tests #{home}/tests"
  action :run
end

execute 'patch' do
  user node['cvat']['user']
  command "RUN patch -p1 < ${HOME}/cvat/apps/engine/static/engine/js/3rdparty.patch"
  action :run
end


execute 'patch' do
  user node['cvat']['user']  
  command "chown -R ${USER}:${USER} ."
  action :run
end

execute 'chown' do
  user 'root'
  command "chown -R #{node['cvat']['user']}:#{node['cvat']['group']} ."
  action :run
end


execute 'chown' do
  user node['cvat']['user']  
  command "mkdir data share media keys logs /tmp/supervisord"
  action :run
end


execute 'chown' do
  user node['cvat']['user']  
  command "python3 manage.py collectstatic"
  action :run
end

execute 'chown' do
  user node['cvat']['user']  
  command "python3 manage.py collectstatic"
  action :run
end
#EXPOSE 8080 8443
#ENTRYPOINT ["/usr/bin/supervisord"]
