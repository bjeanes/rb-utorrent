module UTorrent
  class Settings < Hash
    def initialize
      super
      get_data
    end

    def []=(field, value)
      api_set field.to_s => value
      super
    end
    
    private
    def api_set(params)
      query = params.collect{|k,v| "#{k}=#{v}" }.join("&")
      
      UTorrent::API.req("action=setsetting&#{query}")
      true # TODO : make this check the return type of API.req to see if it was successful
    end
    
    def get_data
      settings = UTorrent::API.req('action=getsettings')
      settings = JSON.parse(settings.body)['settings']
      settings.each do |setting|
        value = case setting[1]
        when 0: setting[2].to_i
        when 1: ((setting[2] == 'false') ? false : true)
        when 2: setting[2].to_s
        end
        
        self[setting[0]] = value
      end
    end
  end
end