-- Table 1: Patient_Vitals_A (Focus on Respiratory Data)
CREATE TABLE Patient_Vitals_A (
    record_id SERIAL PRIMARY KEY,            -- 1: Primary Key (Auto-increment)
    patient_id INT NOT NULL,                 -- 2: Foreign Key/ID for patient
    record_timestamp TIMESTAMP NOT NULL DEFAULT NOW(), -- 3: Time of measurement
    breath_count_per_min INT NOT NULL,       -- 4: Key metric (e.g., 12-20 is normal)
    oxygen_saturation DECIMAL(4, 2) NOT NULL, -- 5: SaO2 percentage (e.g., 95.00)
    systolic_bp INT,                         -- 6: Systolic Blood Pressure
    diastolic_bp INT,                        -- 7: Diastolic Blood Pressure
    staff_id VARCHAR(10)                     -- 8: ID of the staff member
);

select * from Patient_Vitals_A

-- Table 2: Patient_Vitals_B (Focus on Cardiac Data)
CREATE TABLE Patient_Vitals_B (
    record_id SERIAL PRIMARY KEY,            -- 1: Primary Key (Auto-increment)
    patient_id INT NOT NULL,                 -- 2: Foreign Key/ID for patient
    record_timestamp TIMESTAMP NOT NULL DEFAULT NOW(), -- 3: Time of measurement
    pulse_rate_per_min INT NOT NULL,         -- 4: Key metric (e.g., 60-100 is normal)
    ecg_rhythm VARCHAR(50) NOT NULL,         -- 5: ECG reading (e.g., 'Sinus Rhythm', 'AFib')
    temperature DECIMAL(4, 1),               -- 6: Body Temperature (e.g., 36.5)
    pain_level INT,                          -- 7: Pain scale (0-10)
    notes TEXT                               -- 8: General Observations
);

select * from Patient_Vitals_B


--Function 1
CREATE OR REPLACE FUNCTION Insert_Vitals_A(
    p_patient_id INT,
    p_breath_count INT,
    p_oxygen_saturation DECIMAL,
    p_systolic_bp INT,
    p_diastolic_bp INT,
    p_staff_id VARCHAR
)
RETURNS TEXT AS $$
DECLARE
    error_message TEXT;
BEGIN
    -- 1. Check for required data (patient_id)
    IF p_patient_id IS NULL OR p_patient_id <= 0 THEN
        error_message := 'ERROR: Patient ID is missing or invalid.';
        RETURN error_message;
    END IF;

    -- 2. Check for required data (breath_count_per_min)
    IF p_breath_count IS NULL OR p_breath_count <= 0 THEN
        error_message := 'ERROR: Breath Count is missing or invalid.';
        RETURN error_message;
    END IF;

    -- 3. Critical Range Check: Severe Bradypnea (too slow)
    IF p_breath_count < 10 THEN
        error_message := 'WARNING: Breath Count is critically low (< 10). Immediate attention required.';
        RETURN error_message;
    END IF;

    -- 4. Critical Range Check: Severe Tachypnea (too fast)
    IF p_breath_count > 30 THEN
        error_message := 'WARNING: Breath Count is critically high (> 30).';
        RETURN error_message;
    END IF;

    -- 5. Range Check: Oxygen Saturation (Min)
    IF p_oxygen_saturation < 90.00 THEN
        error_message := 'WARNING: Oxygen Saturation is below 90%. Potential hypoxemia.';
        RETURN error_message;
    END IF;

    -- 6. Condition Check: Diastolic BP must be less than Systolic BP
    IF p_systolic_bp IS NOT NULL AND p_diastolic_bp IS NOT NULL AND p_diastolic_bp >= p_systolic_bp THEN
        error_message := 'ERROR: Diastolic BP cannot be equal to or greater than Systolic BP.';
        RETURN error_message;
    END IF;

    -- HAPPY PATH: If all checks pass, insert the data
    INSERT INTO Patient_Vitals_A (patient_id, breath_count_per_min, oxygen_saturation, systolic_bp, diastolic_bp, staff_id)
    VALUES (p_patient_id, p_breath_count, p_oxygen_saturation, p_systolic_bp, p_diastolic_bp, p_staff_id);

    RETURN 'SUCCESS: Record inserted into Patient_Vitals_A.';

