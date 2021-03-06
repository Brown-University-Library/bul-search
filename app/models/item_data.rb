class ItemData
  attr_reader :id, :barcode
  attr_accessor :location_code, :bookplate_code, :call_number,
    :created_date, :copy, :volume, :suppressed,
    :checkout_total, :checkout_2015_plus
  attr_writer :bookplate_url, :bookplate_display

  def initialize(id, barcode)
    @id = clean_id(id)
    @barcode = clean_barcode(barcode)
    @suppressed = false
    @checkout_total = 0
    @checkout_2015_plus = 0
    @created_date = nil
  end

  def bookplate_url
    @bookplate_url || ""
  end

  def bookplate_display
    @bookplate_display || ""
  end

  def to_s
    "#{@barcode}, #{@location_code}, #{@bookplate_code}, #{@id}"
  end

  def online?
    return false if @location_code == nil
    return true if @location_code == "el001"
    @location_code[0..1] == "es"
  end

  def location
    @location_name ||= if online?
      "ONLINE"
    else
      Location.get_name(@location_code)
    end
  end

  def clean_id(id)
    return nil if (id || "").strip.length == 0
    if id.start_with?(".i")
      return id[2..-1]
    end
    id
  end

  def clean_barcode(barcode)
    return nil if barcode == nil
    barcode.gsub(" ", "")
  end
end
