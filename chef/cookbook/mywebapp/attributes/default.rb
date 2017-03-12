default[:mywebapp][:server_dns_name]="node.jnanalab.com"
default['mywebapp']['impl_dir']="/var/www/html"
default['mywebapp']['config_path']="/etc/httpd/conf.d"
default['mywebapp']['user']="root"
default['mywebapp']['apache_portal']=%w(qa,stg)
