-- ICT371 ACTIVITY 4 -- SCENARIO 4: CAMPUS CLINIC MEDICINE DISPENSING
-- QUESTION 1: Create tables and insert records 
DROP TABLE IF EXISTS dispensing_records CASCADE; 
DROP TABLE IF EXISTS medicines CASCADE; 
CREATE TABLE medicines ( 
medicine_id SERIAL PRIMARY KEY, 
medicine_name VARCHAR(100), 
stock_quantity INT CHECK (stock_quantity >= 0) 
); 
CREATE TABLE dispensing_records ( 
record_id SERIAL PRIMARY KEY, 
student_number VARCHAR(20), 
medicine_id INT REFERENCES medicines(medicine_id), 
quantity INT, 
status VARCHAR(20) 
); 
INSERT INTO medicines (medicine_name, stock_quantity) 
VALUES 
('Paracetamol', 100), 
('Amoxicillin', 10), 
('Cough Syrup', 0); 

-- QUESTION 2: IF ELSIF ELSE 
DO $$ 
DECLARE 
stock INT; 
BEGIN 
SELECT stock_quantity INTO stock 
FROM medicines 
WHERE medicine_id = 1; 
IF stock = 0 THEN 
RAISE NOTICE 'Medicine is out of stock'; 
ELSIF stock <= 10 THEN 
RAISE NOTICE 'Medicine has low stock'; 
ELSE 
RAISE NOTICE 'Medicine is sufficiently stocked'; 
END IF; 
END $$; 

-- QUESTION 3: WHILE AND NUMERIC FOR 
DO $$ 
DECLARE 
    i INT := 1; 
BEGIN 
    WHILE i <= 3 LOOP 
        RAISE NOTICE 'Stock review day: %', i; 
        i := i + 1; 
    END LOOP; 
 
    FOR i IN 1..3 LOOP 
        RAISE NOTICE 'Shelf inspection number: %', i; 
    END LOOP; 
END $$; 

 -- QUESTION 4: Create dispense_medicine procedure 
 
CREATE OR REPLACE PROCEDURE dispense_medicine( 
    p_student VARCHAR, 
    p_medicine_id INT, 
    p_quantity INT 
) 
LANGUAGE plpgsql 
AS $$ 
DECLARE 
    stock INT; 
BEGIN 
    IF p_quantity <= 0 THEN 
        RAISE EXCEPTION 'Invalid dispensing quantity'; 
    END IF; 
 
    SELECT stock_quantity INTO stock 
    FROM medicines 
    WHERE medicine_id = p_medicine_id 
    FOR UPDATE; 
 
    IF NOT FOUND THEN 
        RAISE EXCEPTION 'Medicine does not exist'; 
    END IF; 
 
    IF stock < p_quantity THEN 
        RAISE NOTICE 'Insufficient medicine stock'; 
 
    ELSE 
        UPDATE medicines 
        SET stock_quantity = stock_quantity - p_quantity 
        WHERE medicine_id = p_medicine_id; 
 
        INSERT INTO dispensing_records 
        (student_number, medicine_id, quantity, status) 
        VALUES 
        (p_student, p_medicine_id, p_quantity, 'Dispensed'); 
 
        RAISE NOTICE 'Medicine dispensed successfully'; 
    END IF; 
END; 
$$; 

-- QUESTION 5: Call procedure 
 
CALL dispense_medicine('MU001', 1, 10); 
CALL dispense_medicine('MU002', 2, 5); 
CALL dispense_medicine('MU003', 3, 5); 
SELECT * FROM medicines; 
SELECT * FROM dispensing_records; 


-- QUESTION 6: Create reverse_dispensing procedure 
CREATE OR REPLACE PROCEDURE reverse_dispensing( 
p_record_id INT 
) 
LANGUAGE plpgsql 
AS $$ 
DECLARE 
v_medicine_id INT; 
v_quantity INT; 
v_status VARCHAR; 
BEGIN 
SELECT medicine_id, quantity, status 
INTO v_medicine_id, v_quantity, v_status 
FROM dispensing_records 
WHERE record_id = p_record_id 
FOR UPDATE; 
IF NOT FOUND THEN 
RAISE NOTICE 'Dispensing record not found'; 
ELSIF v_status = 'Reversed' THEN 
RAISE NOTICE 'Record already reversed'; 
ELSE 
UPDATE medicines 
SET stock_quantity = stock_quantity + v_quantity 
WHERE medicine_id = v_medicine_id; 
UPDATE dispensing_records 
SET status = 'Reversed' 
WHERE record_id = p_record_id; 
RAISE NOTICE 'Dispensing reversed successfully'; 
END IF; 
END; 
$$; -- Call twice for the same record 
CALL reverse_dispensing(1); 
CALL reverse_dispensing(1); 


-- QUESTION 7: Explicit cursor for low-stock medicines 
DO $$ 
DECLARE 
medicine_cursor CURSOR FOR 
SELECT medicine_name, stock_quantity 
FROM medicines 
WHERE stock_quantity <= 10; 
medicine_record RECORD; 
BEGIN 
OPEN medicine_cursor; 
LOOP 
FETCH medicine_cursor INTO medicine_record; 
EXIT WHEN NOT FOUND; 
RAISE NOTICE 'Medicine: %, Stock: %', 
medicine_record.medicine_name, 
medicine_record.stock_quantity; 
END LOOP; 
CLOSE medicine_cursor; 
END $$; 

-- QUESTION 8: Handle negative dispensing quantity 
DO $$ 
BEGIN 
CALL dispense_medicine('MU004', 1, -5); 
EXCEPTION 
WHEN OTHERS THEN 
RAISE NOTICE 'Error handled: %', SQLERRM; 
END $$; 


-- QUESTION 9: Final queries 
SELECT * FROM medicines ORDER BY medicine_id; 
SELECT * FROM dispensing_records ORDER BY record_id;

