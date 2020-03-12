require '../config/environment'
require 'csv'

def write_to_csv(row)
  CSV.open("./dup_detail_new.csv", "a+") do |csv|
    csv << row
  end
end

def merge_group(group)
  return if group.empty?
  professional_ids = group.map{|row| row["id"].to_i}.sort
  master_professional_id = professional_ids.shift
#  write_to_csv(["master"] + group.select{|row| row["id"].to_i == master_professional_id}.first.to_h.values)
  master_professional = begin Barrister::Professional.find master_professional_id rescue nil end
  if master_professional
    write_to_csv(["master"] + group.select{|row| row["id"].to_i == master_professional_id}.first.to_h.values)
  else
    write_to_csv(["master can't find, already merged"] + group.select{|row| row["id"].to_i == master_professional_id}.first.to_h.values)
  end
  professional_ids.each do |p_id|
    merge_result = "not merged"
    professional = begin Barrister::Professional.find p_id rescue nil end
    if master_professional && professional && master_professional.firstname == professional.firstname
      begin
        puts "Merging professional, master is #{master_professional.id}, slave is #{p_id}"
        merge_result = "merged" if master_professional.merge!(professional)
      rescue Exception => e
        merge_result = e.message
      end
    end
    write_to_csv([merge_result] + group.select{|row| row["id"].to_i == p_id}.first.to_h.values)
  end
  write_to_csv([""] * 30)
end


group = []
CSV.parse(File.read('./dup_detail.csv'), :headers => true) do |row|
  if row["id"].blank?
    merge_group(group)
    group = []
  else
    group << row
  end
end
