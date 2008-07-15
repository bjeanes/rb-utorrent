module UTorrent
  class API
    class << self
      def connect(host,port,user,pass)
        if @http.nil?
          @http = Net::HTTP.new(host, port)
          @user = user
          @pass = pass
          self.settings # load settings
        end
        
        self
      end
  
      def settings
        @settings ||= UTorrent::Settings.new
      end
  
      def torrents
        @torrents ||= UTorrent::TorrentList.new
      end

      def req(action)
        req = Net::HTTP::Get.new("/gui/?#{action}")
        req.basic_auth @user, @pass
        @http.request(req)
      end
    end
  end
end