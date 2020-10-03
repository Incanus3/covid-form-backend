module CovidForm
  module Entities
    Client       = Struct.new(:first_name, :last_name, :municipality, :zip_code, :email,
                              :phone_number, :insurance_number, :insurance_company, :id,
                              keyword_init: true)
    Exam         = Struct.new(:requestor_type, :exam_type, :exam_date, :id, keyword_init: true)
    Registration = Struct.new(:requestor_type, :exam_type, :exam_date, :client_id, :id,
                              keyword_init: true)
  end
end
