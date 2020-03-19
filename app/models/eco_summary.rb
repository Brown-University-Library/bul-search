class EcoSummary < ActiveRecord::Base
    def updated_date
        if self.updated_date_gmt == nil
            return ""
        end
        self.updated_date_gmt.localtime
    end

    def list_full_name
        if sierra_list == nil
            return list_name
        end
        "#{list_name} (Sierra List #{sierra_list})"
    end

    def fund_codes
        @fund_codes ||= begin
            # The "Name" value has both the "code" and the "master"
            # code values as a single string.
            # Here we split them into individual values.
            data = JSON.parse(self.fundcodes_str || "[]")
            data.map do |fund|
                code, master = fund["Name"].split("|")
                {"Name" => code || "", "Master" => master || "", "Count" => fund["Count"]}
            end
        end
        @fund_codes
    end

    def locations
        @locations ||= begin
            JSON.parse(self.locations_str || "[]")
        end
    end

    def subjects
        @subjects ||= begin
            JSON.parse(self.subjects_str || "[]")
        end
    end

    def callnumbers
        @callnumbers ||= begin
            JSON.parse(self.callnumbers_str || "[]")
        end
    end

    def checkouts
        @checkouts ||= begin
            JSON.parse(self.checkouts_str || "[]")
        end
    end

    def ranges()
        EcoRange.where(eco_summary_id: id)
    end

    # Reloads the details for the current EcoSummary which means
    # getting the list of bib records that match the call number
    # ranges for this EcoSummary.
    def refresh()
        # Delete previous details for this list...
        EcoDetails.delete_all("eco_summary_id = #{id}")

        # ...and fetch those records again based on the current
        # call number ranges.
        # TODO: optimize this code to insert in batches
        ranges().each do |range|
            bibs = Callnumber.get_by_range(range.from, range.to)
            items_count = 0
            bibs.each do |bib|
                items_count += EcoDetails.new_from_bib(id, range.id, bib[:id])
            end
            range.count = items_count
            range.save!
        end
    end

    def self.create_sample_lists()
        # Define header...
        s = EcoSummary.new
        s.list_name = "GOBI--2020_01_LC Subject Grouping_EA_review"
        s.save!

        # ...define ranges
        ranges = []
        ranges << {from: "B 125", to: "B 162", name: "Philosophy (General) / Orient"}
        ranges << {from: "B 5180", to: "B 5224", name: "Philosophy (General) / East Asia"}
        ranges << {from: "B 5230", to: "B 5234", name: "Philosophy (General) / korea"}
        ranges << {from: "B 5240", to: "B 5244", name: "Philosophy (General) / Japan"}
        ranges << {from: "B 5250", to: "B 5254", name: "Philosophy (General) / Korea"}
        # ranges << {from: "BF 1779", to: "BF ", name: "Psychology / Feng shui"}
        ranges << {from: "BL 1000", to: "BL 2370", name: "Religion / Asian.  Oriental"}
        ranges << {from: "BL 1830", to: "BL 1945", name: "Religion / Confucianism-Taoism"}
        ranges << {from: "BL 2216", to: "BL 2229", name: "Religion / Shinto"}
        ranges << {from: "BR 731", to: "BR 1599", name: "Christianity / History by region or country"}
        ranges << {from: "CD 5001", to: "CD 6471", name: "Diplomatics.  Archives.  Seals / Seals"}
        ranges << {from: "CE 1", to: "CE 97", name: "Technical Chronology.  Calendar / Technical Chronology.  Calendar"}
        ranges << {from: "CJ 1", to: "CJ 6661", name: "Numismatics / Numismatics"}
        ranges << {from: "CN 900", to: "CN 1355", name: "Inscriptions.  Epigraphy / By region or country"}
        ranges << {from: "CS 2300", to: "CS 3090", name: "Genealogy / Personal and family names"}
        ranges << {from: "CT 759", to: "CT 3199", name: "Biography / National biography"}
        ranges << {from: "DS 501", to: "DS 519", name: "Asia / Eastern Asia.  Far East."}
        ranges << {from: "DS 701", to: "DS 800", name: "Asia / China"}
        ranges << {from: "DS 801", to: "DS 900", name: "Asia / Japan"}
        ranges << {from: "DS 901", to: "DS 937", name: "Asia / Korea"}
        ranges << {from: "GB 170.3", to: "GB 399", name: "Physical Geography / By region or country"}
        ranges << {from: "GF 651", to: "GF 700", name: "Human Ecology.  Anthropogeography / Asia"}
        ranges << {from: "GN 590", to: "GN 642", name: "Anthropology / Asian ethnic groups"}
        ranges << {from: "GR 265", to: "GR 349", name: "Folklore / Folklore of Asia"}
        ranges << {from: "GT 1370", to: "GT 1579", name: "Manners and Customs (General) / Clothing of Asia"}
        ranges << {from: "HB 125", to: "HB 126", name: "Economic Theory. Demography / Asia"}
        ranges << {from: "HC 411", to: "HC 470", name: "Economic History and Conditions / Asia"}
        ranges << {from: "J 500", to: "J 703", name: "General Legislative and Executive Papers / Asia"}
        ranges << {from: "JQ 670", to: "JQ 679", name: "Political Institutions and Public Administration: Asia. Africa.  Australia / Hong Kong"}
        ranges << {from: "JQ 1050", to: "JQ 1061", name: "Political Institutions and Public Administration: Asia. Africa.  Australia / Goa.  Macau"}
        ranges << {from: "JQ 1500", to: "JQ 1519", name: "Political Institutions and Public Administration: Asia. Africa.  Australia / China"}
        ranges << {from: "JQ 1520", to: "JQ 1539", name: "Political Institutions and Public Administration: Asia. Africa.  Australia / Taiwan"}
        ranges << {from: "JQ 1600", to: "JQ 1699", name: "Political Institutions and Public Administration: Asia. Africa.  Australia / Japan"}
        ranges << {from: "JQ 1720", to: "JQ 1729", name: "Political Institutions and Public Administration: Asia. Africa.  Australia / Korea"}
        ranges << {from: "LA 1050", to: "LA 1429", name: "History of Education / Asia"}
        ranges << {from: "LG 1", to: "LG 400", name: "Education - Individual Institutions / Asia"}
        ranges << {from: "ML 330", to: "ML 345", name: "Literature on Music / Asia"}
        ranges << {from: "PL 1", to: "PL 8844", name: "Languages and Literatures of Eastern Asia, Africa, Oceania / Languages and Literatures of Eastern Asia, Africa, Oceania"}
        ranges << {from: "PL 491", to: "PL 5000", name: "Languages and Literatures of Eastern Asia, Africa, Oceania / Far Eastern languages and literatures"}
        ranges << {from: "PL 501", to: "PL 898", name: "Languages and Literatures of Eastern Asia, Africa, Oceania / Japanese"}
        ranges << {from: "PL 501", to: "PL 699", name: "Languages and Literatures of Eastern Asia, Africa, Oceania / Language"}
        ranges << {from: "PL 701", to: "PL 898", name: "Languages and Literatures of Eastern Asia, Africa, Oceania / Literature"}
        ranges << {from: "PL 901", to: "PL 998", name: "Languages and Literatures of Eastern Asia, Africa, Oceania / Korean"}
        ranges << {from: "PL 901", to: "PL 949", name: "Languages and Literatures of Eastern Asia, Africa, Oceania / Language"}
        ranges << {from: "PL 950", to: "PL 998", name: "Languages and Literatures of Eastern Asia, Africa, Oceania / Literature"}
        ranges << {from: "PL 1001", to: "PL 3279", name: "Languages and Literatures of Eastern Asia, Africa, Oceania / Chinese"}
        ranges << {from: "PL 1001", to: "PL 2239", name: "Languages and Literatures of Eastern Asia, Africa, Oceania / Language"}
        ranges << {from: "PL 2250", to: "PL 3300", name: "Languages and Literatures of Eastern Asia, Africa, Oceania / Literature"}
        ranges << {from: "PL 3301", to: "PL 5000", name: "Languages and Literatures of Eastern Asia, Africa, Oceania / Other groups"}
        ranges << {from: "Z 787", to: "Z 1000", name: "Bibliography.  Library Science / Libraries"}
        ranges << {from: "Z 1946", to: "Z 6953.7", name: "Bibliography.  Library Science / Bibliography.  Books and reading"}
        ranges.each do |range|
            r = EcoRange.new
            r.eco_summary_id = s.id
            r.from = range[:from]
            r.to = range[:to]
            r.name = range[:name]
            r.save!
        end

        # ...populate it with the bib information for those ranges
        s.refresh()
    end
end