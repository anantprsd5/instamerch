# frozen_string_literal: true

class ImagesController < ApplicationController
  def process_image
    # Generate a unique task ID
    task_id = SecureRandom.uuid

    # Store the Base64 encoded image, text, and style in a temporary JSON file
    image_data = params[:image]
    text_data = params[:text]
    style_data = params[:style]

    task_data = {
      image: image_data,
      text: text_data,
      style: style_data,
    }

    tmp_file = Rails.root.join('tmp', "#{task_id}.json")
    File.write(tmp_file, task_data.to_json)

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
