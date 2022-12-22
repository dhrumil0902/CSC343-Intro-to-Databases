-- Ratings histogram.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q7 CASCADE;

CREATE TABLE q7(
    driver_id INTEGER,
    r5 INTEGER,
    r4 INTEGER,
    r3 INTEGER,
    r2 INTEGER,
    r1 INTEGER
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS allDriverRating CASCADE;
CREATE VIEW allDriverRating AS
select driverrating.request_id,driverrating.rating,driver.driver_id 
from dispatch natural join driverrating join request on dispatch.request_id = request.request_id join clockedin on dispatch.shift_id = clockedin.shift_id right join driver on driver.driver_id = clockedin.driver_id;
-- Define views for your intermediate steps here:
INSERT INTO q7
SELECT driver_id,count(CASE WHEN rating = 5 THEN 1 END) AS r5, count(CASE WHEN rating = 4 THEN 1 END) AS r4, count(CASE WHEN rating = 3 THEN 1 END) AS r3, count(CASE WHEN rating = 2 THEN 1 END) AS r2, count(CASE WHEN rating = 1 THEN 1 END) AS r1 from allDriverRating Group by driver_id;
-- Your query that answers the question goes below the "insert into" line:
--INSERT INTO q7
