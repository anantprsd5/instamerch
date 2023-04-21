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

  def test_designs
    response = {"main":["https://printful-upload.s3-accelerate.amazonaws.com/tmp/5907c509af9f02af5795369abeb4efa2/unisex-staple-t-shirt-black-front-644268572374e.jpg",
             "https://printful-upload.s3-accelerate.amazonaws.com/tmp/507b9ebba43b6a8380639c58ed1138b3/unisex-staple-t-shirt-black-front-6442685723f88.jpg",
             "https://printful-upload.s3-accelerate.amazonaws.com/tmp/c3cffd7f4999f34597210c61bccf0146/unisex-staple-t-shirt-black-front-6442685724125.jpg",
             "https://printful-upload.s3-accelerate.amazonaws.com/tmp/2bfd4be5db9f23cca059296f30b5489a/unisex-staple-t-shirt-white-front-64426857242a4.jpg",
             "https://printful-upload.s3-accelerate.amazonaws.com/tmp/3389de7f6f6f298326a7ece4dbf1e5e7/unisex-staple-t-shirt-white-front-6442685724677.jpg",
             "https://printful-upload.s3-accelerate.amazonaws.com/tmp/bb77e930b8783a2f5f8cab8a196ff9fe/unisex-staple-t-shirt-white-front-6442685724979.jpg"]}
    render json: response
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
