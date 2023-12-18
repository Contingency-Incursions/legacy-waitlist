# frozen_string_literal: true

class CategoriesController < ApplicationController
  def index
    categories = CategoriesData.categories
    render json: { 'categories' => categories }
  end
end
