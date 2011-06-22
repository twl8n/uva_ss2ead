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

# def self.work(file)
  
#   # Read the spreadsheet file into a list of hashes, process the
#   # list of hashes into dsc xml, process the dsc with the outer
#   # elements of ead, make sure our output files doesn't exist,
#   # write the output.

#   print "Processing #{file} ..."

#   loh, coll_hr = Ss_converter.file2loh(file)

#   r_flag, dsc = Ss_converter.proc_rows(loh, @cox_t)
#   if (r_flag)
#     base = File.basename(file,File.extname(file)) 
#     new_name = "#{base}.xml"

#     # Write/overwrite the xml file name into a hash value for each iteration.
#     coll_hr['xml_name'] = new_name

#     # coll_hr must be defined and valid for outer_t.
#     xml = @outer_t.result(binding())

#     if File.exists?(new_name)
#       File.rename(new_name, "#{new_name}.bak")
#     end
#     File.open(new_name, "wb") { |my_xml|
#       my_xml.write(xml)
#     }
#     print " Done.\n"
#   else
#     print " Error.\n"
#   end
# end

# Unbuffer output.
STDOUT.sync = true

# # _t aka "template"
# @outer_t = ERB.new File.new("#{File.dirname(File.expand_path(__FILE__))}/pre_dsc_header_t.erb").read, nil, "%"
# @cox_t = ERB.new File.new("#{File.dirname(File.expand_path(__FILE__))}/cox_loop_t.erb").read, nil, "%"


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
        mdo = Msg_dohicky.new(get_remote_addr, "/home/twl8n/uva_ss2ead")
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
    mdo = Msg_dohicky.new(get_remote_addr, "/home/twl8n/uva_ss2ead")
    message = Ss_converter.convert_one(file, mdo)
    puts message
  }
end


exit
