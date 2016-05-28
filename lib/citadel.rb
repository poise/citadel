#
# Copyright 2013-2016, Balanced, Inc.
# Copyright 2016, Noah Kantrowitz
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

require 'chef/http'
require 'chef/json_compat'


# Helper to access files in a private S3 bucket using an interface like Chef
# node attributes.
#
# @since 1.0.0
# @example
#   template '/etc/myapp.conf' do
#     variables password: citadel['myapp/password']
#   end
class Citadel
  autoload :ChefDSL, 'citadel/chef_dsl'
  autoload :CitadelError, 'citadel/error'
  autoload :S3, 'citadel/s3'
  autoload :VERSION, 'citadel/version'

  attr_reader :bucket, :region, :credentials

  def initialize(node, bucket=nil, region=nil)
    @node = node
    @bucket = bucket || node['citadel']['bucket']
    @region = region || node['citadel']['region']
    @credentials = find_credentials
  end

  def find_credentials
    if @node['citadel']['access_key_id']
      {
        access_key_id: @node['citadel']['access_key_id'],
        secret_access_key: @node['citadel']['secret_access_key'],
        token: @node['citadel']['token'],
      }
    elsif @node['ec2']
      role_creds = if @node['ec2']['iam'] && @node['ec2']['iam']['security-credentials']
        # Creds loaded from Ohai.
        @node['ec2']['iam']['security-credentials'].values.first
      else
        metadata_service = Chef::HTTP.new('http://169.254.169.254')
        iam_role = metadata_service.get('latest/meta-data/iam/security-credentials/')
        if iam_role.nil? || iam_role.empty?
          raise 'Unable to find IAM role for node from EC2 metadata'
        else
          creds_json = metadata_service.get("latest/meta-data/iam/security-credentials/#{iam_role}")
          Chef::JSONCompat.parse(creds_json)
        end
      end
      {
        access_key_id: role_creds['AccessKeyId'],
        secret_access_key: role_creds['SecretAccessKey'],
        token: role_creds['Token'],
      }
    else
      raise 'Unable to find S3 credentials'
    end
  end

  def [](key)
    Chef::Log.debug("citadel: Retrieving #{@bucket}/#{key}")
    Citadel::S3.get(bucket: @bucket, path: key, region: @region, **@credentials).to_s
  end
end
