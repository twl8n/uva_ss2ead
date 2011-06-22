#!/usr/bin/env ruby

require 'csv'
require 'rubygems'
require 'csv'
require 'erb'
require 'roo'
require 'find'

names = 1,2,3,4

names.each_index { |xx|
  if names[xx] == 2
    names[xx] = 5
  end
}

names.each { |item|
  puts item
}

exit




# ss = Excelx.new("/home/twl8n/dcs_finding_aids/ContentsSamplesJun10/MSS5295-c.xlsx")
ss = Excelx.new(ARGV[0])

names = ss.row(1)
puts names.class
puts names.size

for row_num in 1..ss.last_row()
  ss.row(row_num).each_index { |col_num|
    # rh['<c0x>'] = sprintf("%d", rh['<c0x>'])

    # The real code doesn't have this silly class test because we
    # never try to convert the column header into an integer.

    if names[col_num] == '<c0x>' && ss.row(row_num)[col_num].class != String
      printf("%s: %d\n", names[col_num], ss.row(row_num)[col_num])
    else
      print "#{names[col_num]}: #{ss.row(row_num)[col_num]}\n"
    end
  }
end

# ss.row(1).each { |cols| puts cols}
