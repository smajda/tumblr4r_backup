require 'rubygems'
gem 'tumblr4r', '>= 0.7.2' # requires 0.7.2's photoset support
require 'tumblr4r'
require 'fileutils'
require 'open-uri'
require 'logger'

module Tumblr4r
=begin
  Adds a Backup subclass of Tumblr4r's Site class that makes backups 
  of posts as well as images (for photo and regular posts)

  Outputs a Jekyll-inspired YAML formatted plain text files. To substitute 
  a different backup method, you'd have to change write_file as well as
  get_existing

  file/directory structure:
  /2009-09-10-post-slug.markdown
  /2009-09-10-post-slug/image.jpg

  file format:
    ---
    title: 
    type: 
    date:
    post_id:
    link:
    ---
    post content

  Use like this:
  site = Tumblr4r::Backup.new('blogname.tumblr.com')
  site.backup_path = "/path/to/your/backups"
  posts = site.find(:all, :filter=>'none')
  site.make_backup(posts)
=end

  class Backup < Site
    attr_accessor :backup_path

    def get_existing
      # get array of post_ids for posts already backed up
      existing = []
      Dir["#{@backup_path}/*.markdown"].each do |f|
        postmeta = YAML.load_file(f)
        existing.push(postmeta["id"])
      end
      return existing 
    end

    def get_myslug(p)
      slugdate = Time.at(p.unix_timestamp).strftime("%Y-%m-%d")
      slugtitle = p.url_with_slug.slice(/[^\/]+$/)
      return myslug = "#{slugdate}-#{slugtitle}"
    end

    def trim_title(s, max = 55)
      if s.length > max
        s = s.slice(0,max).strip + "..."
      end
      return s
    end

    def extract_image_urls(s)
      # need to match markdown and html images
      img_mkd = /!\[.*\]\(([^"\)\ ]+)/
      img_html = /<img[^>]+src=['"]([^'"]+)/

      imgs = []

      # get markdown images
      s.scan(img_mkd).each do |m|
        imgs.push(m[0])
      end

      # get html images
      s.scan(img_html).each do |m|
        imgs.push(m[0])
      end

      return imgs
    end


    def get_content(p)
      content = {}

      case p.type
      when "regular"
        content[:body] = p.regular_body
        content[:title] = if p.regular_title.empty?
                            trim_title(p.regular_body)  
                          else 
                            p.regular_title
                          end
        content[:media] = extract_image_urls(content[:body])

      when "link"
        content[:title] = p.link_text.strip
        content[:body] = "[#{p.link_text}](#{p.link_url})\n\n#{p.link_description}\n"

      when "quote"
        content[:title] = trim_title(p.quote_text)
        content[:body] = "#{p.quote_text}\n\n---#{p.quote_source}"

      when "photo"
        content[:title] = trim_title(p.photo_caption)
        # create media array, test for photoset
        content[:media] = []
        if p.photoset.empty?
          content[:media].push(p.photo_url)
        else
          p.photoset.each do |url|
            content[:media].push(url)
          end
        end
        # create body, single images or photoset
        content[:body] = "#{p.photo_caption}\n\n"
        if content[:media].length > 1
          content[:media].each { |url| content[:body] << "#{url}\n" }
        else
          content[:body] << p.photo_url
        end

      when "audio"
        content[:title] = trim_title(p.audio_caption)
        content[:body] = "#{p.audio_caption}\n\nsource: #{p.audio_player}"

      when "video"
        content[:title] = trim_title(p.video_caption)
        content[:body] = "#{p.video_caption}\n\nsource: #{p.video_source}\n\n#{p.video_player}"

      end

      # check for empty title and make it post_id
      if (!content[:title] || content[:title].empty?)
        content[:title] = p.post_id
      end
        
      return content
    end

    def get_media(bp)
      # grab sources in bp[:media]
      # and download files & rename and place them accordingly
      
      # create directory
      media_dir = "#{@backup_path}/#{bp[:myslug]}"
      if (!File.directory?(media_dir) && !bp[:content][:media].empty? )
        FileUtils::mkdir(media_dir)
      end

      # iterate through urls, get the files
      bp[:content][:media].each do |url|
        unless url.empty? 
          filename = url.slice(/[^\/]+$/)
          filename = "#{media_dir}/#{filename}"
          file = open(filename, 'w')
          file.write(open(url).read)
          file.close
        end
      end
    end


    def write_file(bp)
      filename = "#{@backup_path}/#{bp[:myslug]}.markdown"
      
      # build file content
      filecontent  = "---\n" ##
      filecontent << "title: \"#{bp[:title]}\"\n" ##
      filecontent << "type: #{bp[:type]}\n" ##
      filecontent << "date: \"#{bp[:date]}\"\n" ##
      filecontent << "id: #{bp[:post_id]}\n" ##
      filecontent << "link: \"#{bp[:link]}\"\n" ##
      filecontent << "---\n" ##
      filecontent << "#{bp[:body]}\n" ##
      
      # write to file
      File::open(filename, 'w') do |file|
        file << filecontent
      end
    end

    def make_backup(posts)
      @posts = posts
      existing = get_existing
      @posts.each do |p|
        # if post_id isn't in existing, make backup
        unless existing.include?(p.post_id)
          # backup data in a hash, 'bp'
          bp = {}
          
          bp[:myslug] = get_myslug(p)

          bp[:content] = get_content(p)
          bp[:title] = bp[:content][:title].to_s.gsub('"','\"')
          bp[:body] = bp[:content][:body]
          bp[:media] = bp[:content][:media]

          bp[:date] = p.date
          bp[:type] = p.type
          bp[:link] = p.url_with_slug
          bp[:post_id] = p.post_id
         
          # get any media
          if bp[:content][:media]
            get_media(bp)
          end

          # write the file
          write_file(bp)

          # log the backup
          @logger.info("Backed up \"#{bp[:title]}\"")
        end
      end
    end

  end
end
