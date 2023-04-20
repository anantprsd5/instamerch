class DirectStyle
  class << self
    def perform(task_id)
      resize_image(task_id)
      stylize_image(task_id)
      upscale_image(task_id)
      mockups = print_on_tshirt(task_id)
      delete_task_data_json_file(task_id)
      delete_image_file(task_id)
      save_final_results_to_file(task_id, { "main" => mockups })
    end

    def save_final_results_to_file(task_id, task_data)
      File.open("#{task_id}_result.json", 'w') do |file|
        file.write(task_data.to_json)
      end
    end

    def delete_image_file(task_id)
      file_path = "public/images/#{task_id}.jpg"
      File.delete(file_path) if File.exist?(file_path)
      File.delete("#{task_id}.jpg") if File.exist?(file_path)
    end

    def print_on_tshirt(task_id)
      printful_service = PrintfulServices.new('IbjsKZFmPS4Vz7ajAnchREdlGnTlYHN7KHcpmE1O')
      result = printful_service.generate_mockup("https://instamerch-backend.onrender.com/images/#{task_id}.jpg")
      task_key = result.dig("result", "task_key")
      mockups = []
      loop do
        sleep(5) # Wait for 5 seconds
        response = printful_service.check_mockup_task(task_key)
        status = response.dig("result", "status")
        break if response.dig("result", "status") == "failed"

        if status == 'completed'
          response.dig("result", "mockups").each do |mockup|
            mockups << mockup["mockup_url"]
            mockup["extra"].each do |ex|
              mockups << ex["url"]
            end
          end
        end
      end
      return mockups
    end

    def resize_image(task_id)
      task_data = load_task_data_from_json_file(task_id)
      byebug
      decode_base64_image(task_data["image"], "#{task_id}.jpg")
      ImageResize.resize_image("#{task_id}.jpg")
    end

    def decode_base64_image(base64_image, output_file_path)
      decoded_image = Base64.decode64(base64_image)
      File.open(output_file_path, 'wb') do |file|
        file.write(decoded_image)
      end
    end

    def stylize_image(task_id)
      task_data = load_task_data_from_json_file(task_id)
      text_data = task_data['text']
      style_data = task_data['style']
      image_file = File.open("#{task_id}.jpg", "rb")
      engine_id = "stable-diffusion-768-v2-1"
      api_host = "https://api.stability.ai"
      api_key = 'sk-N0lLDwQZlSzzKFQ1CKgiXVbi0AUmXaDW97e3LWbcJcb9lmd8'
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
          "text_prompts[0][text]" => text_data,
          "cfg_scale" => 7,
          "clip_guidance_preset" => "FAST_BLUE",
          "samples" => 1,
          "steps" => 30,
          "style_preset" => style_data
        }
      )
      response["artifacts"].each_with_index do |image, i|
        File.open("#{task_id}.jpg", "wb") do |f|
          f.write(Base64.decode64(image["base64"]))
        end
      end
    end

    def upscale_image(task_id)
      engine_id = "esrgan-v1-x2plus"
      api_host = "https://api.stability.ai"
      api_key = 'sk-N0lLDwQZlSzzKFQ1CKgiXVbi0AUmXaDW97e3LWbcJcb9lmd8'

      response = HTTParty.post(
        "#{api_host}/v1/generation/#{engine_id}/image-to-image/upscale",
        headers: {
          "accept" => "image/png",
          "authorization" => "bearer #{api_key}"
        },
        body: {
          "image" => File.open("#{task_id}.jpg", "rb"),
          "width" => 1024
        }
      )

      if response.code != 200
        raise "non-200 response: #{response.body}"
      end

      File.write("public/images/#{task_id}.jpg", response.body)
    end

    def load_task_data_from_json_file(task_id)
      file_path = "#{task_id}.json"
      if File.exist?(file_path)
        JSON.parse(File.read(file_path))
      else
        nil
      end
    end

    def delete_task_data_json_file(task_id)
      file_path = "#{task_id}.json"
      File.delete(file_path) if File.exist?(file_path)
    end

    def call_stable_diffusion_api(task_id)
      # Read the task data from the temporary JSON file
      tmp_file = Rails.root.join('tmp', "#{task_id}.json")
      task_data = JSON.parse(File.read(tmp_file))

      image_data = task_data['image']
      text_data = task_data['text'] || 'make the tshirt red'
      style_data = task_data['style']

      # Decode the Base64 encoded image data
      image_data = Base64.decode64(image_data)
      image_file = File.open('public/images/1.jpg_resized.jpg', "rb")

      engine_id = "stable-diffusion-xl-beta-v2-2-2"
      api_host = ENV["API_HOST"] || "https://api.stability.ai"
      api_key = ENV["STABILITY_API_KEY"] || 'sk-N0lLDwQZlSzzKFQ1CKgiXVbi0AUmXaDW97e3LWbcJcb9lmd8'

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
        },
        debug_output: $stdout
      )

      raise "Non-200 response: #{response.body}" if response.code != 200

      data = JSON.parse(response.body)

      data["artifacts"].each_with_index do |image, i|
        File.open("./out/v1_img2img_#{i}.png", "wb") do |f|
          f.write(Base64.decode64(image["base64"]))
        end
      end
    end
  end
end