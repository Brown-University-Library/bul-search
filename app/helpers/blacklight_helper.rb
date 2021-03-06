module BlacklightHelper
  include Blacklight::BlacklightHelperBehavior

  def application_name
    "Brown University Library Search"
  end

  ##Render a hidden div with the GA code
  def render_analytics_code
    code = ENV['GOOGLE_ANALYTICS_CODE']
    return nil unless !code.nil?
    content_tag(:div, "", :class => "hidden", :"data-analytics-id" => code)
  end

  def render_constraints_notes params
    content = ""
    content_tag(:span, content.html_safe)
  end

  def availability_service_url
    ENV['AVAILABILITY_SERVICE']
  end

  def render_show_doc_actions(document=@document, options={})
    wrapping_class = options.delete(:wrapping_class) || "documentFunctions"

    if controller_name == 'bdr'
      partial_location = 'bdr/bookmark_control'
    else
      partial_location = 'catalog/bookmark_control'
    end
    content = []
    content << render(:partial => partial_location, :locals => {:document=> document}.merge(options)) if render_bookmarks_control?

    content_tag("div", safe_join(content, "\n"), :class=> wrapping_class)
  end

  #Borrowed from SearchWorks
  def get_book_ids document
    isbn = add_prefix_to_elements( convert_to_array(document['isbn_t']), 'ISBN' )
    oclc = add_prefix_to_elements( convert_to_array(document['oclc_t']), 'OCLC' )
    #BUL doesn't have LCCNs in Solr index yet.
    lccn = add_prefix_to_elements( convert_to_array(document['lccn_t']), 'LCCN' )

    return { 'isbn' => isbn, 'oclc' => oclc, 'lccn' => lccn }
  end


  def add_prefix_to_elements arr, prefix
    new_array = []

    arr.each do |i|
      new_array.push("#{prefix}#{i}")
    end

    new_array
  end


  def convert_to_array(value = [])
    if value.nil? || value == ""
      return []
    elsif value.kind_of?(Array)
      return value
    else
      return [value.to_s]
    end
  end

  # Search History and Saved Searches display
  def link_to_previous_search(params)
    if params[:controller] == 'easy'
      query = params[:q]
      url = url_for :controller=>'easy', :action=> 'home', :q => query
      label = render_search_to_s_element(t('blacklight.bento.label'), query)
      link_to(label, url)
    else
      link_to(render_search_to_s(params), search_action_path(params))
    end
  end

  def item_subheading fld_value
    text = []
    text << convert_to_array(fld_value)[0]
    text.compact!
    if text.length == 0
      return nil
    else
      return content_tag("h5", safe_join(text, ". "), :class => "title-subheading")
    end
  end

  def index_item_subheading document
    text = []
    text << catalog_author_display(document)
    text << convert_to_array(document['pub_date'])[0]
    text.compact!
    if text.length == 0
      return nil
    else
      return content_tag("div", safe_join(text, ". "), :class => "title-subheading")
    end
  end

  ##
  # This function is used to create an author string display
  # for both the bento results at the catalog results.
  def catalog_author_display document
    primary = document['author_display']
    if primary
      return primary
    else
      added = document['author_addl_display']
      if added
        return added[0]
      end
    end
  end

end
