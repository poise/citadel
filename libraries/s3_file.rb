#
# Author:: Brandon Adams <brandon.adams@me.com>
# Author:: Noah Kantrowitz <noah@coderanger.net>
#
# Copyright 2012-2013, Brandon Adams and other contributors
# Copyright 2013, Balanced, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'time'
require 'openssl'
require 'base64'

class Citadel
  class CitadelError < Exception; end

  module S3
    extend self

    def get(bucket, path, aws_access_key_id, aws_secret_access_key, token=nil)
      path = path[1..-1] if path[0] == '/'
      now = Time.now().utc.strftime('%a, %d %b %Y %H:%M:%S GMT')

      string_to_sign = "GET\n\n\n#{now}\n"
      string_to_sign << "x-amz-security-token:#{token}\n" if token
      string_to_sign << "/#{bucket}/#{path}"

      signed = OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha1'), aws_secret_access_key, string_to_sign)
      signed_base64 = Base64.encode64(signed)

      headers = {
        'date' => now,
        'authorization' => "AWS #{aws_access_key_id}:#{signed_base64}",
      }
      headers['x-amz-security-token'] = token if token
      begin
        Chef::HTTP.new("https://#{bucket}.s3.amazonaws.com").get(path, headers)
      rescue Net::HTTPServerException => e
        raise CitadelError, "Unable to download #{path}: #{e}"
      end
    end

  end
end
