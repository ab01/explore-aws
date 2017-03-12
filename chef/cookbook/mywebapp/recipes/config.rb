yum_package "yum-fastestmirror" do
	action :install
end

execute "yum-update" do
	user "root"
	command "yum -y update"
	action :run
end

package "httpd" do
	action :install
end

service "httpd" do
	action [:start,:enable ]
end

template "/var/www/html/index.html" do
	source "index.html.erb"
        user "root"
        mode 0644
end
