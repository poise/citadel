#
# Author:: Noah Kantrowitz <noah@coderanger.net>
#
# Copyright 2013, Noah Kantrowitz
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'forwardable'

module Citadel
  # Secret data retrieved from S3
  class Secret < String
    def initialize(node, bucket, key)
      super()
      @node = node
      @bucket = bucket
      @key = key
    end

    # Dispatch all String methods to #to_s
    extend Forwardable
    def_delegators(:to_s, *(String.instance_methods - Object.instance_methods))

    # Allow building up keys like a Hash
    def [](subkey)
      new_key = if @key
        "#{@key}/#{subkey}"
      else
        subkey
      end
      self.class.new(@node, @bucket, new_key)
    end

    def to_s
      Citadel.get(@node, @bucket, @key)
    end
  end

  def self.get(node, bucket, key)
    bucket ||= node['citadel']['bucket']
    if node['citadel']['access_key_id']
      # Manually specified credentials
      key_id = node['citadel']['access_key_id']
      secret_key = node['citadel']['secret_access_key']
      token = nil
    elsif node['ec2'] && node['ec2']['iam'] && node['ec2']['iam']['security-credentials']
      # Creds loaded from EC2 metadata server
      # This doesn't yet handle expiration, but it should
      role_creds = node['ec2']['iam']['security-credentials'].values.first
      key_id = role_creds['AccessKeyId']
      secret_key = role_creds['SecretAccessKey']
      token = role_creds['Token']
    else
      raise 'Unable to load secrets from S3, no S3 credentials found'
    end
    Chef::Log.debug("citadel: Retrieving #{bucket}/#{key}")
    Citadel::S3.get(bucket, key, key_id, secret_key, token)
  end

  # Helper module for the DSL extension
  module ChefDSL
    def citadel(bucket=nil)
      Secret.new(node, bucket, nil)
    end
  end
end

# Patch our DSL extension into Chef
class Chef
  class Recipe
    include Citadel::ChefDSL
  end

  class Resource
    include Citadel::ChefDSL
  end

  class Provider
    include Citadel::ChefDSL
  end
end

