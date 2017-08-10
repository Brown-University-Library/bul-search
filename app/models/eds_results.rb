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
      byebug
      response.records.each do |r|
        item = {
          id: r.eds_result_id,
          title: r.eds_title,
          author: self.clean_author(r.eds_authors.first),
          year: r.eds_publication_year,
          type: r.eds_publication_type,
          link: r.eds_plink,
          venue: r.eds_source_title,
          volume: r.eds_volume,
          issue: r.eds_issue,
          start: r.eds_page_start
        }
        items << item
      end
      items
    end

    # Remove the ", Author" postfix on EDS values.
    # We might need to account for other values and/or find out an EDS
    # value that does not include these postfixes.
    def self.clean_author(author)
      return nil if author == nil
      val_to_remove = ", Author"
      value = author.strip
      if value == val_to_remove
        value = nil
      elsif value.end_with?(val_to_remove)
        value = value[0..(value.length()-9)]
      end
      value
    end
end
