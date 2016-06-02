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

describe Citadel::S3 do
  let(:fake_http) { double('Chef::HTTP') }
  let(:fake_response) { double('Net::HTTPResponse') }
  let(:s3_hostname) { 's3.amazonaws.com' }
  before do
    # Stub out the HTTP object.
    expect(Chef::HTTP).to receive(:new).with("https://#{s3_hostname}").and_return(fake_http)
    # Freeze time so our signing is predictable.
    allow(Time).to receive(:now).and_return(Time.at(0))
  end

  context 'with mybucket/mysecret' do
    subject { described_class.get(bucket: 'mybucket', path: 'mysecret', access_key_id: 'AKIAJMKSMHNNCQX4ILAH', secret_access_key: '0ljyHQrk1AGsc2bgx/8fbNghZNYSdckHADR4vNcL') }
    before do
      expect(fake_http).to receive(:get).with('mybucket/mysecret', 'date' => 'Thu, 01 Jan 1970 00:00:00 GMT', 'authorization' => "AWS AKIAJMKSMHNNCQX4ILAH:TQPmJfb3Mx2MblMnRHJS1EG6jus=\n").and_return(fake_response)
    end

    it { is_expected.to be fake_response }
  end # /context with mybucket/mysecret

  context 'with token' do
    subject { described_class.get(bucket: 'mybucket', path: 'mysecret', access_key_id: 'AKIAJMKSMHNNCQX4ILAH', secret_access_key: '0ljyHQrk1AGsc2bgx/8fbNghZNYSdckHADR4vNcL', token: 'EIZvol3NYAGhIYo3mxmF8Bw3GjRFQq6xmjrlXNQs') }
    before do
      expect(fake_http).to receive(:get).with('mybucket/mysecret', 'date' => 'Thu, 01 Jan 1970 00:00:00 GMT', 'authorization' => "AWS AKIAJMKSMHNNCQX4ILAH:ZapoW/urO8FlRSEf+y5iWYeNsrs=\n", 'x-amz-security-token' => 'EIZvol3NYAGhIYo3mxmF8Bw3GjRFQq6xmjrlXNQs').and_return(fake_response)
    end

    it { is_expected.to be fake_response }
  end # /context with token

  context 'with a region' do
    let(:s3_hostname) { 's3-us-west-2.amazonaws.com' }
    subject { described_class.get(bucket: 'mybucket', path: 'mysecret', access_key_id: 'AKIAJMKSMHNNCQX4ILAH', secret_access_key: '0ljyHQrk1AGsc2bgx/8fbNghZNYSdckHADR4vNcL', region: 'us-west-2') }
    before do
      expect(fake_http).to receive(:get).with('mybucket/mysecret', 'date' => 'Thu, 01 Jan 1970 00:00:00 GMT', 'authorization' => "AWS AKIAJMKSMHNNCQX4ILAH:TQPmJfb3Mx2MblMnRHJS1EG6jus=\n").and_return(fake_response)
    end

    it { is_expected.to be fake_response }
  end # /context with a region

  context 'with an exception' do
    subject { described_class.get(bucket: 'mybucket', path: 'mysecret', access_key_id: 'AKIAJMKSMHNNCQX4ILAH', secret_access_key: '0ljyHQrk1AGsc2bgx/8fbNghZNYSdckHADR4vNcL') }
    before do
      expect(fake_http).to receive(:get).with('mybucket/mysecret', 'date' => 'Thu, 01 Jan 1970 00:00:00 GMT', 'authorization' => "AWS AKIAJMKSMHNNCQX4ILAH:TQPmJfb3Mx2MblMnRHJS1EG6jus=\n").and_raise(Net::HTTPServerException.new(nil, nil))
    end

    it { expect { subject }.to raise_error Citadel::CitadelError }
  end # /context with an exception
end




