
SET SEARCH_PATH TO ticketchema, public;

-- The number of venues owned by each owner
SELECT owner_name AS owner, contact AS contact, count(*) AS venues_owned
FROM Owner JOIN Venue ON Owner.contact = Venue.owner_contact
GROUP BY contact, owner_name;

