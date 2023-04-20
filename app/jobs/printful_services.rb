require 'httparty'

class PrintfulServices
  include HTTParty
  base_uri 'https://api.printful.com'

  def initialize(api_key)
    @options = {
      headers: {
        'Authorization' => "Bearer #{api_key}",
        'Content-Type' => 'application/json'
      }
    }
  end

  def upload_image(file_path)
    file = File.open(file_path, 'rb')
    options = @options.dup
    options[:headers].delete('Content-Type')
    options[:body] = { file: file }
    response = self.class.post('/files', options)
    if response.code == 200
      response.parsed_response
    else
      nil
    end
  ensure
    file.close if file
  end

  def check_mockup_task(task_key)
    response = self.class.get("/mockup-generator/task", query: { task_key: task_key }, headers: @options[:headers])

    if response.code == 200
      response.parsed_response
    else
      nil
    end
  end

  def generate_mockup(file_url, placement = 'front')
    body = {
      "variant_ids": [4012, 4013, 4014, 4017, 4018, 4019],
      "format": "jpg",
      "files": [
        {
          "placement": placement,
          "image_url": file_url,
          "position": {
            "area_width": 1800,
            "area_height": 2400,
            "width": 1800,
            "height": 1800,
            "top": 300,
            "left": 0
          }
        }
      ]
    }

    response = self.class.post('/mockup-generator/create-task/71', body: body.to_json, headers: @options[:headers])

    if response.code == 200
      response.parsed_response
    else
      nil
    end
  end
end