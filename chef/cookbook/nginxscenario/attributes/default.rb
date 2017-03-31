default[:nginxscenario][:server_dns_name]="dev.jnanalab.com"
default['nginxscenario']['impl_dir']="/opt"
default['nginxscenario']['config_path']="/etc/nginx/sites-available"
default['nginxscenario']['user']="root"
default['nginxscenario']['sslplacement']="/etc/nginx/ssl"
default['nginxscenario']['nginx_portal']=%w(dev,prd)
