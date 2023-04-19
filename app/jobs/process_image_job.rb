require 'base64'
require 'httparty'
require 'json'

class ProcessImageJob < ApplicationJob
  queue_as :default

  def perform(task_id)
    # Call the Stable Diffusion API and the Printful API
    stylized_image = call_stable_diffusion_api(task_id)
    product_mockup = call_printful_api(stylized_image, text_data)

    # Store the result in a cache with an expiration time
    Rails.cache.write(task_id, product_mockup, expires_in: 1.hour)

    # Delete the temporary JSON file
    File.delete(tmp_file)
  end


  def call_stable_diffusion_api(task_id)
    # Read the task data from the temporary JSON file
    tmp_file = Rails.root.join('tmp', "#{task_id}.json")
    task_data = JSON.parse(File.read(tmp_file))

    image_data = task_data['image']
    text_data = task_data['text']
    style_data = task_data['style']

    # Decode the Base64 encoded image data
    image_data = Base64.decode64(image_data)

    engine_id = "stable-diffusion-v1-5"
    api_host = ENV["API_HOST"] || "https://api.stability.ai"
    api_key = ENV["STABILITY_API_KEY"]

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
        "init_image" => image_data,
        "image_strength" => 0.35,
        "init_image_mode" => "IMAGE_STRENGTH",
        "text_prompts[0][text]" => prompt,
        "cfg_scale" => 7,
        "clip_guidance_preset" => "FAST_BLUE",
        "samples" => 1,
        "steps" => 30,
      }
    )

    raise "Non-200 response: #{response.body}" if response.code != 200

    data = JSON.parse(response.body)

    data["artifacts"].each_with_index do |image, i|
      File.open("./out/v1_img2img_#{i}.png", "wb") do |f|
        f.write(Base64.decode64(image["base64"]))
      end
    end
  end

  def call_printful_api(image, product_info)

  end
end