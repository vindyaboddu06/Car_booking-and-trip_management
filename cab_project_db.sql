CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    phone VARCHAR(15) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE,
    registration_date DATE DEFAULT CURRENT_DATE
);
SELECT * FROM customers;
CREATE TABLE drivers (
    driver_id SERIAL PRIMARY KEY,
    driver_name VARCHAR(100) NOT NULL,
    phone VARCHAR(15) UNIQUE NOT NULL,
    license_number VARCHAR(50) UNIQUE NOT NULL,
    joining_date DATE DEFAULT CURRENT_DATE,
    status VARCHAR(20) DEFAULT 'Available'
);
SELECT * FROM drivers;
CREATE TABLE vehicles (
    vehicle_id SERIAL PRIMARY KEY,
    driver_id INT REFERENCES drivers(driver_id),
    vehicle_number VARCHAR(20) UNIQUE NOT NULL,
    vehicle_type VARCHAR(30) NOT NULL,
    model VARCHAR(50),
    seating_capacity INT CHECK (seating_capacity > 0)
);
SELECT * FROM vehicles;
CREATE TABLE bookings (
    booking_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    pickup_location VARCHAR(150) NOT NULL,
    drop_location VARCHAR(150) NOT NULL,
    booking_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    booking_status VARCHAR(20) DEFAULT 'Pending'
);
CREATE TABLE trips (
    trip_id SERIAL PRIMARY KEY,
    booking_id INT UNIQUE REFERENCES bookings(booking_id),
    driver_id INT REFERENCES drivers(driver_id),
    vehicle_id INT REFERENCES vehicles(vehicle_id),
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    distance_km DECIMAL(8,2),
    fare DECIMAL(10,2),
    trip_status VARCHAR(20)
);
CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    trip_id INT REFERENCES trips(trip_id),
    amount DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(30),
    payment_status VARCHAR(20),
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO customers
(customer_name, phone, email, registration_date)
SELECT
    'Customer_' || gs,
    '9' || LPAD(gs::TEXT, 9, '0'),
    'customer' || gs || '@gmail.com',
    CURRENT_DATE - (random() * 1000)::INT
FROM generate_series(1, 20000) AS gs;
SELECT COUNT(*) FROM customers;
INSERT INTO drivers
(driver_name, phone, license_number, joining_date, status)
SELECT
    'Driver_' || gs,
    '8' || LPAD(gs::TEXT, 9, '0'),
    'APDL' || LPAD(gs::TEXT, 6, '0'),
    CURRENT_DATE - (random() * 1500)::INT,
    (ARRAY['Available', 'Busy', 'Offline'])
        [floor(random() * 3 + 1)]
FROM generate_series(1, 5000) AS gs;
SELECT COUNT(*) FROM drivers;
INSERT INTO vehicles
(driver_id, vehicle_number, vehicle_type, model, seating_capacity)
SELECT
    gs,
    'AP' || LPAD((floor(random() * 99) + 1)::INT::TEXT, 2, '0')
    || 'AB' || LPAD(gs::TEXT, 4, '0'),

    (ARRAY['Sedan', 'SUV', 'Hatchback'])
        [floor(random() * 3 + 1)],

    (ARRAY[
        'Honda City',
        'Hyundai Creta',
        'Maruti Swift',
        'Toyota Glanza'
    ])[floor(random() * 4 + 1)],

    5

FROM generate_series(1, 5000) AS gs;
SELECT COUNT(*) FROM vehicles;
INSERT INTO bookings
(customer_id, pickup_location, drop_location, booking_time, booking_status)
SELECT
    (floor(random() * 20000) + 1)::INT,

    (ARRAY[
        'Vijayawada',
        'Guntur',
        'Tenali',
        'Amaravati',
        'Mangalagiri'
    ])[floor(random() * 5 + 1)],

    (ARRAY[
        'Vijayawada',
        'Guntur',
        'Tenali',
        'Amaravati',
        'Mangalagiri'
    ])[floor(random() * 5 + 1)],

    CURRENT_TIMESTAMP - (random() * INTERVAL '365 days'),

    (ARRAY[
        'Pending',
        'Completed',
        'Cancelled'
    ])[floor(random() * 3 + 1)]

FROM generate_series(1, 20000);
SELECT COUNT(*) FROM bookings;
INSERT INTO trips
(
    booking_id,
    driver_id,
    vehicle_id,
    start_time,
    end_time,
    distance_km,
    fare,
    trip_status
)
SELECT
    b.booking_id,
    (floor(random() * 5000) + 1)::INT,
    (floor(random() * 5000) + 1)::INT,
    b.booking_time,
    b.booking_time + (random() * INTERVAL '2 hours'),
    ROUND((random() * 45 + 5)::NUMERIC, 2),
    ROUND((random() * 900 + 100)::NUMERIC, 2),
    'Completed'
