
SET SEARCH_PATH TO ticketchema, public;

DROP VIEW IF EXISTS TicketsSold CASCADE;
DROP VIEW IF EXISTS SeatCount CASCADE;

-- The total amount (dollars) of tickets sold for each concert
CREATE VIEW TicketsSold AS
SELECT c.concert_name,c.datetime, c.vid, sum(prices.price) AS total_value,
	   count(*) AS seats_sold
FROM PurchasedTicket p
    JOIN Concert c ON p.vid = c.vid AND c.datetime = p.concert_datetime
	JOIN Prices ON Prices.vid = c.vid AND Prices.datetime = c.datetime
	                   AND Prices.section_id = p.section_id
GROUP BY c.datetime, c.vid, c.concert_name;

-- The number of seats at each venue
CREATE VIEW SeatCount AS
SELECT v.vid, count(*) AS seat_count
FROM Seat s JOIN Section d ON s.section_id = d.section_id
	        JOIN Venue v ON v.vid = d.vid
GROUP BY v.vid;

-- The percent of venue sold for each concert
SELECT TicketsSold.concert_name, v.venue_name AS venue, TicketsSold.datetime,
	   TicketsSold.total_value,
	   (TicketsSold.seats_sold * 100/SeatCount.seat_count) AS percent_sold
FROM TicketsSold JOIN SeatCount ON TicketsSold.vid = SeatCount.vid
				 JOIN Venue v ON v.vid = TicketsSold.vid;

