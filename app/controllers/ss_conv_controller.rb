
require 'rubygems'
require 'csv'
require 'roo'
require 'find'
require 'util' # our local utility methods

Rmatic_db = "rmatic.db"
Msg_schema = "msg_schema.sql"
Orig = "/home/twl8n/dcs_finding_aids"

class SsConvController < ApplicationController

  # constants and config?
  # any admin functions?
  # Add download functions.

  def upload
    # post = save_file(params[:upload], params[:uuid].to_s())
    upload = params[:upload]
    @mdo = Msg_dohicky.new(get_remote_addr, "/home/twl8n/uva_ss2ead")
  
    if (upload.to_s.empty?)
      @mdo.set_message("No file name so nothing was uploaded.", true)
      redirect_to :action => 'index'
      return
    end

    name =  upload.original_filename
    base_name = File.basename(name)

    # Cleanse bad chars from file names.
    base_name.gsub!(/[^A-Za-z0-9\-_\.]/, '_')
    save_dir = Orig
    dir_label = "origin directory"

    if (! File.exists?(save_dir))
      @mdo.set_message("Directory #{save_dir} does not exist. File not saved.", true)
      redirect_to :action => 'index'
      return 
    end

    # Create the full file path
    # path = File.join(directory, name)
    # write the file
    File.open("#{save_dir}/#{base_name}", "wb") { |myupload|
      myupload.write(upload.read)
    }
    @mdo.set_message("File #{base_name} has been uploaded to #{dir_label}.", true)

    redirect_to :action => 'index'
  end

  def show_xml
    # View am xml file in the browser
    xml_fname  = params[:xml_fname]
    output_type = params[:type]
    @mdo = Msg_dohicky.new(get_remote_addr, "/home/twl8n/uva_ss2ead")

    # Process ss_fname through File to untaint
    xml_ext = File.extname(xml_fname)
    xml_base = File.basename(xml_fname, xml_ext)
    xml_full_fname = Orig + "/" + xml_base + xml_ext
    if File.exists?(xml_full_fname)
      if output_type == 'html'
        # Firefox, Safari, and Chrome can't do the XML inline. Rather
        # than figuring out why, just run it through xsltproc to create
        # an html file. Create the html every time, on the fly so we
        # don't have stale data.
        html_fname = xml_base + ".html"
        html_full_fname = Orig + '/' + html_fname
        `xsltproc #{xml_full_fname} > #{html_full_fname}`
        @text = IO.read("#{html_full_fname}")
        send_data(@text,
                  :filename => html_fname,
                  :type => "text/html",
                  :disposition => "inline")
      else
        @text = IO.read("#{xml_full_fname}")
        send_data(@text,
                  :filename => xml_fname,
                  :type => "text/plain",
                  :disposition => "inline")
        
      end
    else
      @mdo.set_message("Cannot find xml file #{xml_full_fname}", true) #append
      redirect_to :action => 'index'
    end
  end

  def show_ss
    # View a spreadsheet in name/value line mode in the web browser
    @mdo = Msg_dohicky.new(get_remote_addr, "/home/twl8n/uva_ss2ead")

    ss_name  = params[:ss_name]
    # Process ss_name through File to untaint
    ss_ext = File.extname(ss_name)
    ss_base = File.basename(ss_name, ss_ext)
    ss_full_name = Orig + "/" + ss_base + ss_ext
    if File.exists?(ss_full_name)
      @ss_text = "Viewing #{ss_full_name}\n"
      @ss_text.concat(`./show_ss.rb #{ss_full_name}`)
    else
      @ss_text = "Can' find #{ss_full_name}\n"
    end
    @mdo.set_message("Viewing successful", true) #append
    @message = @mdo.get_message()
    @mdo.set_message("", false) # clear the message
  end

  def index
    # file report / list

    @mdo = Msg_dohicky.new(get_remote_addr, "/home/twl8n/uva_ss2ead")

    @f_info = [] 
    bgcolor = '#EEEDFD'
    color_toggle = true

    orig_ss_list = []
    Find.find(Orig) { |file|
      # Skip . .. and files that aren't .csv or .xlsx
      if file.match(/^\.[\/]*$/) || ! File.extname(file).match(/csv|xlsx/i)
        next
      end

      if File.directory?(file)
        # Don't descend into directories.
        Find.prune()
      else
        orig_ss_list.push(file)
      end
    }
    
    orig_ss_list.sort.each { |file|
      rh = Hash.new
      rh[:orig] = File.basename(file)
      path = File.dirname(file)
      rh[:xml_fname] = "#{File.basename(file, File.extname(file))}.xml"
      rh[:xml_full_name] = "#{path}/#{rh[:xml_fname]}"
      
      if File.exists?(rh[:xml_full_name])
        rh[:xml_exists] = true
        rh[:xml_mtime] = File.new(rh[:xml_full_name]).mtime
      else
        rh[:xml_exists] = false
      end

      if (color_toggle)
        color_toggle = false
      else
        color_toggle = true
        rh[:bgcolor] = bgcolor
      end
      loh, coll_hr = Ss_converter.file2loh(file)
      
      # Copy the collection hash values into rh to make them visble to
      # the web page.

      coll_hr.keys.each { |key|
        rh[key] = coll_hr[key]
      }
      @f_info.push(rh);
    }
    @message = @mdo.get_message()
    @mdo.set_message("", false) # clear the message
  end

  def convert_ss
    # run render
    ss_name  = params[:ss_name]
    @mdo = Msg_dohicky.new(get_remote_addr, "/home/twl8n/uva_ss2ead")

    # Process ss_name through File to untaint
    ss_ext = File.extname(ss_name)
    ss_base = File.basename(ss_name, ss_ext)
    ss_full_name = Orig + "/" + ss_base + ss_ext
    if File.exists?(ss_full_name)
      Ss_converter.convert_one(ss_full_name, @mdo)
    else
      @mdo.set_message("Error: Cannot find #{ss_full_name}", true) #append
    end
    redirect_to :action => 'index'
  end

end
