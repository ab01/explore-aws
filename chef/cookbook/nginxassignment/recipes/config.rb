yum_package "yum-fastestmirror" do
	action :install
end

execute "yum-update" do
	user "root"
	command "yum -y update"
	action :run
end

package "nginx" do
	action :install
end

package "httpd-tools" do
        action :install
end

template "/etc/nginx/nginx.conf" do
        source "nginx.conf.erb"
        user "root"
        mode 0644
end 

htpasswd "/etc/nginx/htpassword" do
  user "nginx"
  password "passw0rd"
end

template "/opt/a.txt" do
	source "a.txt.erb"
        user "root"
        mode 0644
end
