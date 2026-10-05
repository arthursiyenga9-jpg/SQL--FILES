-- ICT371 ACTIVITY 4 -- SCENARIO 3: STUDENT HOSTEL ROOM ALLOCATION 

-- QUESTION 1: Create tables and insert records 
DROP TABLE IF EXISTS allocations CASCADE; 
DROP TABLE IF EXISTS hostel_rooms CASCADE; 
CREATE TABLE hostel_rooms ( 
room_id SERIAL PRIMARY KEY, 
room_number VARCHAR(20), 
available_spaces INT CHECK (available_spaces >= 0) 
); 
CREATE TABLE allocations ( 
allocation_id SERIAL PRIMARY KEY, 
student_number VARCHAR(20), 
room_id INT REFERENCES hostel_rooms(room_id), 
status VARCHAR(20) 
); 
INSERT INTO hostel_rooms (room_number, available_spaces) 
VALUES 
('A101', 4), 
('A102', 1), 
('A103', 0);

-- QUESTION 2: IF ELSIF ELSE 
DO $$ 
DECLARE 
spaces INT; 
BEGIN 
SELECT available_spaces INTO spaces 
FROM hostel_rooms 
WHERE room_id = 1; 
IF spaces = 0 THEN 
        RAISE NOTICE 'Room is full'; 
 
    ELSIF spaces = 1 THEN 
        RAISE NOTICE 'Room has one space left'; 
 
    ELSE 
        RAISE NOTICE 'Room has several spaces available'; 
    END IF; 
END $$; 

 -- QUESTION 3: WHILE AND NUMERIC FOR 
 
DO $$ 
DECLARE 
    i INT := 1; 
BEGIN 
    WHILE i <= 3 LOOP 
        RAISE NOTICE 'Hostel inspection day: %', i; 
        i := i + 1; 
    END LOOP; 
 
    FOR i IN 1..3 LOOP 
        RAISE NOTICE 'Room check number: %', i; 
    END LOOP; 
END $$; 

 
-- QUESTION 4: Create allocate_room procedure 

CREATE OR REPLACE PROCEDURE allocate_room( 
    p_student VARCHAR, 
    p_room_id INT 
) 
LANGUAGE plpgsql 
AS $$ 
DECLARE 
    spaces INT; 
BEGIN 
    IF p_student IS NULL OR TRIM(p_student) = '' THEN 
        RAISE EXCEPTION 'Student number cannot be blank'; 
    END IF; 
 
    SELECT available_spaces INTO spaces 
    FROM hostel_rooms 
    WHERE room_id = p_room_id 
    FOR UPDATE; 
 
    IF NOT FOUND THEN 
        RAISE EXCEPTION 'Room does not exist'; 
    END IF; 
 
    IF spaces <= 0 THEN 
        RAISE NOTICE 'Room is full'; 
 
    ELSE 
        UPDATE hostel_rooms 
        SET available_spaces = available_spaces - 1 
        WHERE room_id = p_room_id; 
INSERT INTO allocations 
(student_number, room_id, status) 
VALUES 
(p_student, p_room_id, 'Allocated'); 
RAISE NOTICE 'Room allocated successfully'; 
END IF; 
END; 
$$; 

-- QUESTION 5: Call procedure 
CALL allocate_room('MU001', 1); 
CALL allocate_room('MU002', 2); 
CALL allocate_room('MU003', 3); 
SELECT * FROM hostel_rooms; 
SELECT * FROM allocations;

-- QUESTION 6: Create check_out procedure 
CREATE OR REPLACE PROCEDURE check_out( 
p_allocation_id INT 
) 
LANGUAGE plpgsql 
AS $$ 
DECLARE 
v_room_id INT; 
v_status VARCHAR; 
BEGIN 
SELECT room_id, status 
INTO v_room_id, v_status 
FROM allocations 
WHERE allocation_id = p_allocation_id 
FOR UPDATE; 
IF NOT FOUND THEN 
RAISE NOTICE 'Allocation not found'; 
ELSIF v_status = 'Completed' THEN 
RAISE NOTICE 'Student has already checked out'; 
ELSE 
UPDATE hostel_rooms 
SET available_spaces = available_spaces + 1 
WHERE room_id = v_room_id; 
UPDATE allocations 
SET status = 'Completed' 
WHERE allocation_id = p_allocation_id; 
RAISE NOTICE 'Checkout successful'; 
END IF; 
END; 
$$; 
-- Call twice for the same allocation 
CALL check_out(1); 
CALL check_out(1); 


-- QUESTION 7: Explicit cursor 
DO $$ 
DECLARE 
room_cursor CURSOR FOR 
SELECT room_number, available_spaces 
FROM hostel_rooms 
WHERE available_spaces <= 1; 
room_record RECORD; 
BEGIN 
OPEN room_cursor; 
LOOP 
FETCH room_cursor INTO room_record; 
EXIT WHEN NOT FOUND; 
RAISE NOTICE 'Room: %, Available spaces: %', 
room_record.room_number, 
room_record.available_spaces; 
END LOOP; 
CLOSE room_cursor; 
END $$; 


-- QUESTION 8: Exception handling for blank student number 
DO $$ 
BEGIN 
CALL allocate_room('   ', 1); 
EXCEPTION 
WHEN OTHERS THEN 
RAISE NOTICE 'Error handled: %', SQLERRM; 
END $$; 


-- QUESTION 9: Final queries 
SELECT * FROM hostel_rooms ORDER BY room_id; 
SELECT * FROM allocations ORDER BY allocation_id; 





