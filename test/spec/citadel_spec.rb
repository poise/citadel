#
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

require 'spec_helper'

describe Citadel do
  let(:args) { [] }
  subject { described_class.new(chef_run.node, *args)['mykey'] }
  before do
    override_attributes['citadel'] ||= {}
    override_attributes['citadel']['bucket'] = 'mybucket'
  end

  context 'with testing node attributes' do
    before do
      override_attributes['citadel']['access_key_id'] = 'mykey'
      override_attributes['citadel']['secret_access_key'] = 'mysecret'
    end

    it do
      expect(Citadel::S3).to receive(:get).with(bucket: 'mybucket', region: 'us-east-1', path: 'mykey', access_key_id: 'mykey', secret_access_key: 'mysecret', token: nil).and_return(double(to_s: ''))
      subject
    end
  end # /context with testing node attributes

  context 'with ohai credentials' do
    before do
      override_attributes['ec2'] ||= {}
      override_attributes['ec2']['iam'] ||= {}
      override_attributes['ec2']['iam']['security-credentials'] ||= {}
      override_attributes['ec2']['iam']['security-credentials']['myrole'] ||= {}
      override_attributes['ec2']['iam']['security-credentials']['myrole']['AccessKeyId'] = 'mykey'
      override_attributes['ec2']['iam']['security-credentials']['myrole']['SecretAccessKey'] = 'mysecret'
      override_attributes['ec2']['iam']['security-credentials']['myrole']['Token'] = 'mytoken'
    end

    it do
      expect(Citadel::S3).to receive(:get).with(bucket: 'mybucket', region: 'us-east-1', path: 'mykey', access_key_id: 'mykey', secret_access_key: 'mysecret', token: 'mytoken').and_return(double(to_s: ''))
      subject
    end
  end # /context with ohai credentials

  context 'with direct metadata access' do
    before do
      override_attributes['ec2'] ||= {}
    end

    it do
      fake_http = double('metadata_service')
      expect(fake_http).to receive(:get).with('latest/meta-data/iam/security-credentials/').and_return('myrole')
      expect(fake_http).to receive(:get).with('latest/meta-data/iam/security-credentials/myrole').and_return({AccessKeyId: 'mykey', SecretAccessKey: 'mysecret', Token: 'mytoken'}.to_json)
      expect(Chef::HTTP).to receive(:new).with('http://169.254.169.254').and_return(fake_http)
      expect(Citadel::S3).to receive(:get).with(bucket: 'mybucket', region: 'us-east-1', path: 'mykey', access_key_id: 'mykey', secret_access_key: 'mysecret', token: 'mytoken').and_return(double(to_s: ''))
      subject
    end
  end # /context with direct metadata access

  context 'with no IAM role' do
    before do
      override_attributes['ec2'] ||= {}
    end

    it do
      fake_http = double('metadata_service')
      expect(fake_http).to receive(:get).with('latest/meta-data/iam/security-credentials/').and_raise(Net::HTTPServerException.new(nil, nil))
      expect(Chef::HTTP).to receive(:new).with('http://169.254.169.254').and_return(fake_http)
      expect { subject }.to raise_error Citadel::CitadelError
    end
  end # /context with no IAM role
end
