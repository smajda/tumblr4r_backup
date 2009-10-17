### About

Backup script for tumblr using [tumblr4r](http://github.com/tmaeda/tumblr4r). 

Adds a Backup subclass of Tumblr4r's Site class that makes backups 
of posts as well as images (for photo and regular posts)

Outputs to Jekyll-inspired plain text files with YAML metadata in the front matter. To substitute a different backup method, you'd have to change `write_file` as well as `get_existing`

Dependencies: tumblr4r, sanitize.

### Usage

Use like this:

     site = Tumblr4r::Backup.new('blogname.tumblr.com')
     site.backup_path = "/path/to/your/backups"
     site.make_backup

