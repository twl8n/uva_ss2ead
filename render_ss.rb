#!/usr/bin/env ruby

# Render CSV data (spreadsheet) into an arbitrarily depth nested XML
# hierarchy via a template.

# Created by Tom Laudeman

# Copyright 2011 University of Virginia

# Licensed under the Apache License, Version 2.0 (the "License"); you
# may not use this file except in compliance with the License.  You
# may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.  See the License for the specific language governing
# permissions and limitations under the License.

# Working version. Correct order and nesting.
# ./render_csv.rb second_example.csv | xmllint --format - | less

require 'lib/util'

# Unbuffer output.
STDOUT.sync = true

# chdir to the working dir so we can use file names without full
# paths. Use the block version of chdir so after the block we are in
# the dir where we started.

if File.directory?(ARGV[0])
  # We are processing an entire directory.
  Dir.chdir(ARGV[0]) {
    Find.find("./") { |file|
      # Skip . .. and files that aren't .csv or .xlsx
      if file.match(/^\.[\/]*$/) || ! File.extname(file).match(/csv|xlsx/i)
        next
      end

      if File.directory?(file)
        # Don't descend into directories.
        # print "prune #{file}\n"
        Find.prune()
      else
        #print "work #{file}\n"
        # work(file)
        mdo = Msg_dohicky.new(get_remote_addr, Home)
        message = Ss_converter.convert_one(file, mdo)
        puts message
      end
    }
  }
else
  # We are processing only one file.
  path = File.dirname(ARGV[0])
  file = File.basename(ARGV[0])
  Dir.chdir(path) {
    mdo = Msg_dohicky.new(get_remote_addr, Home)
    message = Ss_converter.convert_one(file, mdo)
    puts message
  }
end


exit
