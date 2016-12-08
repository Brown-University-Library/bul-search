# -*- encoding : utf-8 -*-
#
require "./lib/user_input.rb"

class ApiController < ApplicationController
  include Blacklight::Catalog

  # TODO: figure out a better way to configure Solr
  # without having to include Blacklight::Catalog
  configure_blacklight do |config|
    config.default_solr_params = {
      :qt => 'search',
      :rows => 10,
      :spellcheck => false
    }
  end

  def items_by_location
    code = params[:code] || ""
    if code.empty?
      return render_error("No location code provided (code)")
    end

    item = Item.new(blacklight_config)
    code = UserInput::Cleaner.clean(code)
    response = item.by_location(code, page, per_page)
    render :json => response.documents
  end

  def items_nearby
    id = UserInput::Cleaner.clean_id(params[:id])
    if id.empty?
      return render_error("No id provided.")
    end
    shelf = Shelf.new(blacklight_config)
    case params[:block]
    when "next"
      normalized = UserInput::Cleaner.clean(params[:normalized])
      documents = shelf.nearby_items_next(id, normalized)
    when "prev"
      normalized = UserInput::Cleaner.clean(params[:normalized])
      documents = shelf.nearby_items_prev(id, normalized)
    else
      documents = shelf.nearby_items(id)
    end
    documents.each do |d|
      d.link = "#{catalog_url(d.id)}?nearby"
    end

    nearby_response = {
      start: "0",
      num_found: documents.count.to_s,
      limit: "0",
      docs: documents
    }
    render :json => nearby_response
  end

  def shelf_items
    id = UserInput::Cleaner.clean_id(params[:id])
    if id.empty?
      return render_error("No id provided.")
    end

    start = (UserInput::Cleaner.clean(params[:start]) || "0").to_i
    if start > 0
      id = Callnumber.next_id(id, start)
    end
    limit = (UserInput::Cleaner.clean(params[:limit]) || "10").to_i
    verbose = params.has_key?("verbose") ? "verbose" : nil
    shelf = Shelf.new(blacklight_config)
    documents = shelf.nearby_items(id)
    documents.each do |d|
      if verbose != nil
        d.title = d.title + "<br/>" + d.id + ": " + d.callnumbers.join(",")
      end
      d.link = "#{catalog_url(d.id)}?nearby&#{verbose}"
    end

    nearby_response = {
      start: "0",
      num_found: (documents.count*100).to_s,
      limit: "0",
      docs: documents
    }
    render :json => nearby_response
  end

  private
    def page
      int_param(:page, 1)
    end

    def per_page
      int_param(:per_page, 10, 1000)
    end

    def render_error(message)
      render status: 400, :json => "{\"error\": \"#{message}\"}"
    end
end
