#
# Cookbook Name:: ssh-auth
# Recipe:: default
#
# Copyright (C) 2014 YOUR_NAME
#
# All rights reserved - Do Not Redistribute
#

def update_authorized_keys(data)
  data.each do |user, keys|
    next if ! keys
    file "/home/#{user}/.ssh/authorized_keys" do
      content keys.join("\n")
      owner user
      group user
      mode 00600
    end
  end
end


def update_admin_only()
  auth_keys = {}
  admin = data_bag_item('ssh-projects', 'admin')
  admin['user-list'].each do |u|
    auth_keys[u] = []
    admin["#{u}"].each do |ku|
      ssh_user = data_bag_item('ssh-users', "#{ku.gsub(/[^a-z]/i,'_')}")
      ssh_user["public_keys"].each { |k| auth_keys[u] << k }
    end
  end
  update_authorized_keys auth_keys
end

def update_with_project(p)
  auth_keys = {}
  admin = data_bag_item('ssh-projects', 'admin')
  admin['user-list'].each do |u|
    auth_keys[u] = []
    admin["#{u}"].each do |ku|
      ssh_user = data_bag_item('ssh-users', "#{ku.gsub(/[^a-z]/i,'_')}")
      ssh_user["public_keys"].each { |k| auth_keys[u] << k }
    end
  end

  project = data_bag_item('ssh-projects', "#{p}")
  project['user-list'].each do |u|
    auth_keys[u] = [] if ! auth_keys[u]
    project["#{u}"].each do |ku|
      ssh_user = data_bag_item('ssh-users', "#{ku.gsub(/[^a-z]/i,'_')}")
      ssh_user["public_keys"].each { |k| auth_keys[u] << k }
      auth_keys[u] = auth_keys[u].uniq
    end
  end

  update_authorized_keys auth_keys
end

if node['ssh-auth']['project'] 
  project = node['ssh-auth']['project']
  if project == "admin"
    update_admin_only
  else
    update_with_project(project)
  end
else
  update_with_project
end
