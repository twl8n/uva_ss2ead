#!/usr/bin/env ruby

require 'csv'
# require 'erb'

# ["==", "===", "=~", "__id__", "__send__", "all?", "any?", "class",
# "clone", "close", "close_on_terminate", "collect", "count", "cycle",
# "detect", "display", "drop", "drop_while", "dup", "each",
# "each_cons", "each_slice", "each_with_index", "entries",
# "enum_cons", "enum_for", "enum_slice", "enum_with_index", "eql?",
# "equal?", "extend", "find", "find_all", "find_index", "first",
# "freeze", "frozen?", "grep", "group_by", "hash", "id", "include?",
# "inject", "inspect", "instance_eval", "instance_exec",
# "instance_of?", "instance_variable_defined?",
# "instance_variable_get", "instance_variable_set",
# "instance_variables", "is_a?", "kind_of?", "map", "max", "max_by",
# "member?", "method", "methods", "min", "min_by", "minmax",
# "minmax_by", "nil?", "none?", "object_id", "one?", "partition",
# "private_methods", "protected_methods", "public_methods", "reduce",
# "reject", "respond_to?", "reverse_each", "select", "send", "shift",
# "singleton_methods", "sort", "sort_by", "taint", "tainted?", "take",
# "take_while", "tap", "to_a", "to_enum", "to_s", "type", "untaint",
# "zip"]


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
