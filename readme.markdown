### About

Backup script for tumblr using [tumblr4r](http://github.com/tmaeda/tumblr4r). 

Adds a Backup subclass of Tumblr4r's Site class that makes backups 
of posts as well as images (for photo and regular posts)

Outputs to Jekyll-inspired plain text files with YAML metadata in the front matter. To substitute a different backup method, you'd have to change `write_file` as well as `get_existing`

Dependencies: tumblr4r, obviously, and sanitize.

### Usage

Use like this:

     site = Tumblr4r::Backup.new('blogname.tumblr.com')
     site.backup_path = "/path/to/your/backups"
     posts = site.find(:all, :filter=>'none')
     site.make_backup(posts)


### Limitations 

Right now this only grabs 50 most recent posts at a time. If your tumblelog is older than that, this won't figure that out and go back and get those older posts. While I don't personally need, I mostly wrote this to help me learn Ruby and I think the API allows this, so I may add this in the future.
