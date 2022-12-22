-- Frequent riders.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q6 CASCADE;

CREATE TABLE q6(
    client_id INTEGER,
    year CHAR(4),
    rides INTEGER
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS ValidRequests CASCADE;
DROP VIEW IF EXISTS ValidYears CASCADE;
DROP TABLE IF EXISTS YearClientRidenum CASCADE;
DROP VIEW IF EXISTS MAX1 CASCADE;
DROP VIEW IF EXISTS MAX2 CASCADE;
DROP VIEW IF EXISTS MAX3 CASCADE;
DROP VIEW IF EXISTS MIN1 CASCADE;
DROP VIEW IF EXISTS MIN2 CASCADE;
DROP VIEW IF EXISTS MIN3 CASCADE;



-- Define views for your intermediate steps here:

-- ValidRequests are requests that were completed, i.e., can be considered as rides.
-- request_id, client_id, year of the such requests.

CREATE VIEW ValidRequests AS
SELECT Request.request_id, client_id, extract(year from Request.datetime) as year
FROM DropOff join Request on Dropoff.request_id = Request.request_id;

-- VALIDYEARS should contain all years, 
-- that has at least one client that had a ride in that year.
-- ( NOTE: year in ValidRequests are automatically valid years. This is for readibility & convenience in further processes.)
CREATE VIEW ValidYears AS
SELECT distinct year
FROM ValidRequests;

-- How many rides that a client had in each valid year?
-- For each year, ALL client should be considered(including ones with 0 rides), to compute ridenum.

-- Part1. Get all the clients that have no ride in certain year
DROP VIEW IF EXISTS Client0rideinThatYear CASCADE;
CREATE VIEW Client0rideinThatYear AS
SELECT distinct Client.client_id, ValidYears.year, 0 as ridenum  -- just to make sure, but it should be distinct in the first place
FROM Client, ValidYears
WHERE ValidYears.year not in (SELECT year
                            FROM ValidRequests
                            WHERE Client.client_id = ValidRequests.client_id);


-- Part 2. add all clients with the at least one corresponding rides in corresponding year
DROP VIEW IF EXISTS YearClientRidenumAtleast1;
CREATE VIEW YearClientRidenumAtleast1 AS
SELECT client_id,-- OTHER METHOD THAT I COULDN'T RESOLVE: as ycrclient, -- this renaming is to reference in this null case below.
        -- (CASE WHEN yearIS NOT NULL THEN 
        --         year 
        --     ELSE -- find a year that <client> not in the client_id of ValidRequests
        --         (SELECT min(this_year)
        --         FROM Client0rideinThatYear
        --         WHERE this_client = client)
        --         -- (CASE WHEN client not int (select client_id from )theres no client in the table THEN give min(year) in ValidYears
        --         -- ELSE  -- there is a client in the valid requests table so we should avoid that
        --         -- )
        -- END ) as 
        year, 
        count(request_id) as ridenum
FROM  ValidRequests-- Client LEFT JOIN ValidRequests ON ValidRequests.client_id = Client.client_id
GROUP BY year, client_id;


-- Inserting Part1 and Part2 to a new table
DROP TABLE IF EXISTS YearClientRidenum CASCADE;
CREATE TABLE YearClientRidenum(client_id integer not null, year integer not null, ridenum integer not null);
INSERT INTO YearClientRidenum(SELECT client_id, year, ridenum
                                FROM YearClientRidenumAtleast1);
INSERT INTO YearClientRidenum (SELECT client_id, year, 0
                                FROM Client0rideinThatYear);


-- MAX ridenum
CREATE VIEW MAX1 AS
SELECT distinct max(ridenum) as ridenum
FROM YearClientRidenum;

-- 2nd Max ridenum
CREATE VIEW MAX2 AS
SELECT distinct ridenum
FROM YearClientRidenum
WHERE ridenum >= ALL (SELECT ridenum
                FROM YearClientRidenum
                EXCEPT
                SELECT ridenum
                FROM MAX1);

-- 3rd Max ridenum
-- NOTE THIS INCLUDES ALL (1)maximum ridenum, (2)second maximum, (3) 3rd maximum
CREATE VIEW MAX3 AS
SELECT distinct ridenum
FROM YearClientRidenum
WHERE ridenum >= ALL (SELECT ridenum
                FROM YearClientRidenum
                EXCEPT (
                    (SELECT ridenum FROM MAX1) 
                    UNION 
                    (SELECT ridenum FROM MAX2)
                    )
                );


-- MIN ridenum
CREATE VIEW MIN1 AS
SELECT distinct min(ridenum) as ridenum
FROM YearClientRidenum;

-- 2nd Min ridenum
CREATE VIEW MIN2 AS
SELECT distinct ridenum
FROM YearClientRidenum
WHERE ridenum <= ALL (SELECT ridenum
                FROM YearClientRidenum
                EXCEPT
                SELECT ridenum
                FROM MIN1);

-- 3rd MIN ridenum
-- NOTE THIS INCLUDES ALL (1)min ridenum, (2)second min, (3) 3rd min
CREATE VIEW MIN3 AS
SELECT distinct ridenum
FROM YearClientRidenum
WHERE ridenum <= ALL (SELECT ridenum
                FROM YearClientRidenum
                EXCEPT (
                    (SELECT ridenum FROM MIN1) 
                    UNION 
                    (SELECT ridenum FROM MIN2)
                    )
                );

-- Your query that answers the question goes below the "insert into" line:
-- TOP3 and BOTTOM 3
INSERT INTO q6
SELECT DISTINCT client_id, year, ridenum as rides
FROM YearClientRidenum
WHERE ridenum in (SELECT * FROM MAX3) or ridenum in (SELECT * FROM MIN3);

-- Finally, we will get rid of the additional table we have made in the steps.
-- Moved to the first DROP lines.