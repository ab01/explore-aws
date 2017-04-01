details = Chef::EncryptedDataBagItem.load("nginxsecrets", "nginx")

case "#{node['nginxscenario']['nginx_portal']}"

	when "dev"
        template "#{node['nginxscenario']['config_path']}/webappssl_default.conf" do
        	source "webappssl_default.conf.erb"
		owner "#{node['nginxscenario']['user']}"
		mode 0644
	end

        directory "#{node['nginxscenario']['sslplacement']}" do
                  owner "#{node['nginxscenario']['user']}"
                  group "#{node['nginxscenario']['user']}"
                  recursive true
                  action :create
                  mode '0755'
        end

        cookbook_file "#{node['nginxscenario']['sslplacement']}/nginx.key" do
                 source 'nginx.key'
                 owner "#{node['nginxscenario']['user']}"
                 group "#{node['nginxscenario']['user']}"
                 mode '0644'
                 action :create
       end

       cookbook_file "#{node['nginxscenario']['sslplacement']}/nginx.crt" do
                 source 'nginx.crt'
                 owner "#{node['nginxscenario']['user']}"
                 group "#{node['nginxscenario']['user']}"
                 mode '0644'
                 action :create
       end


        when "prd"
        template "#{node['nginxscenario']['config_path']}/webapp_default.conf" do
                source "webapp_default.conf.erb"
                owner "#{node['nginxscenario']['user']}" 
                mode 0644
        end
end
