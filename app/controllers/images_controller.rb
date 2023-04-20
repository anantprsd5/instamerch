# frozen_string_literal: true

class ImagesController < ApplicationController
  def create_designs
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

    save_task_data_to_json_file(task_id, task_data)
    # Process the image asynchronously
    mockups = ProcessImageJob.perform(task_id)

    render json: mockups
  end

  def get_designs
    task_id = params[:task_id]
    result = load_final_results_json_file(task_id)

    if result
      render json: { status: 'completed', mockup: result }
    else
      render json: { status: 'pending' }
    end
  end

  def testing_it
    render json: { status: 'It works' }
  end

  private

  def save_task_data_to_json_file(task_id, task_data)
    File.open("#{task_id}.json", 'w') do |file|
      file.write(task_data.to_json)
    end
  end

  def load_final_results_json_file(task_id)
    file_path = "#{task_id}_result.json"
    if File.exist?(file_path)
      JSON.parse(File.read(file_path))
    else
      nil
    end
  end
end
