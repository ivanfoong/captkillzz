require 'nokogiri'
require 'net/http'
require 'uri'

dir = 'samples'
Dir::mkdir(dir)

the_uri = URI.parse('http://www.sbstransit.com.sg');
1.upto 1000 do |n|
  Net::HTTP.start(the_uri.host, the_uri.port) do |http|
    resp = http.get('/iris3/nextbus.aspx')
    Nokogiri::HTML(resp.body).css('div.jp_subheaders > div > span > img').each do |image|
      image_url = "http://#{the_uri.host}/iris3/#{image.attribute 'src'}"
      puts image_url
      headers = {}
      headers['Host'] = 'www.sbstransit.com.sg'
      #headers['User-Agent'] = 'TODO: Enter Your User-Agent Here'
      #headers['Referer'] = 'http://www.sbstransit.com.sg/iris3/nextbus.aspx'
      #headers['Cache-Control'] = 'max-age=0'
      #headers['Accept'] = '*/*'
      #headers['Accept-Language'] = 'en-us'
      #headers['Accept-Encoding'] = 'gzip, deflate'
      headers['Cookie'] = resp.response['Set-Cookie']
      #headers['Pragma'] = 'no-cache'
      #headers['Connection'] = 'keep-alive'
      image_resp = http.get("/iris3/#{image.attribute 'src'}", headers)
      open("#{dir}/#{n}.jpeg", 'wb') do |file|
        file.write(image_resp.body)
      end
    end
  end
end