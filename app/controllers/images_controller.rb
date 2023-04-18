# frozen_string_literal: true

class ImagesController < ApplicationController
  def process_image
    # Generate a unique task ID
    task_id = SecureRandom.uuid

    # Store the Base64 encoded image in a temporary file
    image_data = params[:image]
    tmp_file = Rails.root.join('tmp', task_id)
    File.write(tmp_file, Base64.decode64(image_data))

    # Process the image asynchronously
    ProcessImageJob.perform_later(task_id)

    # Return the task ID to the frontend
    render json: { task_id: task_id }
  end

  def task_status
    task_id = params[:task_id]
    result = Rails.cache.read(task_id)

    if result
      render json: { status: 'completed', mockup: result }
    else
      render json: { status: 'pending' }
    end
  end
end
