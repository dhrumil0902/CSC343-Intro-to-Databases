-- Bigger and smaller spenders.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q5 CASCADE;

CREATE TABLE q5(
    client_id INTEGER,
    month VARCHAR(7),
    total FLOAT,
    comparison VARCHAR(30)
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS rideExtractMonth CASCADE;
create view rideExtractMonth as
SELECT request.request_id,client_id, billed.amount, concat(extract(year from datetime),to_char(extract(MONTH from datetime), '09' )) as monthyear
FROM request join billed on request.request_id = billed.request_id
where request.request_id IN (select request_id from dropoff);

DROP VIEW IF EXISTS billedAvgMonth CASCADE;
create view billedAvgMonth as
select monthyear, avg(amount) from rideExtractMonth group by monthyear;

DROP VIEW IF EXISTS billedTotalMonth CASCADE;
create view billedTotalMonth as
select client.client_id,monthyear, sum(amount) from rideExtractMonth right join client on rideExtractMonth.client_id = client.client_id group by client.client_id, monthyear;
-- Define views for your intermediate steps here:
DROP VIEW IF EXISTS clientMonthComb CASCADE;
create view clientMonthComb as
select client_id,monthyear from client,billedavgmonth;

DROP VIEW IF EXISTS everyZeroMonth CASCADE;
create view everyZeroMonth as
select *, 0 as amount from clientMonthComb where (client_id, monthyear)  NOT IN (
select client_id,case when monthyear IS NULL then '9484' else monthyear end from billedTotalMonth);

DROP VIEW IF EXISTS finalMonth CASCADE;
create view finalMonth as
select * from everyZeroMonth 
UNION 
select * from billedTotalMonth;

INSERT INTO q5
select client_id, finalMonth.monthyear, amount, case when amount < avg then 'below' else 'at or above' end from finalMonth,billedAvgMonth where finalMonth.monthyear = billedAvgMonth.monthyear ;
--select * from billedavgmonth,billedtotalmonth where ;
--select * from clientMonthComb where case when Exists(
	--select * from billedTotalMonth where billedTotalMonth.client_id = clientMonthComb.client_id and billedTotalMonth.monthyear = clientMonthComb.monthyear) IS true then 1 else 0 end;
-- Your query that answers the question goes below the "insert into" line:
--INSERT INTO q5
