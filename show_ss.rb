#!/usr/bin/env ruby

# Created by Tom Laudeman

# Copyright 2011 University of Virginia

require 'csv'
require 'rubygems'
require 'csv'
require 'erb'
require 'roo'
require 'find'
require 'lib/util'

# def self.dumploh(loh, label, names)
#   xx = 0
#   max_nsize = 0
#   names.each { |item|
#     if (item.size > max_nsize)
#       max_nsize = item.size
#     end
#   }

#   while xx < loh.size
#     href = loh[xx]
#     names.each_index { |yy|
#       fmt = "%+#{max_nsize}.#{max_nsize}s"
#       # Show row and col numbers as one-based since they are counting
#       # numbers, not array indices.
#       printf("%02d %02d #{fmt}: %s\n", xx+1, yy+1, names[yy], href[names[yy]])
#     }
#     print "\n"
#     xx += 1
#   end

# end

def self.fix_col_names(names)
  names.each_index { |xx|
    if names[xx].eql?('<c0x>')
      names[xx] = 'component'
      break;
    end
  }
  return names
end

def self.file2loh(file)
  cm_flag = false
  special_row_2 = false
  loh = []
  coll_hr = Hash.new
  data = []
  if file.match(/\.csv/i)
    ss = CSV.open(file, 'r')
    while (row = ss.first()) 
      data.push(row)
    end
  elsif file.match(/\.xlsx/i)
    ss = Excelx.new(file)
    for row_num in 1..ss.last_row()
      ss.row(row_num).each
      data.push(ss.row(row_num))
    end
  end
  # Headers in [0] (row 1), collection data in [1] (row 2), finding
  # aid starts in [2] (row 3)
  
  names = data[0]
  names = fix_col_names(names)

  for xx_dex in 1..(data.size-1)
    rh = Hash.new()
    row = data[xx_dex]
    row.each_index { |col_num|
      rh[names[col_num]] = row[col_num]
    }
    rh = Ss_converter.fix_our_hash(rh)
    if ! cm_flag &&
        ! rh['container'].empty? &&
        ! C_list.member?(rh['container'].downcase)
      cm_flag = true
      message.concat("#{rh['num']} containter value \"#{rh['container']}\" not in list\n")
    end
    loh.push(rh)
  end
  Ss_converter.dumploh(loh, "pre", names)
  return [loh, coll_hr, names]
end

# Unbuffer output.
STDOUT.sync = true

loh, coll_hr, names = file2loh(ARGV[0])
