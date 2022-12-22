-- Lure them back.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q2 CASCADE;

CREATE TABLE q2(
    client_id INTEGER,
    name VARCHAR(41),
  	email VARCHAR(30),
  	billed FLOAT,
  	decline INTEGER
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS billed500 CASCADE;

CREATE VIEW billed500 
AS 
SELECT client_id, sum(amount) as billed 
FROM request JOIN billed  ON request.request_id = billed.request_id 
WHERE extract( YEAR from datetime) < 2020 and 
request.request_id IN ( 
	SELECT request_id FROM dropoff)
						
GROUP BY client_id 
HAVING sum(amount)>=500;

DROP VIEW IF EXISTS rides2020 CASCADE;
CREATE VIEW rides2020
AS
SELECT client_id, count(request_id) from request where request_id IN (SELECT request_id from dropoff) and extract(year from datetime) = 2020 GROUP BY client_id HAVING count(request_id) <= 10 and count(request_id) >= 1;

DROP VIEW IF EXISTS decline CASCADE;
CREATE VIEW decline
AS
SELECT client_id,count(CASE WHEN extract(year from datetime) = 2021 THEN 1 END) - count(CASE WHEN extract(year from datetime) = 2020 THEN 1 END) as decline
from request 
where request_id IN( select request_id from dropoff) and 
( SELECT count(*) from request r1 where r1.client_id = request.client_id and extract(year from datetime) = 2020) 
> 
( SELECT count(*) from request r1 where r1.client_id = request.client_id and extract(year from datetime) = 2021) 
GROUP BY client_id;


--,extract(year from datetime) = 2021,extract(year from datetime) = 2020;
--SELECT client_id, extract(year from datetime), count(extract(year from datetime)) from --request where request_id IN( SELECT request_id from dropoff) GROUP BY client_id,extract(year from datetime)
-- Define views for your intermediate steps here:


-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q2
SELECT client_id, concat(firstname,' ',surname) as name, case when email IS NULL then 'unknown' else email end,billed, decline from client natural join rides2020 natural join decline natural join billed500;
