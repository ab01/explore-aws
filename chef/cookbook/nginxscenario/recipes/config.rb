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


template "/opt/a.txt" do
	source "a.txt.erb"
        user "root"
        mode 0644
end
