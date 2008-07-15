module UTorrent  
  class Label < Struct.new(:name, :number)
  end
  
  class TorrentList < Array
    def initialize
      super()
      update!
    end
    
    def [](index)
      if index.is_a? Fixnum
        super(index)
      else
        find{|t| t.hash == index}
      end
    end
    
    def delete(index)
      if index.is_a? Fixnum
        super(index)
      else
        self[]
      end
    end
    
    def search(name)
      name.downcase!
      find_all{|t| t.name.downcase.match(name)}
    end

    def update!
      if @cache_id.nil?
        data = UTorrent::API.req('list=1')
        data = JSON.parse(data.body)
      
        @cache_id = data['torrentc']
        @labels = data['label'].collect do |label|
          Label.new(label[0], label[1])
        end

        data['torrents'].each do |torrent|
          self << Torrent.new(torrent)
        end
      else
        data = UTorrent::API.req("list=1&cid=#{@cache_id}")
        data = JSON.parse(data.body)
        
        @cache_id = data['torrentc']
        
        # delete removed torrents
        data['torrentm'].each do |torrent|
          self.delete_at(torrent) # Hoping this uses #[] to find object
        end
        
        # update/add new torrents
        data['torrentp'].each do |torrent|
          if old_torrent = self[torrent.first]
            old_torrent.update! torrent
          else
            self << Torrent.new(torrent)
          end
        end
      end
    end
  end
  
  class Torrent
    STATUSES = {
      :started => 1, 
      :checking => 2,
      :start_after_check => 4,
      :checked => 8,
      :error => 16,
      :paused => 32,
      :queued => 64,
      :loaded => 128
    }
    
    attr_reader :hash, :name, :size, :downloaded, :uploaded, :upload_speed, 
      :download_speed, :eta, :peers_connected, :peers_total, :seeds_connected,
      :seeds_total, :queue_order, :remaining_bytes
    
    # Can we change queue_order?
    def initialize(torrent)
      @hash, @status, @name, @size, @percent, @downloaded, 
      @uploaded, @ratio, @upload_speed, @download_speed, @eta,
      @label, @peers_connected, @peers_total, @seeds_connected, @seeds_total, 
      @availability, @queue_order, @remaining_bytes = *torrent
    end
    
    def update!(data)
      # data to update the torrent with
    end
    
    # allow performing stuff such as Torrent#checked? or #paused?
    def method_missing(method, *args)
      if method.to_s.downcase =~ /(.*)\?$/
        has_status?($1.to_sym)
      else
        super(method, *args)
      end
    end
    
    # some accessors which need a bit of transformation
    def percent; @percent / 10.0; end
    def ratio; @ratio / 10.0; end
    def availability; (@availability / 65535.0) * 100.0; end
    
    def name=(new_name)
      api_set(:name, new_name)
      @name = new_name
    end
    
    def eta_as_time
      
    end
    
    def files
      @files ||= begin
        files = JSON.parse(UTorrent::API.req("action=getfiles&hash=#{@hash}").body)
        files["files"][1].collect{|f| TorrentFile.new(*f)}
      end
    end
    
    # a torrent is force-started if i t is not "in" the queue, but still running
    def force_started?
      has_status(:started) and not has_status(:queued)
    end
    
    def ==(torrent)
      torrent.hash == @hash
    end
    alias_method :===, :==
    
    def has_status?(status)
      status = STATUSES[status]
      
      (@status & status == 0)
    end
    private :has_status?
    
    class TorrentFile < Struct.new(:name, :size, :downloaded, :priority); end
  end
end
