
Chef – Encrypted Data-bags example
June 23, 2012 by James Tran	
Create your encrypt/decrypt “key”

$ openssl rand -base64 512 > ~/.chef/encrypted_data_bag_secret
Create a new “data bag” named “mysecrets”

$ knife data bag create mysecrets
Create a new json with information that you want encrypted.

This will be stored inside the “data bag” named “mysecrets”
This will use the “key” you created earlier to encrypt
We will store this as “marioworld”

$ knife data bag create mysecrets marioworld –secret-file ~/.chef/encrypted_data_bag_secret
* This will prompt open an editor to add items to json
1
2
3
4
	
{ "id": "marioworld",
"user": "luigi"
"pass": "yahoo"
}
Now Create a simple recipe and template file that will utilize this encrypted “data bag”
Create the Recipe

$ knife cookbook create databag-test
$ cd ~/chef-repo/cookbooks/recipes/
$ vi default.rb
1
2
3
4
5
6
7
8
9
10
11
12
13
14
15
16
17
18
19
20
21
22
23
24
25
26
27
28
29
30
31
32
	
#
# Cookbook Name:: databag-test
# Recipe:: default
#
# Copyright 2012, James Tran
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
 
# This is where you will store a copy of your key on the chef-client
secret = Chef::EncryptedDataBagItem.load_secret("/etc/chef/encrypted_data_bag_secret")
 
# This decrypts the data bag contents of "mysecrets->marioworld" and uses the key defined at variable "secret"
luigi_keys = Chef::EncryptedDataBagItem.load("mysecrets", "marioworld", secret)
 
template "/tmp/databag" do
     variables(:mypass => luigi_keys['pass'],
               :myuser => luigi_keys['user'])
     owner "root"
     mode  "0644"
     source "databag_test.erb"
end
Create the Template

$ cd ~/chef-repo/cookbooks/databag-test/templates
$ vi databag_test.erb
1
2
	
Username: <%= @myuser %>
Password: <%= @mypass %>
Copy your “key” to the node

$ scp ~/.chef/encrypted_data_bag_secret root@somenode:/etc/chef/
Add the recipe to a node and run chef-client

$ knife node run_list add somenode “recipe[databag-test]”
$ knife ssh “name:somenode” -x root “chef-client”
Verify the contents of the new file created at /tmp/databag

$ knife ssh “name:somenode” -x root “cat /tmp/databag”

Username: luigi
Password: yahoo
