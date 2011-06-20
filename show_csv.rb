#!/usr/bin/env ruby

require 'csv'
require 'rubygems'
require 'csv'
require 'erb'
require 'roo'
require 'find'

def self.dumploh(loh, label, names)
  xx = 0
  max_nsize = 0
  names.each { |item|
    if (item.size > max_nsize)
      max_nsize = item.size
    end
  }
  print "--- #{label}\n"
  while xx < loh.size
    href = loh[xx]
    names.each_index { |yy|
      fmt = "%+#{max_nsize}.#{max_nsize}s"
      printf("%02d %02d #{fmt}: %s\n", xx, yy, names[yy], href[names[yy]])
    }
    print "\n"
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
    
    if (special_row_2)
      # Save collection info in columns to the left of c0x.
      collection_data = ss.first() # row 2
      collection_data.each_index { |col_num|
        # Only process data columns before <c0x>. 
        if names[col_num] == '<c0x>'
          break
        end
        coll_hr[names[col_num]] = collection_data[col_num]
      }
    end
      
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
    
    if (special_row_2)
      ss.row(2).each_index { |col_num|
        if names[col_num] == '<c0x>'
          break
        end
        coll_hr[names[col_num]] = ss.row(2)[col_num]
        print "collection  #{names[col_num]}: #{coll_hr[names[col_num]]}\n"
      }
    end

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
  dumploh(loh, "pre", names)
  return [loh, coll_hr, names]
end

# Unbuffer output.
STDOUT.sync = true

print "starting\n"
loh, coll_hr, names = file2loh(ARGV[0])

# loh.each { |href|
  
#   names.each_index  { |xx|
#     print "#{names[xx]}: (#{href.object_id()}) #{href[names[xx]]}\n"
#   }

# }

if false
  var = CSV.open(ARGV[0], 'r')
  
  col_names = var.first()

  # puts var.public_methods.sort.inspect

  if true
    var.collect.each_with_index { |row,yy|
      
      col_names.each_with_index { |name,xx|
        
        print "#{yy} #{name}: #{row[xx]}\n"
        
        # row.each_with_index { |cell,xx|
        #   print "#{yy} #{col_names[xx]}: #{cell}\n"
        # }
      }
      print "\n"
    }
  end

  #template = ERB.new File.new("simple_1_t.erb").read, nil, "%"
  #print template.result(binding)
end
