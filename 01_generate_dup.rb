require '../config/environment'
require 'csv'

result = Barrister::BarristerBase.connection.execute "
SELECT la.state, licensing_authority_id, license_number, license_date, COUNT(DISTINCT professional_id) cp
FROM license l
JOIN licensing_authority la ON la.id = licensing_authority_id
WHERE license_number IS NOT NULL
GROUP BY 1, 2, 3, 4 HAVING cp > 1 order by cp"

CSV.open("./dup.csv", "w") do |csv|
  csv << ["state", "licensing_authority_id", "license_number", "license_date", "cp"]
  result.each do |row|
    csv << row
  end
end
