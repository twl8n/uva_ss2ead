
require 'erb'
require 'rubygems'
require 'csv'
require 'roo'
require 'find'
require 'sqlite3'
# Buggy don't use. Incorrectly changes &#x2013; to &amp;#x2013;
# require 'escape'

load File.join(File.dirname(__FILE__),'../config/configure.rb')

class Ss_converter

  def initialize(file, mdo, quiet_flag)

    # quiet_flag controls whether or not we get all the "deprecated
    # column" messages.

    @file = file
    @mdo = mdo
    @dk_flags = Hash.new
    @quiet_flag = quiet_flag
  end

  def proc_rows(loh, cox_t)
    # This method does the real work of changing a flat list (of
    # hashes) into nested XML text. The results array is stack and
    # stack[0] is the special, final accumulator of everything that
    # happens. Each child writes into the 'content' key of the
    # parent. Each entry renders itself along with its 'content' into
    # it's parent 'content' key. The final parent is stack[0] which
    # renders itself and returns.

    content = ""
    stack = []
    rh = Hash.new()
    rh['content'] = ""
    rh['component'] = 0 # special zero level collects all content
    rh['yy'] = -1 # weird, but only a label
    stack.push(rh)

    xx = 0
    while xx < loh.size
      href = loh[xx]
      href['yy'] = xx
      cox = href['component']

      # Increment not before we forget. Do not use xx below this line.
      xx += 1

      if (cox.to_i < 1)
        msg = "Warning: Row #{xx+1} of #@file must have a valid >= 1 component. Skipping."
        print "#{msg}\n"
        @mdo.set_message(msg, true)
        # We don't want to return on empty records. This sanity check
        # could get more specific, but mostly just issue a warning and
        # not do anything more on this record. Do not simply "next"
        # here because there could be other stuff after this
        # statement. (There isn't because by breaking structured
        # programming tennets I created a bug.)  Core principles of
        # structured progamming apply here.

        # return [false,""]
      else
        href['content'] = ""
        
        # Always try to prune the stack. Always push the new hash ref onto
        # the stack. Hash refs will stay on the stack as long as the depth
        # increases. As soon as depth decreases or is the same, the stack
        # is pruned. The last href on the stack always accumulates results.

        # The template requires vars content, old_href.

        while cox.to_i <= stack.last['component'].to_i
          old_href = stack.pop()
          content = old_href['content']
          var = cox_t.result(binding())
          stack.last['content'].concat( var )
        end
        stack.push(href)
      end
    end

    while stack.size > 1
      old_href = stack.pop()
      content = old_href['content']
      var = cox_t.result(binding())
      stack.last['content'].concat( var )
    end
    #abort "<dsc>#{stack.last['content']}\n</dsc>\n"
    return [true,stack.last['content']]
  end

  def convert_one()
    # _t aka "template"
    @outer_t = ERB.new File.new("#{Home}/pre_dsc_header_t.erb").read, nil, "%"
    @cox_t = ERB.new File.new("#{Home}/cox_loop_t.erb").read, nil, "%"

    # Read the spreadsheet @file into a list of hashes, process the
    # list of hashes into dsc xml, process the dsc with the outer
    # elements of ead, make sure our output files doesn't exist,
    # write the output.

    loh, coll_hr, f2l_message, names_unused = file2loh()
    r_flag, dsc = proc_rows(loh, @cox_t)
    if (r_flag)
      base = File.basename(@file,File.extname(@file)) 
      path = File.dirname(@file)
      new_name = "#{path}/#{base}.xml"

      # Write/overwrite the xml @file name into a hash value for each
      # iteration.  This goes into the output and needs to be the name
      # without the path.
      coll_hr['xml_name'] = "#{base}.xml" # new_name

      # coll_hr must be defined and valid for outer_t.
      xml_output = @outer_t.result(binding())

      message = "writing #{new_name}\n"
      
      File.open(new_name, "wb") { |my_xml|
        my_xml.write(xml_output)
      }
      
      message.concat("Complete: processing #{@file}")
    else
      message = "Error: processing #{@file}"
    end

    @mdo.set_message(message, true)
    if ! f2l_message.empty?
      @mdo.set_message(f2l_message, true)
      message.concat(f2l_message)
    end
    return message
  end

  def self.prloh(loh, label)
    # Debug the list of hashes
    xx = 0
    print "--- #{label}\n"
    while xx < loh.size
      href = loh[xx]
      if true # href['component'] == 1
        print "#{href['yy']}: #{href['component']}"
        print "con:#{href['content']}\n"
      end
      xx += 1
    end
    print "---\n\n"
  end

  def self.dumploh(loh, label, names)

    # We need an array names because hash keys are not ordered.

    xx = 0
    max_nsize = 0
    names.each { |item|
      if (item.size > max_nsize)
        max_nsize = item.size
      end
    }

    # print "mn: #{max_nsize} ls: #{loh.size}\n"
    
    while xx < loh.size
      href = loh[xx]
      names.each_index { |yy|
        fmt = "%+#{max_nsize}.#{max_nsize}s"
        # Show row and col numbers as one-based since they are counting
        # numbers, not array indices.
        printf("%02d %02d #{fmt}: %s\n", xx+1, yy+1, names[yy], href[names[yy]])
      }
      print "\n"
      xx += 1
    end

  end

  def fix_col_names(names)
    # Over time column names have changed. Here we fix any legacy
    # names.
    names.each_index { |xx|
      if names[xx] == '<c0x>'
        names[xx] = 'component'
        break;
      end
    }
    return names
  end


  def file2loh()
    file = @file
    if ! @quiet_flag
      print "working on #{file}\n"
      @mdo.set_message("working on #{file}", true)
    end
    message = ""
    cm_flag = false
    loh = []
    coll_hr = Hash.new
    data = []
    if file.match(/\.csv/i)
      print "Error: CSV file #{file} not supported\n"
      exit;
    end
    if ! file.match(/\.xlsx/i)
      print "Error: file #{file} supported\n"
      exit;
    end
    ss = Excelx.new(file)
      
    # http://roo.rubyforge.org/rdoc/index.html
    
    # We must have 2 sheets.
    
    # We must have at least 2 rows: column names and a row of data. It is
    # possible (I suppose) that the data row is all empty.
    max_row = 2
    if ss.last_row(sheet=ss.sheets[1]) > max_row
      max_row = ss.last_row(sheet=ss.sheets[1])
    end
    
    # Headers in row 1 of both sheets. Collection data in sheet[0] row
    # 2. Component data on sheet[1] starting in row 2.

    coll_names = ss.row(1, sheet=ss.sheets[0])
    coll_names = fix_col_names(coll_names)

    cont_names = ss.row(1, sheet=ss.sheets[1])
    cont_names = fix_col_names(cont_names)
    
    all_names = []
    all_names.concat(coll_names)
    all_names.concat(cont_names)

    # Populate coll_hr the collection hash ref (actually a hash, but I
    # like "hr" for historical reasons).

    # coll_data_row = 1
    # data[coll_data_row].each_index { |col_num|
    #   if names[col_num] == 'component'
    #     break
    #   end
    #   coll_hr[names[col_num]] = data[coll_data_row][col_num]
    #   print "ch: #{coll_hr[names[col_num]]}\n"
    # }

    ss.row(2, sheet=ss.sheets[0]).each_index { |col_num|
      coll_hr[coll_names[col_num]] = ss.row(2, sheet=ss.sheets[0])[col_num]
    }

    coll_hr = fix_our_hash(coll_hr, "coll_hr: #{file}")

    # for xx_dex in 2..(data.size-1)
    for xx_dex in 2..(max_row)
      rh = Hash.new()
      # row = data[xx_dex]
      row = ss.row(xx_dex, sheet=ss.sheets[1])
      row.each_index { |col_num|
        rh[cont_names[col_num]] = row[col_num]
      }
      rh = fix_our_hash(rh, "rh: #{file}")
      if ! cm_flag &&
          ! rh['container'].empty? &&
          ! C_list.member?(rh['container'].downcase)
        cm_flag = true
        message.concat("#{rh['num']} containter value \"#{rh['container']}\" not in list\n")
      end
      # print "rh: #{rh}\n"
      loh.push(rh)
    end
    # dumploh(loh, "pre", names)
    # print "msg: #{message}\n"
    return [loh, coll_hr, message, all_names]
  end

  def newline_to_p(var)
    # I'm not sure the .to_s is sensible. Only strings should be
    # passed in here, but we'll force .to_s just in case.

    # Double new is <p>, but the fields we're talking about already
    # have <p>, so we actually use "closing p newline opening p".

    # Singles are replaced using a negative look ahead assertion so we
    # skip the newlines we just added before <p> tags.

    if ! var.to_s.empty?
      var = var.to_s.gsub(/\n{2}/ms, "<\/p>\n<p>")
      var = var.to_s.gsub(/\n(?!<p>)/ms, "<br/>")
    end
    return var
  end
  
  def fix_our_hash(my_h, msg)
    # This is where we fix systematic issues with data. my_h is a
    # hash.
    
    # num and component strangely convert to strings with floating
    # point values even though celltype() says they are strings. We
    # have to convert them into strings containing an
    # integer. Oddly, other columns such as "c_level" and "guide
    # date" are type "float" even though they only contain
    # strings. Either the Roo gem or Excel are confused. Regardless,
    # fix the data here.

    my_h['num'] = unintegerize(my_h['num'])
    my_h['component'] = unintegerize(my_h['component'])
    my_h['unitdate'] = unintegerize(my_h['unitdate'])
    
    if ! defined?(my_h['container']) || my_h['container'].to_s.empty?
      my_h['container'] = ""
    end
    
    if ! @quiet_flag
      deprecated_keys = ['c0x level','collection date', 'acqinfo']
      deprecated_keys.each { |dkey|
        if my_h.has_key?(dkey) && ! @dk_flags.has_key?(dkey)
          @dk_flags[dkey] = 1
          tmp_msg = "Warning: have deprecated column \'#{dkey}\' msg: #{msg}"
          print "#{tmp_msg}\n"
          @mdo.set_message(tmp_msg, true)
        end
      }
    end

    # If c_level is not 'series', set a flag that will be used in
    # the .erb to remove the label attribute.
    if my_h['c_level'].to_s.match(/series/)
      my_h['series_flag'] = true
    end
    
    my_h['container_label'] = my_h['container'].capitalize
    my_h['container_type'] = my_h['container'].downcase

    my_h['container_flag'] = true
    if my_h['container'].empty?
      my_h['container_flag'] = false
    end

    # http://rubydoc.info/gems/escape/0.0.4/frames

    # Escape.html_text escapes a string appropriate for HTML text
    # using character references.
    
    # It escapes 3 characters:
    #       '&' to '&amp;'
    #       '<' to '&lt;'
    #       '>' to '&gt;'
    #  Escape.html_text("abc") #=> "abc"
    #  Escape.html_text("a & b < c > d") #=> "a &amp; b &lt; c &gt; d"
    
    # This function is not appropriate for escaping HTML element
    # attribute because quotes are not escaped.

    my_h.keys.each { |key|
      if my_h[key].class == String
        my_h[key] = Escape.html_text(my_h[key])
      end
    }
      
    # I'm pretty sure we have to put this after the Escape.html_text
    # otherwise our conversions will be escaped.

    my_h['bioghist'] = newline_to_p(my_h['bioghist'])
    my_h['guide_scope'] = newline_to_p(my_h['guide_scope'])
    my_h['access_restrict'] = newline_to_p(my_h['access_restrict'])
    my_h['use_restrict']  = newline_to_p(my_h['use_restrict'])
    my_h['process_info']  = newline_to_p(my_h['process_info'])
    my_h['related_mats']  = newline_to_p(my_h['related_mats'])
    my_h['arrangement']  = newline_to_p(my_h['arrangement'])
    my_h['scopecontent']  = newline_to_p(my_h['scopecontent'])

    # un-escape <list>, at least in guide_scope
    # my_h['guide_scope'].gsub!(/&lt;list&gt;/, "<list>")
    # my_h['guide_scope'].gsub!(/&lt;\/list&gt;/, "</list>")
    

    return my_h
  end

  def unintegerize(ivar)
    ivar = ivar.to_s;
    # If ivar contains all digits, or digits and dot followed by a zero
    # then run it through sprintf to convert to string form as an integer.

    # We want strings, so use sprintf() which returns a string.
    # to_i() returns a Fixnum. Could use .to_i.to_s but that seems
    # silly, where sprintf() is for serious programmers. sprintf()
    # rounds, but in this cas we have onl y numbers with .0 on the end
    # like 1.0, 4030.0, etc.

    if ivar.match(/^\d+(\.0)*$/)
      ivar = sprintf("%.0f", ivar)
    end
    if ivar == '0'
      ivar = ""
    end
    return ivar
  end

