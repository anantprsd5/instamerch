class ProcessImageJob < ApplicationJob
  queue_as :default

  def perform(task_id)
    # Read the image from the temporary file
    tmp_file = Rails.root.join('tmp', task_id)
    image_data = File.read(tmp_file)

    # Call the Stable Diffusion API and the Printful API
    stylized_image = call_stable_diffusion_api(image_data)
    product_mockup = call_printful_api(stylized_image)

    # Store the result in a cache with an expiration time
    Rails.cache.write(task_id, product_mockup, expires_in: 1.hour)

    # Delete the temporary file
    File.delete(tmp_file)
  end
end