END;
$$ LANGUAGE plpgsql;

select * from Insert_Vitals_A

SELECT Insert_Vitals_A(101, 16, 98.50, 120, 80, 'S123');

SELECT Insert_Vitals_A(102, 20, 88.00, 130, 85, 'S456');


--Function 2

CREATE OR REPLACE FUNCTION Insert_Vitals_B(
    p_patient_id INT,
    p_pulse_rate INT,
    p_ecg_rhythm VARCHAR,
    p_temperature DECIMAL,
    p_pain_level INT,
    p_notes TEXT
)
RETURNS TEXT AS $$
DECLARE
    error_message TEXT;
BEGIN
    -- 1. Check for required data (patient_id)
    IF p_patient_id IS NULL OR p_patient_id <= 0 THEN
        error_message := 'ERROR: Patient ID is missing or invalid.';
        RETURN error_message;
    END IF;

    -- 2. Check for required data (pulse_rate_per_min)
    IF p_pulse_rate IS NULL OR p_pulse_rate <= 0 THEN
        error_message := 'ERROR: Pulse Rate is missing or invalid.';
        RETURN error_message;
    END IF;

    -- 3. Critical Range Check: Severe Bradycardia (too slow)
    IF p_pulse_rate < 50 THEN
        error_message := 'WARNING: Pulse Rate is critically low (< 50). Bradycardia detected.';
        RETURN error_message;
    END IF;

    -- 4. Critical Range Check: Severe Tachycardia (too fast)
    IF p_pulse_rate > 120 THEN
        error_message := 'WARNING: Pulse Rate is critically high (> 120). Tachycardia detected.';
        RETURN error_message;
    END IF;

    -- 5. Range Check: Hyperthermia (High Temp)
    IF p_temperature IS NOT NULL AND p_temperature > 38.5 THEN
        error_message := 'WARNING: Temperature is elevated (> 38.5°C). Fever detected.';
        RETURN error_message;
    END IF;

    -- 6. Condition Check: Pain Level is 10 and no notes are provided
    IF p_pain_level = 10 AND (p_notes IS NULL OR TRIM(p_notes) = '') THEN
        error_message := 'WARNING: Pain Level is 10, but no detailed notes were provided.';
        RETURN error_message;
    END IF;

    -- HAPPY PATH: If all checks pass, insert the data
    INSERT INTO Patient_Vitals_B (patient_id, pulse_rate_per_min, ecg_rhythm, temperature, pain_level, notes)
    VALUES (p_patient_id, p_pulse_rate, p_ecg_rhythm, p_temperature, p_pain_level, p_notes);

    RETURN 'SUCCESS: Record inserted into Patient_Vitals_B.';

END;
$$ LANGUAGE plpgsql;

SELECT Insert_Vitals_B(201, 75, 'Sinus Rhythm', 37.0, 3, 'Patient resting');

SELECT Insert_Vitals_B(202, 135, 'AFib', 37.5, 5, 'Patient anxious');


--Aggregate function 
CREATE OR REPLACE FUNCTION Get_Avg_Patient_Vitals(
    p_patient_id INT
)
RETURNS TABLE (
    patient_id INT,
    avg_breath_count NUMERIC,
    avg_pulse_rate NUMERIC,
    total_records BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        A.patient_id,
        AVG(A.breath_count_per_min) AS avg_breath_count,
        AVG(B.pulse_rate_per_min) AS avg_pulse_rate,
        COUNT(A.patient_id) AS total_records
    FROM
        Patient_Vitals_A A
    INNER JOIN
        Patient_Vitals_B B ON A.patient_id = B.patient_id -- Assuming records are linked by patient_id
    WHERE
        A.patient_id = p_patient_id
    GROUP BY
        A.patient_id;

    IF NOT FOUND THEN
        -- Optionally handle the case where the patient ID is not found
        RAISE EXCEPTION 'Patient ID % not found in records.', p_patient_id;
    END IF;

END;
$$ LANGUAGE plpgsql;

SELECT * FROM Get_Avg_Patient_Vitals(101);