
SET SEARCH_PATH TO ticketchema, public;

-- The percent of seats that are accessible at each venue
SELECT v.vid,v.venue_name,
		count(CASE WHEN s.accessibility = TRUE THEN 1 END) *100/count(*)
		AS percent_seats_accessible
FROM Seat s JOIN Section d ON s.section_id = d.section_id
	        JOIN Venue v ON v.vid = d.vid
GROUP BY v.vid ;


