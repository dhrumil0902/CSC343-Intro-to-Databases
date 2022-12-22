-- Rest bylaw.

-- You must not change the next 2 lines or the table definition.
-- SET SEARCH_PATH TO uber, public;
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q3 CASCADE;

CREATE TABLE q3(
    driver_id INTEGER,
    start DATE,
    driving INTERVAL,
    breaks INTERVAL
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS CompletedPickUp CASCADE;
DROP VIEW IF EXISTS DayEACHDurationId CASCADE;
DROP VIEW IF EXISTS DayTotaldurationId CASCADE;
DROP VIEW IF EXISTS DropoffDriver CASCADE;
DROP VIEW IF EXISTS PickUpDriver CASCADE;
DROP VIEW IF EXISTS DriverEachBreakDuration CASCADE;
DROP VIEW IF EXISTS IDDAYHadBreakTotalbreak CASCADE;
DROP VIEW IF EXISTS DAYidDurationBreak CASCADE;
DROP VIEW IF EXISTS brokebylaw CASCADE;



-- Define views for your intermediate steps here:

-- STEP 1. GETTING DURATIONS

-- Pickup that has corresponding dropoff(their Request IDs, driver ID, date)
CREATE VIEW CompletedPickUp
AS 
SELECT Pickup.request_id, ClockedIn.driver_id, Pickup.datetime
FROM Pickup join Dropoff on Pickup.request_id = Dropoff.request_id 
    join Dispatch on Dropoff.request_id = Dispatch.request_id
    join ClockedIn on Dispatch.shift_id = ClockedIn.shift_id
ORDER BY ClockedIn.driver_id;


-- For each driver, day, EACH duration, their driver ID.
CREATE VIEW DayEACHDurationId
AS 
SELECT Date(Dropoff.datetime) as day, min(Dropoff.datetime-CompletedPickup.datetime) as duration, driver_id
FROM Dropoff join CompletedPickup on Dropoff.request_id = CompletedPickup.request_id
WHERE Date(Dropoff.datetime) = Date(CompletedPickup.datetime)
GROUP BY driver_id, Date(Dropoff.datetime);


-- For each driver, day, TOTAL duration(sum of the duration of that day), their driver ID.
CREATE VIEW DayTotaldurationId
AS 
SELECT day, sum(duration) as total_duration, driver_id
FROM DayEACHDurationId
GROUP BY driver_id, day;


-- STEP 2. GETTING BREAKS

-- Dropoff of driver(driver id, date, the datetime of the drop off)
CREATE VIEW DropoffDriver
AS
SELECT driver_id, date(Dropoff.datetime) as day, Dropoff.datetime
FROM Dropoff join Dispatch on Dropoff.request_id = Dispatch.request_id
    join ClockedIn on Dispatch.shift_id = ClockedIn.shift_id;


-- PickUp of driver(driver id, and the datetime of the pickup)
CREATE VIEW PickUpDriver
AS
SELECT driver_id, date(PickUp.datetime) as day, PickUp.datetime
FROM PickUp join Dispatch on PickUp.request_id = Dispatch.request_id
    join ClockedIn on Dispatch.shift_id = ClockedIn.shift_id;


-- Driver_id, day, each break's duration on that day
CREATE VIEW DriverEachBreakDuration
AS
SELECT PairOfDtimePtime.driver_id, PairOfDtimePtime.day, (CASE WHEN Pdatetime IS NOT NULL THEN (Pdatetime-Ddatetime) ELSE INTERVAL '0 min' END) as each_break
FROM ( -- To get each break, we should get each pair(if exists) of [(1)dropoff, (2)nextpickup]
-- Note: and nextpickup is the pickup(if exists) that happens in the closest time of the (1)dropoff
    SELECT DropoffDriver.driver_id, DropoffDriver.day, DropoffDriver.datetime as Ddatetime,
    min(PickUpDriver.datetime) as Pdatetime
    -- IF(PickUpDriver.datetime IS NOT NULL, PickUpDriver.datetime that makes the min difference from Dropoff driver, null)
    FROM DropoffDriver LEFT JOIN PickUpDriver
    ON DropoffDriver.driver_id = PickUpDriver.driver_id
        AND DropoffDriver.day = PickUpDriver.day
        AND DropoffDriver.datetime < PickUpDriver.datetime
    GROUP BY DropoffDriver.driver_id, DropoffDriver.day, DropoffDriver.datetime) AS PairOfDtimePtime;


-- ID, Day, had_break, total_break
-- For each (1) driver_id, (2) on a particular day,(3) boolean value that checkes if the driver of driver_id 
-- had a break that lasts more than 15 minutes, (4) total_break duration on that day
CREATE VIEW IDDAYHadBreakTotalbreak
AS
SELECT driver_id, day, 
(CASE WHEN (CASE WHEN max(each_break)IS NOT NULL THEN
                        max(each_break)
                    ELSE
                        INTERVAL '0 min'
            END) 
            >(INTERVAL '15 min') THEN
                TRUE 
        ELSE 
            FALSE END) as had_break, 
            
(CASE WHEN sum(each_break)IS NOT NULL THEN
     sum(each_break)
ELSE 
    INTERVAL '0 min' END) as total_break

FROM DriverEachBreakDuration
GROUP BY driver_id, day;


-- need a combined table that has DayTotaldurationId and IDDAYHadBreakTotalbreak, and for every day from starting day of DayDuration to the end dat of Dayduration, 
-- IDDAYHadBreakTotalbreak should have a value(even if there is no corresponding day.)
-- In detail, (1) had_break should be false and (2)total_break should be 0(this is for convention)

CREATE VIEW DAYidDurationBreak
AS
SELECT DayTotaldurationId.day, DayTotaldurationId.driver_id, total_duration, 
        (CASE WHEN had_break IS NOT NULL THEN had_break ELSE False END) as had_break, 
        (CASE WHEN total_break IS NOT NULL THEN total_break ELSE INTERVAL '0 min' END) as total_break
FROM DayTotaldurationId LEFT JOIN IDDAYHadBreakTotalbreak
ON (DayTotaldurationId.driver_id = IDDAYHadBreakTotalbreak.driver_id)
   AND (DayTotaldurationId.day = IDDAYHadBreakTotalbreak.day);


CREATE VIEW brokebylaw
AS
SELECT driver_id as driver1, day as day1, (total_duration + total_duration2+total_duration3) as driving, (total_break+total_break2+total_break3) as breaks
FROM DAYidDurationBreak
    join (SELECT driver_id as driver2, day as day2, total_duration as total_duration2, total_break as total_break2
                    FROM DAYidDurationBreak
                    WHERE total_duration > INTERVAL '12 hours'
                            and had_break = False) AS secondday on driver_id = driver2 and day2 = day + INTERVAL '1 day'

    join (SELECT driver_id as driver3, day as day3, total_duration as total_duration3, total_break as total_break3
                                        FROM DAYidDurationBreak
                                        WHERE total_duration > '12 hours'
                                                and had_break = False) AS thirdday on driver_id = driver3 and day3 = day2 + INTERVAL '1 day'

WHERE total_duration >= '12 hours' and had_break = FALSE;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q3
SELECT driver1 as driver_id, day1 as start, driving, breaks
FROM brokebylaw;