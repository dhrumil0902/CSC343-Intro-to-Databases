-- Rainmakers.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q10 CASCADE;

CREATE TABLE q10(
    driver_id INTEGER,
    month CHAR(2),
    mileage_2020 FLOAT,
    billings_2020 FLOAT,
    mileage_2021 FLOAT,
    billings_2021 FLOAT,
    mileage_increase FLOAT,
    billings_increase FLOAT
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;

DROP VIEW IF EXISTS driverRideInfo CASCADE;
CREATE VIEW driverRideInfo As
select to_char(extract(MONTH from request.datetime), '09') as month , concat(extract(year from request.datetime), ' ', to_char(extract(MONTH from request.datetime), '09' )) as monthyear  ,driver.driver_id, amount, request.destination <@> request.source as mileage
from dispatch join request on dispatch.request_id = request.request_id join clockedin on dispatch.shift_id = clockedin.shift_id join billed on billed.request_id = request.request_id right join driver on driver.driver_id = clockedin.driver_id
where dispatch.request_id IN(select request_id from dropoff) and extract(YEAR from request.datetime) < 2022 and extract(YEAR from request.datetime) > 2019;
-- Define views for your intermediate steps here:

DROP VIEW IF EXISTS seriesMonth CASCADE;
CREATE VIEW seriesMonth As
select to_char(generate_series(1,12), '09') AS mo, 2020 AS ye

UNION

select to_char(generate_series(1,12), '09') AS mo, 2021 AS ye;

DROP VIEW IF EXISTS allDriverMonths CASCADE;
CREATE VIEW allDriverMonths As
select mo as month, concat(ye,' ',mo) as monthyear, driver_id, 0 as amount, 0 as mileage from driver,seriesMonth;

DROP VIEW IF EXISTS driverInfoMonths CASCADE;
CREATE VIEW driverInfoMonths AS
select * from allDriverMonths where (driver_id, monthyear) NOT IN (
	select driver_id,monthyear from driverRideInfo
)
UNION

select * from driverRideInfo;

INSERT INTO q10
select driver_id, substring(month,2,3), sum(CASE when substring(monthyear,1,4) = '2020' then mileage else 0 end) as mileage_2020, sum(CASE when substring(monthyear,1,4) = '2020' then amount else 0 end) as billings_2020, sum(CASE when substring(monthyear,1,4) = '2021' then mileage else 0 end) as mileage_2021, sum(CASE when substring(monthyear,1,4) = '2021' then amount else 0 end) as billings_2021, sum(CASE when substring(monthyear,1,4) = '2021' then mileage else 0 end) - sum(CASE when substring(monthyear,1,4) = '2020' then mileage else 0 end) as mileage_increase, sum(CASE when substring(monthyear,1,4) = '2021' then amount else 0 end) - sum(CASE when substring(monthyear,1,4) = '2020' then amount else 0 end) as billings_increase  from driverInfoMonths GROUP BY driver_id,month;
 
-- Your query that answers the question goes below the "insert into" line:
--INSERT INTO q10
