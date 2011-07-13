#!/usr/bin/env ruby

# Created by Tom Laudeman

# Copyright 2011 University of Virginia

require 'csv'
require 'rubygems'
require 'csv'
require 'erb'
require 'roo'
require 'find'

# Works as of 1.9
# require_relative 'lib/util'

# Prior to 1.9 do this:
require File.join(File.dirname(__FILE__), 'lib/util')


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
  message = ""
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

    # http://roo.rubyforge.org/rdoc/index.html
    if ss.sheets.length > 1
      print "Using two sheets.\n\n"
      # If we have a second sheet, find out how many rows, then
      # concat each row of sheet[1] onto the corresponding row of
      # sheet[0].
      
      max_row = ss.last_row(sheet=ss.sheets[0])
      if ss.last_row(sheet=ss.sheets[1]) > max_row
        max_row = ss.last_row(sheet=ss.sheets[1])
      end
      for row_num in 1..max_row
        temp_row = ss.row(row_num, sheet=ss.sheets[0])
        temp_row.concat(ss.row(row_num, sheet=ss.sheets[1]))
        data.push(temp_row)
      end
    else 
      print "Using one sheet.\n\n"
      for row_num in 1..ss.last_row()
        data.push(ss.row(row_num))
      end
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
