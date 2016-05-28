#
# Copyright 2012-2016, Brandon Adams and other contributors.
# Copyright 2013-2016, Balanced, Inc.
# Copyright 2016, Noah Kantrowitz
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

require 'chef/http'

require 'citadel/error'


class Citadel
  # Simple read-only S3 client.
  #
  # @since 1.0.0
  # @api private
  module S3
    extend self

    # Get an object from S3.
    #
    # @param bucket [String] Name of the bucket to use.
    # @param path [String] Path to the object.
    # @param aws_access_key_id [String] AWS access key ID.
    # @param aws_secret_access_key [String] AWS secret access key.
    # @param token [String, nil] AWS IAM token.
    # @param region [String] S3 bucket region.
    # @return [Net::HTTPResponse]
    def get(bucket:, path:, aws_access_key_id:, aws_secret_access_key:, token: nil, region: nil)
      region ||= 'us-east-1' # Most buckets.
      path = path[1..-1] if path[0] == '/'
      now = Time.now().utc.strftime('%a, %d %b %Y %H:%M:%S GMT')

      string_to_sign = "GET\n\n\n#{now}\n"
      string_to_sign << "x-amz-security-token:#{token}\n" if token
      string_to_sign << "/#{bucket}/#{path}"

      signed = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), aws_secret_access_key, string_to_sign)
      signed_base64 = Base64.encode64(signed)

      headers = {
        'date' => now,
        'authorization' => "AWS #{aws_access_key_id}:#{signed_base64}",
      }
      headers['x-amz-security-token'] = token if token

      hostname = case region
      when 'us-east-1'
        's3.amazonaws.com'
      else
        "s3-#{region}.amazonaws.com"
      end

      begin
        Chef::HTTP.new("https://#{hostname}").get("#{bucket}/#{path}", headers)
      rescue Net::HTTPServerException => e
        raise CitadelError.net("Unable to download #{path}: #{e}")
      end
    end

  end
end
