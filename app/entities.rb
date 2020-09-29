Client = Struct.new(:requestor_type, :exam_type, :exam_date, :first_name, :last_name, :municipality,
                    :zip_code, :email, :phone_number, :insurance_number, :insurance_company,
                    keyword_init: true)
Exam   = Struct.new(:requestor_type, :exam_type, :exam_date)
