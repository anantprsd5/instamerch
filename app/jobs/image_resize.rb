class ImageResize
  class << self
    def resize_image(image_path, new_width: 768, new_height: 768)
      image = Magick::Image.read(image_path).first

      image.change_geometry!("#{new_width}x#{new_height}") do |cols, rows, img|
        resized_image = img.resize(cols, rows)
        output_path = "#{image_path}"
        resized_image.write(output_path)

        output_path
      end
    end

    def generate_tshirt_mockup
      # Replace 'your_api_key_here' with your Printful API key
      printful_service = PrintfulServices.new('<YOUR_API_KEY>')

        result = printful_service.generate_mockup('https://i.ibb.co/kqc4zfB/v1-upscaled-image.png')

        if result
          mockup_url = result['mockup']['url']
          output_file_path = 'path/to/output/image.jpg'

          # Save the mockup image as a JPG file
          File.open(output_file_path, 'wb') do |output_file|
            open(mockup_url) do |input|
              output_file.write(input.read)
            end
          end

          # Do something with the output_file_path, e.g., render the mockup image
        else
          # Handle errors, e.g., show an error message
        end
    end

    def check_progress
      printful_service = PrintfulServices.new('<YOUR_API_KEY>')
      printful_service.check_mockup_task("gt-504391194")
    end


    def dummy_call
      text_data = 'change to imaginary cyberpunk style world'
      image_file = File.open('public/images/1.jpg_resized.jpg', "rb")

      engine_id = "stable-diffusion-768-v2-1"
      api_host = ENV["API_HOST"] || "https://api.stability.ai"
      api_key = ENV["STABILITY_API_KEY"] || '<YOUR_API_KEY>'

      raise "Missing Stability API key." if api_key.nil?

      style_data ||= 'illustration'
      prompt = "#{text_data} in the style of #{style_data}"
      response = HTTParty.post(
        "#{api_host}/v1/generation/#{engine_id}/image-to-image",
        headers: {
          "Accept" => "application/json",
          "Authorization" => "Bearer #{api_key}"
        },
        body: {
          "init_image" => image_file,
          "image_strength" => 0.35,
          "init_image_mode" => "IMAGE_STRENGTH",
          "text_prompts[0][text]" => prompt,
          "cfg_scale" => 7,
          "clip_guidance_preset" => "FAST_BLUE",
          "samples" => 1,
          "steps" => 30,
          "style_preset" => 'photographic'
        },
        debug_output: $stdout
      )
      response["artifacts"].each_with_index do |image, i|
        File.open("img_#{i}.jpg", "wb") do |f|
          f.write(Base64.decode64(image["base64"]))
        end
      end
      return response
    end

    def upscale_image
      engine_id = "esrgan-v1-x2plus"
      api_host = "https://api.stability.ai"
      api_key = '<YOUR_API_KEY>'

      response = HTTParty.post(
        "#{api_host}/v1/generation/#{engine_id}/image-to-image/upscale",
        headers: {
          "accept" => "image/png",
          "authorization" => "bearer #{api_key}"
        },
        body: {
          "image" => File.open("img_0.jpg", "rb"),
          "width" => 1024
        }
      )

      if response.code != 200
        raise "non-200 response: #{response.body}"
      end

      File.write("v1_upscaled_image.png", response.body)
    end

    def get_engines
      api_host = ENV['API_HOST'] || 'https://api.stability.ai'
      url = "#{api_host}/v1/engines/list"

      api_key = '<YOUR_API_KEY>'
      raise "Missing Stability API key." if api_key.nil?

      response = HTTParty.get(url, headers: { "Authorization" => "Bearer #{api_key}" })
      return response
    end
  end
end
