
SET SEARCH_PATH TO ticketchema, public;

DROP TABLE IF EXISTS UserPurchases CASCADE;

--Number of tickets purchased by each user
CREATE TABLE UserPurchases(
	username character varying(30),
	tickets integer

);
-- The amount of tickets purchased by each user
INSERT INTO UserPurchases
SELECT username, count(*) AS tickets
FROM PurchasedTicket
GROUP BY username;

--The username(s) who purchased the max amount of tickets
SELECT username FROM UserPurchases WHERE tickets =
	(
	 SELECT MAX(tickets)
	 FROM UserPurchases
	 );
