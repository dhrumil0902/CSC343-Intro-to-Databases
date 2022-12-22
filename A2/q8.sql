-- Scratching backs?

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q8 CASCADE;

CREATE TABLE q8(
    client_id INTEGER,
    reciprocals INTEGER,
    difference FLOAT
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS driverRatedClient CASCADE;
CREATE VIEW driverRatedClient  AS
select request.request_id,rating as clientRating,client_id from clientrating join request on clientrating.request_id = request.request_id where request.request_id IN (Select request_id from dropoff);

DROP VIEW IF EXISTS clientRatedDriver CASCADE;
CREATE VIEW clientRatedDriver  AS
select driverrating.request_id,driver_id, driverrating.rating as driverRating
from dispatch join driverrating on dispatch.request_id = driverrating.request_id join request on dispatch.request_id = request.request_id join clockedin on dispatch.shift_id = clockedin.shift_id 
where driverrating.request_id IN(select request_id from dropoff);
-- Define views for your intermediate steps here:
INSERT INTO q8
select client_id,count(*) as reciprocals,avg(driverrating - clientrating) as difference from driverRatedClient join clientRatedDriver on driverRatedClient.request_id = clientRatedDriver.request_id group by client_id;
-- Your query that answers the question goes below the "insert into" line:

