SET SEARCH_PATH TO ticketchema;

INSERT INTO Owner(contact, owner_name) VALUES
    ('7788702678', 'The Corporation of Massey Hall and Roy Thomson Hall');

INSERT INTO Venue(venue_name, city, street_address, owner_contact) VALUES
    ('Massey Hall', 'Toronto', '178 Victoria Street', '7788702678');

INSERT INTO Section(section_name, vid) VALUES
    ('floor', 1),
    ('balcony', 1);

INSERT INTO Seat(seat_name, section_id, accessibility) VALUES
    ('A1', 1, true),
    ('A2', 1, true),
    ('A3', 1, true);
INSERT INTO Seat(seat_name, section_id) VALUES
    ('A4', 1),
    ('A5', 1),
    ('A6', 1),
    ('A7', 1);
INSERT INTO Seat(seat_name, section_id, accessibility) VALUES
    ('A8', 1, true),
    ('A9', 1, true),
    ('A10', 1, true);
INSERT INTO Seat(seat_name, section_id) VALUES
    ('B1', 1),
    ('B2', 1),
    ('B3', 1),
    ('B4', 1),
    ('B5', 1),
    ('B6', 1),
    ('B7', 1),
    ('B8', 1),
    ('B9', 1),
    ('B10', 1),

    ('C1', 2),
    ('C2', 2),
    ('C3', 2),
    ('C4', 2),
    ('C5', 2);

INSERT INTO Venue(venue_name, city, street_address, owner_contact) VALUES
    ('Roy Thomson Hall', 'Toronto', '60 Simcoe St', '7788702678');

INSERT INTO Section(section_name, vid) VALUES ('main hall', 2);

INSERT INTO Seat(seat_name, section_id, accessibility) VALUES
      ('AA1', 3, false),
      ('AA2', 3, false),
      ('AA3', 3, false);

INSERT INTO Seat(seat_name, section_id) VALUES
      ('BB1', 3),
      ('BB2', 3),
      ('BB3', 3),
      ('BB4', 3),
      ('BB5', 3),
      ('BB6', 3),
      ('BB7', 3),
      ('BB8', 3),

      ('CC1', 3),
      ('CC2', 3),
      ('CC3', 3),
      ('CC4', 3),
      ('CC5', 3),
      ('CC6', 3),
      ('CC7', 3),
      ('CC8', 3),
      ('CC9', 3),
      ('CC10', 3);

INSERT INTO Owner (contact, owner_name) VALUES
    ('7788701234', 'Maple Leaf Sports & Entertainment');


INSERT INTO Venue(venue_name, city, street_address, owner_contact) VALUES
    ('ScotiaBank Arena', 'Toronto', '40 Bay St', '7788701234');

INSERT INTO Section (section_name, vid) VALUES
    ('100', 3),
    ('200', 3),
    ('300', 3);

INSERT INTO Seat (seat_name, section_id, accessibility) VALUES
    ('row 1, seat 1', 4, true),
    ('row 1, seat 2', 4, true),
    ('row 1, seat 3', 4, true),
    ('row 1, seat 4', 4, true),
    ('row 1, seat 5', 4, true),
    ('row 2, seat 1', 4, true),
    ('row 2, seat 2', 4, true),
    ('row 2, seat 3', 4, true),
    ('row 2, seat 4', 4, true),
    ('row 2, seat 5', 4, true);

INSERT INTO Seat (seat_name, section_id) VALUES
   ('row 1, seat 1', 5),
   ('row 1, seat 2', 5),
   ('row 1, seat 3', 5),
   ('row 1, seat 4', 5),
   ('row 1, seat 5', 5),
   ('row 2, seat 1', 5),
   ('row 2, seat 2', 5),
   ('row 2, seat 3', 5),
   ('row 2, seat 4', 5),
   ('row 2, seat 5', 5);

INSERT INTO Seat (seat_name, section_id) VALUES
    ('row 1, seat 1', 6),
    ('row 1, seat 2', 6),
    ('row 1, seat 3', 6),
    ('row 1, seat 4', 6),
    ('row 1, seat 5', 6),
    ('row 2, seat 1', 6),
    ('row 2, seat 2', 6),
    ('row 2, seat 3', 6),
    ('row 2, seat 4', 6),
    ('row 2, seat 5', 6);


INSERT INTO Concert (concert_name, vid, datetime) VALUES
    ('Ron Sexmith', 1, '2022-12-03 19:30');

INSERT INTO Prices (vid, datetime, section_id, price) VALUES
    (1, '2022-12-03 19:30', 1, 130),
    (1, '2022-12-03 19:30', 2, 99);


INSERT INTO Concert (concert_name, vid, datetime) VALUES
    ('Women''s Blues Review', 1, '2022-11-25 20:00');

INSERT INTO Prices (vid, datetime, section_id, price) VALUES
      (1, '2022-11-25 20:00', 1, 150),
      (1, '2022-11-25 20:00', 2, 99);




INSERT INTO Concert (concert_name, vid, datetime) VALUES
    ('Mariah Carey - Merry Christmas to all', 3,
     '2022-12-09 20:00'),
    ('Mariah Carey - Merry Christmas to all', 3,
     '2022-12-11 20:00');

INSERT INTO Prices (vid, datetime, section_id, price) VALUES
      (3, '2022-12-09 20:00', 4, 986),
      (3, '2022-12-09 20:00', 5, 244),
      (3, '2022-12-09 20:00', 6, 176),
      (3, '2022-12-11 20:00', 4, 936),
      (3, '2022-12-11 20:00', 5, 194),
      (3, '2022-12-11 20:00', 6, 126);



-- floor 1
-- balcony 2
-- main hall 3
-- 100 4
-- 200 5
-- 300 6

INSERT INTO Concert (concert_name, vid, datetime) VALUES
      ('Elf in Concert', 2,
       '2022-12-09 19:30'),
      ('Elf in Concert', 2,
       '2022-12-10 14:30'),
      ('Elf in Concert', 2,
       '2022-12-10 19:30');

INSERT INTO Prices (vid, datetime, section_id, price) VALUES
      (2, '2022-12-09 19:30', 3, 159),
      (2, '2022-12-10 14:30', 3, 159),
      (2, '2022-12-10 19:30', 3, 159);


INSERT INTO Users (username) VALUES
      ('ahightower'),
      ('d_targaryen'),
      ('cristonc');

-- TODO : Make a ticket object for each seat!

INSERT INTO PurchasedTicket(seat_name, section_id, vid, concert_datetime,
                            username, purchase_datetime) VALUES
      ('A5', 1, 1, '2022-11-25 20:00', 'ahightower', '2022-11-20');


INSERT INTO PurchasedTicket(seat_name, section_id, vid, concert_datetime,
                            username, purchase_datetime) VALUES
    ('B3', 1, 1, '2022-12-03 19:30', 'd_targaryen', '2022-12-01'),
    ('BB7', 3, 2, '2022-12-10 19:30', 'd_targaryen', '2022-12-01'),
    ('row 1, seat 3', 4, 3, '2022-12-09 20:00', 'cristonc', '2022-12-01'),
    ('row 2, seat 3', 5, 3, '2022-12-11 20:00', 'cristonc', '2022-12-01'),
    ('row 2, seat 4', 5, 3, '2022-12-11 20:00', 'cristonc', '2022-12-01');
