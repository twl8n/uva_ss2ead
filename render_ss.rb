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

require 'rubygems'
require 'csv'
require 'erb'
require 'roo'
require 'find'

def self.proc_rows(loh, cox_t)

  content = ""
  stack = []
  rh = Hash.new()
  rh['content'] = ""
  rh['<c0x>'] = 0 # special zero level collects all content
  rh['yy'] = -1 # weird, but only a label
  stack.push(rh)

  xx = 0
  while xx < loh.size
    href = loh[xx]
    cox = href['<c0x>']
    if (cox.to_i < 1)
      # Must have a valid >= 1 cox
      return [false,""]
    end
    href['content'] = ""
    href['yy'] = xx
    
    # Always try to prune the stack. Always push the new hash ref onto
    # the stack. Hash refs will stay on the stack as long as the depth
    # increases. As soon as depth decreases or is the same, the stack
    # is pruned. The last href on the stack always accumulates results.

    # The template requires vars content, old_href.

    while cox.to_i <= stack.last['<c0x>'].to_i
      old_href = stack.pop()
      content = old_href['content']
      var = cox_t.result(binding())
      stack.last['content'].concat( var )
    end
    stack.push(href)
    xx += 1
  end

  while stack.size > 1
    old_href = stack.pop()
    content = old_href['content']
    var = cox_t.result(binding())
    stack.last['content'].concat( var )
  end

  # print "<dsc>#{stack.last['content']}\n</dsc>\n"

  return [true,stack.last['content']]
end


# Debug the list of hashes

def self.prloh(loh, label)
  xx = 0
  print "--- #{label}\n"
  while xx < loh.size
    href = loh[xx]
    if true # href['<c0x>'] == 1
      print "#{href['yy']}: #{href['<c0x>']}"
      print "con:#{href['content']}\n"
    end
    xx += 1
  end
  print "---\n\n"
end

def self.dumploh(loh, label, names)
  xx = 0
  print "--- #{label}\n"
  while xx < loh.size
    href = loh[xx]
    names.each_index { |yy|
      print "#{names[yy]}: #{href[names[yy]]}\n"
    }
    xx += 1
  end
  print "---\n\n"
end


def self.file2loh(file)
  loh = []
  coll_hr = Hash.new
  if file.match(/\.csv/i)
    ss = CSV.open(file, 'r')
    # column names
    names = ss.first() # row 1
    
    # Save collection info in columns to the left of c0x.
    collection_data = ss.first() # row 2
    collection_data.each_index { |col_num|
      if names[col_num] == '<c0x>'
        break
      end
      coll_hr[names[col_num]] = collection_data[col_num]
    }

    # Turn the CSV data into a list of hashes.
    # first() is like pop. Finding aid starts in row 3.
    while (collection_data = ss.first())
      rh = Hash.new()
      collection_data.each_index { |col_num|
        rh[names[col_num]] = collection_data[col_num]
      }
      loh.push(rh)
    end
  elsif file.match(/\.xlsx/i)
    ss = Excelx.new(file)
    names = ss.row(1)

    # Headers in row 1, collection data in row 2, finding aid starts in row 3
    
    ss.row(2).each_index { |col_num|
      if names[col_num] == '<c0x>'
        break
      end
      coll_hr[names[col_num]] = ss.row(2)[col_num]
    }

    for row_num in 3..ss.last_row()
      rh = Hash.new()
      ss.row(row_num).each_index { |col_num|
        rh[names[col_num]] = ss.row(row_num)[col_num]
        # The roo code is converting an number into a float, so 1
        # becomes 1.0 which is amusing. Force the number to be a string.
        rh['<c0x>'] = sprintf("%d", rh['<c0x>'])
      }
      loh.push(rh)
    end
  end
  #dumploh(loh, "pre", names)
  return [loh, coll_hr]
end
# dumploh(loh, "pre", names)

def self.work(file)
  
  # Read the spreadsheet file into a list of hashes, process the
  # list of hashes into dsc xml, process the dsc with the outer
  # elements of ead, make sure our output files doesn't exist,
  # write the output.

  print "Processing #{file} ..."

  loh, coll_hr = file2loh(file)
  r_flag, dsc = proc_rows(loh, @cox_t)
  if (r_flag)
    base = File.basename(file,File.extname(file)) 
    new_name = "#{base}.xml"

    # Write/overwrite the xml file name into a hash value for each iteration.
    coll_hr['xml_name'] = new_name

    # coll_hr must be defined and valid for outer_t.
    xml = @outer_t.result(binding())

    if File.exists?(new_name)
      File.rename(new_name, "#{new_name}.bak")
    end
    File.open(new_name, "wb") { |my_xml|
      my_xml.write(xml)
    }
    print " Done.\n"
  else
    print " Error.\n"
  end
end

# Unbuffer output.
STDOUT.sync = true

# _t aka "template"
@outer_t = ERB.new File.new("#{File.dirname(File.expand_path(__FILE__))}/pre_dsc_header_t.erb").read, nil, "%"
@cox_t = ERB.new File.new("#{File.dirname(File.expand_path(__FILE__))}/cox_loop_t.erb").read, nil, "%"


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
        work(file)
      end
    }
  }
else
  # We are processing only one file.
  path = File.dirname(ARGV[0])
  file = File.basename(ARGV[0])
  Dir.chdir(path) {
    work(file)
  }
end


exit
