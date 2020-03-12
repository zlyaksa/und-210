require '../config/environment'
require 'csv'

max_addresses_count = 0
max_schools_count = 0
result_array = []
CSV.parse(File.read('./dup.csv'), :headers => true).each do |row|
  Barrister::License.where(:licensing_authority_id => row["licensing_authority_id"], :license_number => row["license_number"]).each do |license|
    professional = license.professional
    hash = {:id => professional.id, :prefix => professional.prefix, :firstname => professional.firstname, :middlename => professional.middlename, :lastname => professional.lastname,
            :suffix => professional.suffix, :email => professional.email_address, :email_license => license.email_address,
            :addresses => professional.professional_addresses.sort_by(&:ordinal).map(&:address).compact.map{|a| [a.address_line1, a.address_line2, a.city, a.state, a.postal_code].compact.join("|")},
            :schools => professional.professional_schools.map{|ps| [ps.school.name, ps.graduation_date].join("|")}}

    max_addresses_count = hash[:addresses].count if hash[:addresses].count > max_addresses_count
    max_schools_count = hash[:schools].count if hash[:schools].count > max_schools_count
    result_array << hash
  end
  result_array << {:id => -1} # separator from csv
end

CSV.open("./dup_detail.csv", "w") do |csv|
  header = ["id","prefix","firstname","middlename","lastname","suffix","email","email_license"]
  len = header.length
  1.upto(max_addresses_count) do |i|
    header << "address#{i}"
  end

  1.upto(max_schools_count) do |i|
    header << "school#{i}"
  end

  csv << header

  result_array.each do |hash|
    if hash[:id] == -1
      csv << [""] * (len + max_addresses_count + max_schools_count)
      next
    end
    array = [hash[:id], hash[:prefix], hash[:firstname], hash[:middlename], hash[:lastname], hash[:suffx], hash[:email], hash[:email_license]]
    1.upto(max_addresses_count) do |i|
      array << hash[:addresses][i - 1]
    end

    1.upto(max_schools_count) do |i|
      array << hash[:schools][i - 1]
    end
    csv << array
  end
end
