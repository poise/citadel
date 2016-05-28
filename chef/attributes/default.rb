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

# Default S3 bucket to use for Citadel data
default['citadel']['bucket'] = nil
default['citadel']['region'] = 'us-east-1'

# Override these for use in Vagrant or other development environments
default['citadel']['access_key_id'] = nil
default['citadel']['secret_access_key'] = nil
