# frozen_string_literal: true

class ModulesController < ApplicationController

  def preload
    render json: module_info_impl(FitsData.used_module_ids)
  end

  def module_info
    ids = params[:ids].split(',')
    type_ids = []

    ids.each do |id|
      numeric_id = id.to_i
      if numeric_id == 0 # to_i returns 0 if the conversion fails
        render json: { error: 'Invalid type ID given' }, status: 400 and return
      end
      type_ids << numeric_id
    end

    if type_ids.length > 200
      render json: { error: 'Too many IDs' }, status: 400 and return
    end

    render json: module_info_impl(type_ids)
  end

  private
  def module_info_impl(ids)
    result = {}

    InvTypesService.load_types(ids, with_all: true).each do |id, type_info|
      if type_info
        result[id] = {
          name: type_info.typeName.clone,
          category: type_info.cached_group.groupName,
          slot: type_info.slot
        }
      end
    end

    result
  rescue StandardError => e # equivalent to Rust's ?, replace with specific exception if needed
    puts e.message
    nil
  end
end
