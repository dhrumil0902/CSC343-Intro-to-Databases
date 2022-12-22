-- Do drivers improve?

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q4 CASCADE;

CREATE TABLE q4(
    type VARCHAR(9),
    number INTEGER,
    early FLOAT,
    late FLOAT
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS ValidRides CASCADE;
DROP VIEW IF EXISTS ValidRidesDrivers CASCADE;
DROP VIEW IF EXISTS ExperiencedDrivers CASCADE;
DROP VIEW IF EXISTS TrainedExpDrivers CASCADE;
DROP VIEW IF EXISTS UntrainedExpDrivers CASCADE;
DROP VIEW IF EXISTS Firstday CASCADE;
DROP VIEW IF EXISTS Seocondday CASCADE;
DROP VIEW IF EXISTS Thirdday CASCADE;
DROP VIEW IF EXISTS Fourthday CASCADE; 
DROP VIEW IF EXISTS Fifthday CASCADE; 
DROP VIEW IF EXISTS TrainedEarlyRatings CASCADE; 
DROP VIEW IF EXISTS TrainedLateRatings CASCADE; 
DROP VIEW IF EXISTS UntrainedEarlyRatings CASCADE; 
DROP VIEW IF EXISTS UntrainedLateRatings CASCADE; 
DROP VIEW IF EXISTS TrainedEarlyAvg CASCADE;
DROP VIEW IF EXISTS TrainedLateAvg CASCADE; 
DROP VIEW IF EXISTS UntrainedEarlyAvgCASCADE; 
DROP VIEW IF EXISTS UntrainedLateAvg CASCADE;

-- Define views for your intermediate steps here:
-- Step 1-1. ValidRides are the ride that has been completed dropoff from a request
-- Record request_id of such ride and day which has been requested!
CREATE VIEW ValidRides AS
SELECT Request.request_id, date(Request.datetime) as day
FROM Dropoff join Request on Dropoff.request_id = Request.request_id;

-- Step 1-2. Get the driverID to such valid rides
CREATE VIEW ValidRidesDrivers AS
SELECT ValidRides.request_id, ValidRides.day, ClockedIn.driver_id
FROM ValidRides join Dispatch on ValidRides.request_id = Dispatch.request_id
    join ClockedIn on Dispatch.shift_id = ClockedIn.shift_id;

-- Step 1-3. Experienced Drivers are the drivers who have given at least one ride for each of at least
-- 10 different days. Record their distinct Driver_id's only.
CREATE VIEW ExperiencedDrivers AS
SELECT distinct driver_id  -- already naturally distinct, but making sure
FROM ValidRidesDrivers
GROUP BY driver_id
HAVING count(DISTINCT day) >= 10;

-- Step 2-1. Split the ExperiencedDrivers into two groups(Trained, Untrained)
-- TrainedExpDrivers has a driver_id of Trained Experienced Drivers.
CREATE VIEW TrainedExpDrivers AS
SELECT ExperiencedDrivers.driver_id
FROM ExperiencedDrivers join Driver on Driver.driver_id = ExperiencedDrivers.driver_id
WHERE trained = True;

-- UntrainedExpDrivers has a driver_id of Untrained Experienced Drivers.
CREATE VIEW UntrainedExpDrivers AS
SELECT ExperiencedDrivers.driver_id
FROM ExperiencedDrivers join Driver on Driver.driver_id = ExperiencedDrivers.driver_id
WHERE trained = False;

-- Step 3-0. Fifth day for each of all exp drivers(driver_id)

-- Only containing the first day of the fifth day
CREATE VIEW Firstday AS
SELECT driver_id as did1, min(day) as day1
FROM ValidRidesDrivers
GROUP BY driver_id;


-- Containing second day of the fifth day
CREATE VIEW Secondday AS
SELECT driver_id as did2, max(day) as day2
FROM ValidRidesDrivers AS This
WHERE day <= ALL((SELECT day
                FROM ValidRidesDrivers
                WHERE ValidRidesDrivers.driver_id = This.driver_id)
                EXCEPT
                (SELECT day1 as day
                FROM Firstday
                WHERE did1 = This.driver_id))
GROUP BY driver_id;

-- Containing 3rd day of the fifth day
CREATE VIEW Thirdday AS
SELECT driver_id as did3, max(day) as day3
FROM ValidRidesDrivers AS This
WHERE day <= ALL((SELECT day
                FROM ValidRidesDrivers
                WHERE ValidRidesDrivers.driver_id = This.driver_id)
                EXCEPT
                    ((SELECT day1 as day
                    FROM Firstday
                    WHERE did1 = This.driver_id)
                    UNION
                    (SELECT day2 as day
                    FROM Secondday
                    WHERE did2 = This.driver_id)
                    )
                )
GROUP BY driver_id;


-- Containing 4th day of the fifth day
CREATE VIEW Fourthday AS
SELECT driver_id as did4, max(day) as day4
FROM ValidRidesDrivers AS This
WHERE day <= ALL((SELECT day
                FROM ValidRidesDrivers
                WHERE ValidRidesDrivers.driver_id = This.driver_id)
                EXCEPT(
                    (SELECT day1 as day
                    FROM Firstday
                    WHERE did1 = This.driver_id)
                    UNION
                    (SELECT day2 as day
                    FROM Secondday
                    WHERE did2 = This.driver_id)
                    UNION
                    (SELECT day3 as day
                    FROM Thirdday
                    WHERE did3 = This.driver_id)
                    )
                )
GROUP BY driver_id;

-- Containing 5th day of the fifth day
CREATE VIEW Fifthday AS
SELECT driver_id as did5, max(day) as day5
FROM ValidRidesDrivers AS This
WHERE day <= ALL((SELECT day
                FROM ValidRidesDrivers
                WHERE ValidRidesDrivers.driver_id = This.driver_id)
                EXCEPT(
                    (SELECT day1 as day
                    FROM Firstday
                    WHERE did1 = This.driver_id)
                    UNION
                    (SELECT day2 as day
                    FROM Secondday
                    WHERE did2 = This.driver_id)
                    UNION
                    (SELECT day3 as day
                    FROM Thirdday
                    WHERE did3 = This.driver_id)
                    UNION
                    (SELECT day4 as day
                    FROM Fourthday
                    WHERE did4 = This.driver_id)
                    )
                )
GROUP BY driver_id;


-- Step 3-1. Early Ratings of each Trained Experienced Driver

CREATE VIEW TrainedEarlyRatings AS
SELECT ValidRidesDrivers.driver_id, DriverRating.rating
FROM TrainedExpDrivers join ValidRidesDrivers on 
    TrainedExpDrivers.driver_id = ValidRidesDrivers.driver_id
    join DriverRating on 
    DriverRating.request_id = ValidRidesDrivers.request_id
WHERE ValidRidesDrivers.day <= (SELECT day5 as day
                                FROM Fifthday
                                WHERE did5 = ValidRidesDrivers.driver_id);

-- Step 3-2. Late Ratings of each Trained Experienced Driver
CREATE VIEW TrainedLateRatings AS
SELECT ValidRidesDrivers.driver_id, DriverRating.rating
FROM TrainedExpDrivers join ValidRidesDrivers on 
    TrainedExpDrivers.driver_id = ValidRidesDrivers.driver_id
    join DriverRating on 
    DriverRating.request_id = ValidRidesDrivers.request_id
WHERE ValidRidesDrivers.day > (SELECT day5 as day
                                FROM Fifthday
                                WHERE did5 = ValidRidesDrivers.driver_id);

-- Step 3-3. Early Ratings of each Untrained Experienced Driver
CREATE VIEW UntrainedEarlyRatings AS
SELECT ValidRidesDrivers.driver_id, DriverRating.rating
FROM UntrainedExpDrivers join ValidRidesDrivers on 
    UntrainedExpDrivers.driver_id = ValidRidesDrivers.driver_id
    join DriverRating on 
    DriverRating.request_id =ValidRidesDrivers.request_id
WHERE ValidRidesDrivers.day <= (SELECT day5 as day
                                FROM Fifthday
                                WHERE did5 = ValidRidesDrivers.driver_id);

-- Step 3-4. Late Ratings of each Untrained Experienced Driver

CREATE VIEW UntrainedLateRatings AS
SELECT ValidRidesDrivers.driver_id, DriverRating.rating
FROM UntrainedExpDrivers join ValidRidesDrivers on 
    UntrainedExpDrivers.driver_id = ValidRidesDrivers.driver_id
    join DriverRating on 
    DriverRating.request_id = ValidRidesDrivers.request_id
WHERE ValidRidesDrivers.day > (SELECT day5 as day
                                FROM Fifthday
                                WHERE did5 = ValidRidesDrivers.driver_id);

-- Step 3-5. Early Average of each Trained Experienced Driver
CREATE VIEW TrainedEarlyAvg AS
SELECT driver_id, avg(rating) AS EAforeachdriver
FROM TrainedEarlyRatings
GROUP BY driver_id;

-- Step 3-6. Late Average of each Trained Experienced Driver
CREATE VIEW TrainedLateAvg AS
SELECT driver_id, avg(rating) AS LAforeachdriver
FROM TrainedLateRatings
GROUP BY driver_id;

-- Step 3-7. Early Average of each Untrained Experienced Driver
CREATE VIEW UntrainedEarlyAvg AS
SELECT driver_id, avg(rating) AS EAforeachdriver
FROM UntrainedEarlyRatings
GROUP BY driver_id;

-- Step 3-8. Early Average of each Untrained Experienced Driver
CREATE VIEW UntrainedLateAvg AS
SELECT driver_id, avg(rating) AS LAforeachdriver
FROM UntrainedLateRatings
GROUP BY driver_id;


-- -- airbag in case there is no data
-- INSERT INTO TrainedEarlyAvg VALUES
-- (NULL, NULL);

-- -- airbag in case there is no data
-- INSERT INTO TrainedLateAvg VALUES
-- (NULL, NULL);

-- -- airbag in case there is no data
-- INSERT INTO UntrainedEarlyAvg VALUES
-- (NULL, NULL);

-- -- airbag in case there is no data
-- INSERT INTO UntrainedLateAvg VALUES
-- (NULL, NULL);

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q4
SELECT 'trained' as type, count(distinct TrainedEarlyAvg.driver_id) as number, NULL as early, NULL as late
FROM TrainedEarlyAvg;

UPDATE q4
SET early = (SELECT avg(EAforeachdriver)
FROM TrainedEarlyAvg join TrainedLateAvg on TrainedEarlyAvg.driver_id = TrainedLateAvg.driver_id), 

late = (SELECT avg(LAforeachdriver) 
FROM TrainedEarlyAvg join TrainedLateAvg on TrainedEarlyAvg.driver_id = TrainedLateAvg.driver_id)

WHERE type = 'trained'
;

INSERT INTO q4
SELECT 'untrained' as type, count(distinct UntrainedEarlyAvg.driver_id) as number, NULL as early, NULL as late
FROM UntrainedEarlyAvg;

UPDATE q4
SET early = (SELECT avg(EAforeachdriver)as early
FROM UntrainedEarlyAvg join UntrainedLateAvg on UntrainedEarlyAvg.driver_id = UntrainedLateAvg.driver_id), 

late = (SELECT avg(LAforeachdriver) FROM UntrainedEarlyAvg join UntrainedLateAvg on UntrainedEarlyAvg.driver_id = UntrainedLateAvg.driver_id)

WHERE type = 'untrained';