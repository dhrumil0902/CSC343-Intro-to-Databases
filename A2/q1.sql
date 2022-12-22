-- Months.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q1 CASCADE;

CREATE TABLE q1(
    client_id INTEGER,
    email VARCHAR(30),
    months INTEGER
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS ridesMonthYear CASCADE;


-- Define views for your intermediate steps here:
CREATE VIEW ridesMonthYear 
AS 
SELECT request_id,client_id, concat(extract(MONTH from datetime),'-', extract(year from datetime)) as monthyear
FROM request
--filtering rides that were not completed
WHERE request_id IN (
	SELECT request_id
	FROM pickup
	) and request_id IN (
	SELECT request_id
	FROM dropoff);

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q1 
SELECT client. client_id, email, count(DISTINCT monthyear) as months 
FROM client LEFT JOIN ridesMonthYear on ridesMonthYear.client_id = client.client_id 
Group by client.client_id;