end # class Ss_converter

def container_list

end

def get_remote_host
  return request.remote_host
end

def get_remote_addr
  if defined?(request) && request.to_s.length > 0
    return request.remote_addr
  else
    # The pid
    return $$
  end
end

def my_server_port
  return request.server_port
end

class Msg_dohicky

  # Set and get messages to show in web pages. Messages are saved in a
  # database so they'll survive page loads. We don't have logins so the
  # user_id is the remote ip address.
  
  # The messages handled by Msg_dohicky are the Rails web page status
  # messages handled on a per-user / per-session basis. There is only
  # one Rmatic_db per Rubymatica instance. This is used primarily in
  # hello_world_controller.rb.
  
  @fn = ""
  @user_id = ""

  def initialize(generic_id, msg_path)
    @user_id = generic_id
    @fn = "#{msg_path}/#{Rmatic_db}"
    
    # If the db doesn't exist, create it.

    if (! File.size?(@fn))
      db = SQLite3::Database.new(@fn)
      db.busy_timeout=1000 # milliseconds?
      db.transaction(:immediate)
      sql_source = "#{msg_path}/#{Msg_schema}"
      db.execute_batch(IO.read(sql_source))
      db.commit
      db.close
    end
  end
  
  # Save a message for a given user. If flag (concat_flag) is false,
  # remove all old messages. True to add, concat a new message record.
  
  def set_message(str,flag)
    db = SQLite3::Database.new(@fn)
    db.busy_timeout=1000 # milliseconds?
    if (! flag)
      db.transaction(:immediate)
      stmt = db.prepare("delete from msg where user_id=?")
      stmt.execute(@user_id);
      stmt.close
      db.commit
    end

    db.transaction(:immediate)
    stmt = db.prepare("insert into msg (user_id,msg_text) values (?,?)")
    stmt.execute(@user_id, str);
    stmt.close
    db.commit
    db.close();
  end

  # Get all the messages for a given user. Notice that rather than
  # returning a list of hash, we concat the list elements into a
  # single string.

  def get_message
    db = SQLite3::Database.new(@fn)
    db.busy_timeout=1000 # milliseconds?
    db.transaction(:immediate)
    stmt = db.prepare("select user_id,msg_text from msg where user_id = ? order by id")
    ps = Proc_sql.new();
    stmt.execute(@user_id){ |rs|
      ps.chew(rs)
    }
    stmt.close
    db.close()
    results = ""
    ps.loh.each { |hr|
      results.concat("\n#{hr['msg_text']}")
    }
    return results
  end
end # class Msg_dohicky


class Proc_sql
  # Process (chew) sql records into a list of hash. Called in an
  # execute2() loop. Ruby doesn't really know how to return SQL results
  # as a list of hash, so we need this helper method to create a
  # list-of-hash. You'll see Proc_sql all over where we pull back some
  # data and send that data off to a Rails erb to be looped through,
  # usually as table tr tags.
  
  def initialize
    @columns = []
    @loh = []
  end

  def loh
    if (@loh.length>0)
      return @loh
    else
      return [{'msg' => "n/a", 'date' => 'now'}];
    end
  end

  # Initially I thought I was sending this an array from db.execute2
  # which sends the row names as the first record. However, using
  # db.prepare we use stmt.execute (there is no execute2 for
  # statements), so we're getting a ResultSet on which we'll use the
  # columns() method to get column names.

  # It makes sense to each through the result set here. The calling
  # code is cleaner.

  def chew(rset)
    if (@columns.length == 0 )
      @columns = rset.columns;
    end
    rset.each { |row|
      rh = Hash.new();
      @columns.each_index { |xx|
        rh[@columns[xx]] = row[xx];
      }
      @loh.push(rh);
    }
  end
end # class Proc_sql

