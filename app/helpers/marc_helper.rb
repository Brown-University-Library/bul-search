
module MarcHelper

  def marc_display(document, name)
    document.marc_display_field(name)
  end

  def marc_display_tag(document, number)
    document.marc_tag(number)
  end

  def fielded_search(query, field)
    params = {:controller => "catalog", :action => 'index', :search_field => field, :q=> query}
    link_url = search_action_path(params)
    link_to(query, link_url)
  end

  def hot_link(terms, index)
    out = []
    terms.each do |term|
      out << fielded_search(term, index).html_safe
    end
    out
  end

  def toc_link_display(document)
    url = marc_display(document, 'toc_link')
    if url
      content_tag(
        "h6",
        link_to("Online Table of Contents", url),
        :class=> "toc-link"
      )
    end
  end

  def icon(format, size=nil, css_class=nil)
    if Constants::ICONS.has_key?(format)
      cls = "fa-#{Constants::ICONS[format]}"
      if size
        cls += " fa-#{size}"
      end
      content_tag('i', '', :class=>"fa #{cls}")
    end
  end

  ##Notes
  def render_record_notes(document)
    config = [
      {:label => "Note", :tag => "500"},
      {:label => "Dissertation information", :tag => "502"},
      {:label => "Bibliography", :tag => "504"},
      {:label => "Table of Contents", :tag => "505"},
      {:label => "Restrictions", :tag => "506"},
      {:label => "Scale of Material", :tag => "507"},
      {:label => "Other Formats", :tag => "530"}
    ]
    to_display = []
    config.each do |note_config|
      #render partial: "catalog/record/notes", locals: locals
      values = marc_display_tag(document, note_config[:tag])
      if !values.nil? && !values.empty?
        to_display << {:label => note_config[:label], :values => values}
      end
    end
    render partial: "catalog/record/notes", locals: {:note_display => to_display}
  end

end