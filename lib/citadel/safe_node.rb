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


# Block the IAM credentials from being stored to the Chef server.
# @api private
class Chef
  class Node
    old_save = instance_method(:save)

    define_method(:save) do
      security_credentials = nil
      if automatic_attrs['ec2'] && automatic_attrs['ec2']['iam'] && automatic_attrs['ec2']['iam']['security-credentials']
        security_credentials = automatic_attrs['ec2']['iam']['security-credentials']
        automatic_attrs['ec2']['iam']['security-credentials'] = {}
      end
      begin
        old_save.bind(self).call
      ensure
        unless security_credentials.nil?
          automatic_attrs['ec2']['iam']['security-credentials'] = security_credentials
        end
      end
    end

  end
end