FROM bookings b
WHERE b.booking_status = 'Completed';
SELECT COUNT(*) FROM trips;
INSERT INTO payments
(
    trip_id,
    amount,
    payment_method,
    payment_status,
    payment_date
)
SELECT
    trip_id,
    fare,

    (ARRAY[
        'UPI',
        'Card',
        'Cash',
        'Net Banking'
    ])[floor(random() * 4 + 1)],

    'Successful',

    CURRENT_TIMESTAMP - (random() * INTERVAL '365 days')

FROM trips
WHERE trip_status = 'Completed';
SELECT COUNT(*) FROM payments;
SELECT COUNT(*) FROM customers;

SELECT COUNT(*) FROM drivers;

SELECT COUNT(*) FROM vehicles;

SELECT COUNT(*) FROM bookings;

SELECT COUNT(*) FROM trips;

SELECT COUNT(*) FROM payments;
SELECT COUNT(*) AS total_bookings
FROM bookings;
SELECT COUNT(*) AS completed_bookings
FROM bookings
WHERE booking_status = 'Completed';
SELECT COUNT(*) AS cancelled_bookings
FROM bookings
WHERE booking_status = 'Cancelled';
SELECT SUM(amount) AS total_revenue
FROM payments
WHERE payment_status = 'Successful';
SELECT ROUND(AVG(fare), 2) AS average_fare
FROM trips
WHERE trip_status = 'Completed';
SELECT
    c.customer_name,
    b.pickup_location,
    b.drop_location,
    b.booking_status
FROM customers c
JOIN bookings b
ON c.customer_id = b.customer_id;
SELECT
    t.trip_id,
    c.customer_name,
    d.driver_name,
    v.vehicle_number,
    b.pickup_location,
    b.drop_location,
    t.distance_km,
    t.fare,
    t.trip_status
FROM trips t
JOIN bookings b
    ON t.booking_id = b.booking_id
JOIN customers c
    ON b.customer_id = c.customer_id
JOIN drivers d
    ON t.driver_id = d.driver_id
JOIN vehicles v
    ON t.vehicle_id = v.vehicle_id;
SELECT
    d.driver_name,
    COUNT(t.trip_id) AS total_trips
FROM drivers d
JOIN trips t
ON d.driver_id = t.driver_id
GROUP BY d.driver_id, d.driver_name
ORDER BY total_trips DESC;
SELECT
    pickup_location,
    COUNT(*) AS total_bookings
FROM bookings
GROUP BY pickup_location
ORDER BY total_bookings DESC;
SELECT
    d.driver_name,
    COUNT(t.trip_id) AS total_trips
FROM drivers d
JOIN trips t
ON d.driver_id = t.driver_id
GROUP BY d.driver_id, d.driver_name
HAVING COUNT(t.trip_id) >= 5;
SELECT *
FROM trips
WHERE fare > (
    SELECT AVG(fare)
    FROM trips
);
CREATE INDEX idx_bookings_customer
ON bookings(customer_id);
CREATE INDEX idx_trips_driver
ON trips(driver_id);
EXPLAIN ANALYZE
SELECT *
FROM bookings
WHERE customer_id = 1000;
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM bookings
WHERE customer_id = 1000;



SELECT 'customers' AS table_name, COUNT(*) AS records FROM customers
UNION ALL
SELECT 'drivers', COUNT(*) FROM drivers
UNION ALL
SELECT 'vehicles', COUNT(*) FROM vehicles
UNION ALL
SELECT 'bookings', COUNT(*) FROM bookings
UNION ALL
SELECT 'trips', COUNT(*) FROM trips
UNION ALL
SELECT 'payments', COUNT(*) FROM payments;




SELECT
    c.customer_id,
    c.customer_name,
    c.phone,

    b.booking_id,
    b.pickup_location,
    b.drop_location,
    b.booking_time,
    b.booking_status,

    d.driver_id,
    d.driver_name,
    d.phone AS driver_phone,
    d.license_number,

    v.vehicle_number,
    v.vehicle_type,
    v.model,

    t.trip_id,
    t.start_time,
    t.end_time,
    t.distance_km,
    t.fare,
    t.trip_status,

    p.payment_id,
    p.amount,
    p.payment_method,
    p.payment_status,
    p.payment_date

FROM customers c

JOIN bookings b
    ON c.customer_id = b.customer_id

LEFT JOIN trips t
    ON b.booking_id = t.booking_id

LEFT JOIN drivers d
    ON t.driver_id = d.driver_id

LEFT JOIN vehicles v
    ON t.vehicle_id = v.vehicle_id

LEFT JOIN payments p
    ON t.trip_id = p.trip_id

WHERE c.customer_id = 100;