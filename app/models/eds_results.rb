class EdsResults
  attr_reader :items, :facets, :total_hits

  def initialize(items, facets, total_hits)
    @items = items
    @facets = facets
    @total_hits = total_hits
  end

  def self.from_response(response)
    items = items_from_response(response)
    facets = []
    total_hits = response.stat_total_hits
    results = EdsResults.new(items, facets, total_hits)
  end

  private
    def self.items_from_response(response)
      items = []
      response.records.each do |r|
        item = {
          id: r.eds_result_id,
          title: r.eds_title,
          author: clean_author(r.eds_authors.first),
          year: r.eds_publication_year,
          type: r.eds_publication_type,
          link: preferred_link(r),
          venue: r.eds_source_title,
          volume: r.eds_volume,
          issue: r.eds_issue,
          start: r.eds_page_start,
          database: r.eds_database_name
        }
        items << item
      end
      items
    end

    def self.preferred_link(record)
      link = easyarticle_link(record)
      if link == nil
        link = easyaccess_link(record)
        if link == nil
          link = ebscoperma_link(record, true)
        end
      end
      link
    end

    def self.ebscoperma_link(record, proxy)
      link = record.eds_plink
      if link != nil && proxy
        # Prepend revproxy to the EBSCO links to make sure users
        # go through Shibboleth. Otherwise users working from
        # outside our IP range are confronted with an EBSCO
        # login page. RevProxy makes sure users are presented
        # with Brown's Shibboleth authentication instead.
        link = "https://login.revproxy.brown.edu/login?url=#{link}"
      end
      link
    end

    def self.easyarticle_link(record)
      link = easy_link(record.all_links, "//library.brown.edu/easyarticle/")
      return nil if link == nil
      # Use the easyaccess URL instead easyarticle to prevent an extra redirect
      link = link.gsub("//library.brown.edu/easyarticle/", "//library.brown.edu/easyaccess/find/")
      ebsco_link = ebscoperma_link(record, false)
      if ebsco_link != nil
        # EasyAccess expects the EBSCO permalink to be encoded
        link += "&ebscoperma_link=#{CGI.escape(ebsco_link)}"
      end
      link
    end

    def self.easyaccess_link(record)
      easy_link(record.all_links, "//library.brown.edu/easyaccess/find")
    end

    def self.easy_link(links, prefix)
      links.each do |link|
        if (link[:url] || "").include?(prefix)
          return link[:url]
        end
      end
      nil
    end

    def self.results_to_file(response)
      delimiter = ""
      File.open("eds_results.json", 'w') do |file|
        file.write("[\r\n")
        response.records.each do |r|
          file.write(delimiter + r.to_json)
          delimiter = ", \r\n"
        end
        file.write("]\r\n")
      end
      nil
    end

    # Remove the ", Author" postfix on EDS values.
    # We might need to account for other values and/or find out an EDS
    # value that does not include these postfixes.
    def self.clean_author(author)
      return nil if author == nil
      val_to_remove = ", author"
      value = author.strip
      test_value = value.downcase
      if test_value == val_to_remove
        value = nil
      elsif test_value.end_with?(val_to_remove)
        value = value[0..(value.length()-9)]
      end
      value
    end
end
