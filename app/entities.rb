Client = Struct.new(:first_name, :last_name, :municipality, :zip_code, :email, :phone_number,
                    :insurance_number, :insurance_company, :id, keyword_init: true)
Exam   = Struct.new(:requestor_type, :exam_type, :exam_date, :id)
