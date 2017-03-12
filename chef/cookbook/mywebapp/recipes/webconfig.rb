details = Chef::EncryptedDataBagItem.load("mysecrets", "apacheconfig")

case "#{node['mywebapp']['apache_portal']}"
	when "qa"
        template "#{node['mywebapp']['config_path']}/webappssl_default.conf" do
        	source "webappssl_default.conf.erb"
		owner "#{node['mywebapp']['user']}"
		mode 0644
	end

	when "stg"
        template "#{node['mywebapp']['config_path']}/webapp_default.conf" do
                source "webapp_default.conf.erb"
                variables(
                	:owner => details["user"]
                )
                owner "#{node['mywebapp']['user']}" 
                mode 0644
        end
end

service "httpd" do
    action [:enable,:restart]
end
