# Created by Tom Laudeman

# All files of this package are Copyright 2011 University of Virginia

# All files of this package are licensed under the Apache License.
# Licensed under the Apache License Version 2.0 (the "License"); you
# may not use these files except in compliance with the License.  You
# may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.  See the License for the specific language governing
# permissions and limitations under the License.


This package is basically a single Ruby script that reads .csv or
.xlsx with a certain column layout, and creates EAD xml.

<%= dsc %> in pre_dsc_header_t.erb comes from the content hash value
in the list of hashes generated during processing the spread sheet
rows.

Due to the entities and DTD referenced in the EAD XML template, the
following URLs and servers must remain active, and kept up to date.

stylesheet http://ead.lib.virginia.edu/vivaead/published/document.xsl
EAD DTD    http://text.lib.virginia.edu/bin/dtd/eadVIVA/eadVIVA.dtd
logo       http://ead.lib.virginia.edu/vivaead/logos/uva-sc.jpg
conditions http://www.lib.virginia.edu/speccol/vhp/conditions.html
address    http://ead.lib.virginia.edu/vivaead/add_con/uva-sc_address.xml
contact    http://ead.lib.virginia.edu/vivaead/add_con/uva-sc_contact.xml



change notes

x rename render_csv.rb to render_ss.rb, show_csv.rb to show_ss.rb
because both can do more than just csv.

x <ead id="#{coll_hr['num']}">  vui is the num. vui also occurs in file name.

x show_csv.rb add printf max width formatting for name and add ability
  to read xlsx.

Q If an element is empty must we render it as <empty/> or can we use
<empty></empty> ?

A xmllint seems to change empty elements into the self-closing variant.

x add "num" to Accession # in prefercite

x fix both instances of <num> to use collection_num column

x add <head>Conents List</head> as first line of <dcs>

x put sample input and output from "steady" ruby and nokogiri converter into ./steady/

x simple erb text template_1.erb

x copy EADExample.csv to first_example.csv for tab-complete sanity

x show_csv.rb to show csv as name-value pairs where the name is the column name.
