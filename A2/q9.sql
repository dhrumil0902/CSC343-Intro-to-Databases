-- Consistent raters.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q9 CASCADE;

CREATE TABLE q9(
    client_id INTEGER,
    email VARCHAR(30)
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS rideRating CASCADE;
CREATE VIEW rideRating 
AS
select driverrating.request_id,client_id,driver_id 
from dispatch join driverrating on dispatch.request_id = driverrating.request_id join request on dispatch.request_id = request.request_id join clockedin on dispatch.shift_id = clockedin.shift_id 
where driverrating.request_id IN(select request_id from dropoff);
-- Define views for your intermediate steps here:
DROP VIEW IF EXISTS allRides CASCADE;
CREATE VIEW allRides 
AS
select dispatch.shift_id,  dispatch.request_id,client_id,driver_id 
from dispatch join request on dispatch.request_id = request.request_id join clockedin on dispatch.shift_id = clockedin.shift_id 
where dispatch.request_id IN(select request_id from dropoff);

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q9

(select distinct client.client_id,email from allRides join client on allRides.client_id = client.client_id
where driver_id IN (select driver_id from rideRating where rideRating.client_id = allRides.client_id))
EXCEPT
(select distinct client.client_id,email from allRides join client on allRides.client_id = client.client_id where driver_id NOT IN (select driver_id from rideRating where rideRating.client_id = allRides.client_id));
