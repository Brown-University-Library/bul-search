require 'cgi'
require 'json'
require 'open-uri'
require 'rsolr'
require 'uri'

class Easy
  include BlacklightHelper

  def initialize(source, query, guest = true, trusted_ip = false)
    if source == "eds"
      @results = get_eds(query, guest, trusted_ip)
    elsif source == "eds_raw"
      @results = get_eds_raw(query, guest, trusted_ip)
    elsif source == 'newspaper_articles_eds'
      @results = get_eds_newspaper(query, guest, trusted_ip)
    elsif source == 'bdr'
      @results = get_bdr(query)
    else
      @results = get_catalog(query)
    end
  end

  def to_json
    @results
  end

  def bdr_link id
    item_url = ENV['BDR_ITEM_URL'].chomp('/')
    "#{item_url}/#{id}"
  end

  def bdr_thumbnail id
    url = ENV['BDR_THUMBNAIL_SERVICE']
    "#{url}/#{id}"
  end

  def get_bdr query
    solr_url = ENV['BDR_SEARCH_API_URL']
    if ENV['BDR_SEARCH_API_URL'] == nil || ENV['BDR_SEARCH_URL'] == nil
      Rails.logger.warn "BRD search skipped (no BDR_SEARCH_API_URL or BDR_SEARCH_URL available)"
      return nil
    end

    solr = RSolr.connect :url => solr_url

    # Clean up query booleans if present
    # This shouldn't be required but without this change
    # results are different.
    query.gsub!(' or ', ' OR ')
    query.gsub!(' and ', ' AND ')
    solr_q = query.gsub(':', '\\:')
    solr_q.gsub!('-', '\\-')

    qp = {
        :wt=>:json,
        "fl"=>"id:pid, title:primary_title, nonsort: nonsort, thumb:thumbnail, author:creator, year:dateIssued_year_ssim, genre:genre_local",
        "q"=>"#{solr_q}",
        "qt" => 'search',
        "fq"=>"discover:BDR_PUBLIC",
        "rows"=>5
    }
    response = solr.get 'select', :params => qp
    response.deep_stringify_keys!

    response['response']['docs'].each do |doc|
      doc['link'] = bdr_link doc['id']
      doc['thumbnail'] = bdr_thumbnail doc['id']
      #take first creator, year only
      ['author', 'year'].each do |k|
        if doc.has_key?(k)
          doc[k] = doc[k][0]
        end
      end
    end

    bdr_search_url = "https://repository.library.brown.edu/"
    if query != nil && !query.empty?
      bdr_search_url = ENV['BDR_SEARCH_URL'] + '?' + URI.encode_www_form( {'q'=> query} )
    end

    response['response']['more'] = bdr_search_url
    response['response']
  end

  def easy_base_url
    relative_root = ENV['RAILS_RELATIVE_URL_ROOT']
    base = '/easy/'
    if relative_root
      return relative_root + base
    else
      return base
    end
  end

  def catalog_base_url
    #Rails.application.config.relative_url_root if Rails.application.config.respond_to?('relative_url_root')
    relative_root = ENV['RAILS_RELATIVE_URL_ROOT']
    base = '/catalog/'
    if relative_root
      return relative_root + base
    else
      return base
    end
  end

  def format_filter_url(query, format)
    #Link to more results.
    cat_url = catalog_base_url
    enc_format = URI.escape(format.to_s)
    eq = CGI.escape(query)
    "#{cat_url}?f[format][]=#{enc_format}&q=#{eq}"
  end

  def catalog_callnumber_url(query)
    "#{catalog_base_url}?search_field=call_number&q=#{CGI.escape(query)}"
  end

  def advanced_catalog_url(query, format)
    #Link to advanced search
    url = catalog_base_url.gsub("/catalog/", "/advanced/")
    enc_format = URI.escape(format.to_s)
    eq = CGI.escape(query)
    # Notice that we don't pass the standard "f[format]=Book" parameter
    # because that causes Blacklight's Advanced Search page to only
    # display the Book format and prevents users from unselecting it or
    # selecting a different one. We could use the "f_inclusive[format][]=Book"
    # parameter which allows users to select _one_ additional format or
    # unselect the existing format. But instead we are using a custom
    # query string parameter (format_pre) to emulate on the Advanced Search
    # the user clicking on a format as the page loads. This allows the
    # user to select as many formats as the want to.
    "#{url}?&q=#{eq}&format_pre=#{enc_format}"
  end

  def catalog_link id
    burl = catalog_base_url
    #cpath = Rails.application.routes.url_helpers.catalog_path(id)
    return burl + id
  end

  #Returns string with icon class or nil
  def format_icon format
    config = Constants::FORMAT[format]
    unless config.nil?
      info = config[:icon]
      unless info.nil?
        return info
      end
    end
  end

  #Returns info text or nil
  #
  def info_text format
    config = Constants::FORMAT[format]
    unless config.nil?
      info = config[:info]
      unless info.nil?
        return info
      end
    end
  end

  def plural_format format
    if format == 'Music'
      return format
    else
      return format + 's'
    end
  end

  def get_catalog query
    call_number_matches = false
    solr_url = ENV['SOLR_URL']
    solr = RSolr.connect :url => solr_url

    if query == '*'
      q = ''
    else
      q = query
    end

    qp = {
        "group.ngroups"=>true,
        "group.field"=>"format",
        "group"=>true,
        "group.limit"=>5,
        "fl"=>"id, title_display, author_display, author_addl_display, pub_date, format, online:online_b",
        "q"=>"#{q.gsub('--', '\\-\\-')}",
        "qt" => 'search',
        :spellcheck => false,
        "defType" => "dismax", # == SOLR-7-MIGRATION == Needed in Solr 7 because the server is set to Lucene
        "df" => "id"           # == SOLR-7-MIGRATION == Needed in Solr 7 because the server is set to Lucene
    }

    if ENV["CJK"] == "true" && StringUtils.cjk?(q)
      qp[:qf] = 'title_txt_cjk author_txt_cjk'
      qp[:pf] = 'title_txt_cjk author_txt_cjk'
    end

    response = solr.get 'select', :params => qp

    out_data = {}

    groups = []

    response['grouped']['format']['groups'].each do |grp|
        format = grp['groupValue']
        grp_h = {}
        grp_h['format'] = format
        grp_h['numFound'] = grp['doclist']['numFound']
        grp_h['docs'] = []
        grp['doclist']['docs'].each do |doc|
            grp_h['docs'] << bento_doc(doc, format)
        end
        #Link to more results.
        grp_h['more'] = format_filter_url(query, format)
        if format == "Book"
          grp_h['advanced'] = advanced_catalog_url(query, format)
        end

        #icons
        grp_h['icon'] = format_icon(format)
        #info text
        grp_h['info'] = info_text(format)
        groups << grp_h
    end

    if groups.count == 0
      # See if we get any results as a call number search
      blacklight_config = Blacklight.default_configuration
      searcher = SearchCustom.new(blacklight_config)
      params = {}
      response, document_list, match = searcher.callnumber(query, params)
      if document_list.count > 0
        call_number_matches = true
        group = {}
        group['format'] = document_list.first["format"] || "Book"
        group['numFound'] = document_list.count
        group['docs'] = document_list.map {|doc| bento_doc(doc, nil)}
        group['more'] = catalog_callnumber_url(query)
        group['advanced'] = nil
        group['icon'] = nil
        group['info'] = nil
        groups << group
      end
    end

    out_data['groups'] = groups

    formats = []
    response['facet_counts']['facet_fields']['format'].each_slice(2) do |fgrp|
        (format, count) = fgrp
        d = {
            'format'=>format,
            'count'=>count
        }
        if call_number_matches
          d['more'] = catalog_callnumber_url(query)
        else
          d['more'] = format_filter_url(query, format)
        end
        formats << d
    end

    out_data['formats'] = formats

    return out_data
  end

  def bento_doc(doc, format)
    if format == nil
      format = doc['format']
    end
    doc['link'] = catalog_link doc['id']
    #Don't show pub_dates for Journals.  Not relevant.
    if format == 'Journal'
      doc.delete('pub_date')
    end
    #Take first value of pub_date
    if doc.has_key?("pub_date")
      doc['pub_date'] = doc['pub_date'][0]
    end
    doc['author_text'] = catalog_author_display(doc)
    doc
  end

  def get_eds_raw(query, guest, trusted_ip)
    if ENV["EDS_PROFILE_ID"] == nil
      Rails.logger.warn "EDS search skipped (no EDS_PROFILE_ID available)"
      return []
    end
    eds = Eds.new(guest, trusted_ip)
    eds.search_raw(query)
  end

  def get_eds(query, guest, trusted_ip)
    if ENV["EDS_PROFILE_ID"] == nil
      Rails.logger.warn "EDS search skipped (no EDS_PROFILE_ID available)"
      return {}
    end
    eds = Eds.new(guest, trusted_ip)
    eds_results = eds.search(query)
    query_safe = URI.encode(query) # encode to prevent XSS
    results = {}
    results['response'] = {}
    results['response']['more'] = Eds.native_url(query_safe, trusted_ip)
    results['response']['all'] = results['response']['more']
    results['response']['expandSearch'] = Eds.native_expanded_url(query_safe, trusted_ip)
    results['response']['raw'] = "/easy/search?source=eds_raw&q=#{query}"
    results['response']['docs'] = eds_results.items
    results['response']['advanced'] = Eds.native_advanced_url(query, trusted_ip)
    results['response']['numFound'] = eds_results.total_hits
    return results['response']
  end

  def get_eds_newspaper(query, guest, trusted_ip)
    if ENV["EDS_PROFILE_ID"] == nil
      Rails.logger.warn "EDS newspaper search skipped (no EDS_PROFILE_ID available)"
      return {}
    end
    eds = Eds.new(guest, trusted_ip)
    count = eds.newspapers_count(query)
    response = {}
    response[:more] = Eds.native_newspapers_url(query, trusted_ip)
    response[:numFound] = count
    return response
  end

  def self.get_best_bet(query)
    BestBet.get(query)
  end
end
