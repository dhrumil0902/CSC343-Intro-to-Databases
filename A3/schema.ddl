DROP SCHEMA IF EXISTS ticketchema CASCADE;
CREATE SCHEMA ticketchema;
SET SEARCH_PATH TO ticketchema;

-- COULD NOT: What constraints from the domain specification could not be
-- enforced without assertions or triggers, if any?
    -- 1. Every venue needs to have at least 10 seats.

-- DID NOT: What constraints from the domain specification could have been
-- enforced without assertions or triggers, but were not enforced, if any?
-- Why not?
    -- None.

-- EXTRA CONSTRAINTS: What additional constraints that we didn’t mention did you
-- enforce, if any?
    -- EXTRA CONSTRAINT1.
    -- There is no negative price ticket, as it doesn't make sense to give
    -- money to people who buy a ticket for some sections of the concerts.
    --
    -- EXTRA CONSTRAINT2.
    -- Purchase date is before(less than) the concert datetime.
    --
    -- 3. All of ASSUMPTION0, ASSUMPTION1, ASSUMPTION2, ASSUMPTION3-2,
    -- ASSUMPTION4, and ASSUMPTION5 listed below are enforced.
    --
    -- 4. The following is a list of other constraints we thought to be trivial
    -- but not explicitly mentioned. These are often described in comments as
    -- to prevent the non-sense cases... etc.
        -- 1)
        -- A non existing user cannot buy a ticket.
        -- 2)
        -- type constraints (e.g., the maximum length of the characters)
        -- 3)
        -- A section cannot be in the non-existing venue.
        -- 4)
        -- A seat exists only if it is specified that the given venue has the
        -- corresponding and existing section.
        -- 5)
        -- A concert cannot be held at a non-existing venue.
        -- 6)
        -- A price of a ticket is declared only if an existing section specified
        -- is in a venue of an existing concert specified.
        -- 7)
        -- A user cannot buy a ticket of ticket-kind(concert-section) whose
        -- price is not declared.
            -- (Another interpretation: (i) A ticket-kind exists only if
            -- the price is declared. (ii) A ticket exists only if its
            -- ticket-kind exists and the seat is offered by that ticket-kind.
            -- (iii). A user cannot buy a non-existing ticket.)



-- ASSUMPTION: What assumptions did you make?
-- ASSUMPTION0.
-- Only valid phone numbers are given.
--
-- ASSUMPTION1.
-- There is at most one venue with each combination of city-street_address-venue
-- name, i.e., there is at most one venue that is in a certain city at a certain
-- street and has a certain name. There can be many with the sub combination.
-- We didn't make an assumption that there is at most one venue at city-street
-- address because there can be a small venue(like one floor of the building
-- (>10 seats still). And one can want to have one more venue in different floor
-- of the building. In that case, it sounds naming the new venue differently
-- from the existing one is necessary to prevent confusion.
--
-- ASSUMPTION2. Each ticket is for one unique concert seat.
-- (But this is quite mentioned, as "the price of a ticket depends the concert
-- and the section in which the seat is located in the venue.")
--
-- ASSUMPTION3. Each 1 seat that the concert offers(all seats of the venue in
-- our assignment) has exactly 1 corresponding ticket, given the price for that
-- ticket-kind is declared.
    -- ASSUMPTION3-1: (<1) at least 1 corresponding ticket, given ticket-kind.
        -- Because it is not reasonable to have unsellable seats for a ticket
        -- selling business, which would probably aim for the maximum profit.
        -- In the special case where the seller wants to have some "reserved
        -- seats":
            -- For the reserved seat, it is quite typical to have specific
            -- section just for the reserved seats. Then, the seller can set
            -- price of that reserved section of that concert free and make the
            -- corresponding purchases for all those seats, in advance. So this
            -- assumption is still valid to make.
        -- NOTE: This assumption is not enforced, but by having this assumption
        -- lets us keep just the purchased tickets instead of all possible
        -- tickets(each concert-section has all seats with the same prices for
        -- all seats).
    -- ASSUMPTION3-2: (>1) at most 1 corresponding ticket, given the ticket-kind
        -- Because it is non sense two or more people sitting in one seat during
        -- the concert.
    --
-- ASSUMPTION4. A purchase of a certain ticket can be made at most once, i.e.,
-- at most one user can buy each ticket.
    -- Followed by ASSUMPTION3-2, it is reasonable to make this assumption.
--
-- ASSUMPTION5. A venue only exists if the given owner exists.
    -- Because a venue with non-existing owner is not reasonable at all.
--
-- ASSUMPTION6. The same phone number is given in the same format.
    -- TYPE phone_number allows various formats of phone number because in the
    -- real app, there should be a different reason to choose certain format
    -- more preferable than the other(e.g., readability, space(length), etc.
    -- depending on the use), but not to have so many possible values for the
    -- same phone number in the real world.
    -- Note, this is left as a front-end's responsibility, instead of being
    -- enforced here.
        -- This is also reasonable since for a different front-end
        -- (or an actual app), it should be their choice and responsibility to
        -- allow certain formats only, or at least check if the same number is
        -- given in a unified format. So everytime before putting the value into
        -- a database, front-end would need a checker.
    -- This assumption was mainly to prevent the case where the same phone
    -- number is given in multiple formats so that the ddl cannot keep each
    -- phone number unique even though it is PRIMARY KEY of the table.(it will
    -- consider those two differently, which may an unwanted behaviour).
    -- Still, this is still a reasonable assumption to make too as there would
    -- be no point of having various forms of the same value in the database,
    -- if they will eventually considered to be the same.


-- < TYPE(DOMAIN) phone_number >
-- The possible values for the type phone number.
-- It is restricted to only contain number, hyphen, space, or at most one plus
-- sign in front (for international number).
-- Using ASSUMPTION0, we have constructed checker that:
-- COUNTRY CODE 1 :
-- For phone numbers of Canada or U.S., which uses country code (+)1, it has a
-- format for canada after optional +1, 3 area code, followed by 4 digits, and
-- the 4 digits. We allow to have hyphens or spaces.
-- OTHER COUNTRY CODE (not 1) :
-- For these, it must include the country code(which has longest length of 3)
-- with the optional + in front of it. Followed by a country code, we allow from
-- the shortest length(4) digits to the longest length(15) of digits of phone
-- number plus at most 3 hyphens or spaces, each being in between digits.
-- Combining, in maximum: 1 plus sign + 3 digits of country code + 15 digits +
-- 3 hyphens or spaces each being between numbers = we allowed 1+3+15+3 = 22
-- Default value is set to NULL for the future use where phone_number is not a
-- required field but optional(Unlike our example, where we force NOT NULL).
DROP DOMAIN IF EXISTS phone_number CASCADE;
CREATE DOMAIN phone_number AS varchar(22)
    DEFAULT NULL
    CHECK ( VALUE  ~
            '^[\+]?[1]{0,1}[-|\s]?[0-9]{3}[-|\s]?[0-9]{3}[-|\s]?[0-9]{4}$'
            OR
            VALUE ~
            '^[\+]?(?!(?:1))\d{1,3}[-|\s]?[0-9]+[-|\s]?[0-9]+[-|\s]?[0-9]{2,}$'
          );
-- < TABLE Owner >
-- A owner(person/organization) that holds venue(s).
--      contact: phone number of the owner.
            -- set to be PRIMARY KEY as at most one owner can have the same
            -- phone number; we can use it as an identifier.
--      owner_name: name of the owner
            -- not UNIQUE as there can be multiple owner that has the same name
            -- did not specify the length of the string, because there should be
            -- freedom in length of their own name.
CREATE TABLE Owner (
                       contact phone_number PRIMARY KEY,
                       owner_name varchar NOT NULL
);


-- < SEQUENCE vid_seq >
-- a sequence of vid that we use to get a unique value of vid for each venue.
DROP SEQUENCE IF EXISTS vid_seq CASCADE;
CREATE SEQUENCE vid_seq;

-- < TABLE Venue >
-- A venue that is located in certain city and at street address and
-- has owner.
--      vid: an id of each venue
            -- set to be PRIMARY KEY as we will use it to mean one specific
            -- venue by this id outside of this table, but did not want to carry
            -- all city-street_address-venue_name every time.
--      venue_name: a name of the venue
            -- again, we did not specify the length of the string, because there
            -- should be freedom in length of their own name.
--      city: a city name of the venue
            -- the length of the city name is set to be 58, which is the length
            -- of the 2nd longest name city's name (the most longest can be
            -- shorten, i.e., written as Bangkok, which is 5 characters)
--      street_address: a street address of the venue
            -- the length of the street address is set to be 46, which is the
            -- maximum character limit in the first address line that is used
            -- in USPS/UPS/FedEx
-- Following the ASSUMPTION 1, combination of (city, street_address, venue_name)
-- should be unique, and we enforced it.
--      owner_contact: an owner information of the venue. Specifically, it is a
--                      contact of the owner as it is all needed. One can look
--                      up his/her/its name if wanted, using the contact as it
--                      is unique identifier in the Owner table.
CREATE TABLE Venue (
                       vid integer DEFAULT NEXTVAL('vid_seq') PRIMARY KEY,
                       venue_name varchar NOT NULL,
                       city varchar(58) NOT NULL,
                       street_address varchar(46) NOT NULL,
                       UNIQUE (city, street_address, venue_name),
                       owner_contact phone_number NOT NULL REFERENCES Owner
);


-- < TABLE Concert >
-- A concert that has its name and holds at a corresponding venue.
--      concert_name: name of the concert
            -- following the description, concert names are not unique
            -- we did not specify the length of the string, because there
            -- should be freedom in length of their concert name. Even in
            -- given data, there exists a very long concert name, as well.
--      vid: vid of the venue that the concert is happening at
            -- this references vid of the Venue table as it is non sense if a
            -- concert is happening at a non-existing venue. It should be one of
            -- the existing venues (in Venue).
--      datetime: date and time of the concert
-- Combination of (vid, datetime) is set to be PRIMARY KEY following reasons:
    -- By the given fact, a venue can only have one concert at a given time.
    -- Meaning it does not make sense to have more than one concert in a certain
    -- venue at a certain datetime. Or equivalently, there should be at most one
    -- concert in a certain venue at a certain datetime.
-- So we can use a combination of vid and datetime as a identifier of a concert,
-- i.e., use these two information to refer exactly one specific concert.
-- +) Note we didn't put this as an assumption because we just got it from the
-- given fact.
CREATE TABLE Concert (
                         concert_name varchar NOT NULL,
                         vid integer NOT NULL REFERENCES Venue(vid),
                         datetime timestamp NOT NULL,
                         PRIMARY KEY (vid, datetime)
);


-- < SEQUENCE section_id_seq >
-- a sequence of section id that we use to get a unique value of section_id for
-- each section.
DROP SEQUENCE IF EXISTS section_id_seq CASCADE;
CREATE SEQUENCE section_id_seq;


-- < TABLE Section >
-- A section that belongs to a venue.
-- ( So, for instance, for two sections that both have the same name but in
-- different venue is considered as two distinct sections. )
--      section_id: a unique identifier of this section. Each section has a
--      different section_id.
            -- And therefore, it is set as a PRIMARY KEY.
--      section_name: a name of the section.
            -- we restricted the length of the string not to be longer than 20
            -- characters, because for section name, it is non sense to have
            -- super long names for each section of the concert as it is really
            -- intended to guide user to a correct seat.
            -- But we gave a generosity till 20 for some special cases.
--      vid: a vid of the venue that this section belongs to.
            -- this references vid of the Venue table as it is non sense if we
            -- are to record a section of a non-existing venue. It should be one
            -- of the existing venues (in Venue).
-- The combination (section_name, vid) is set to be UNIQUE as by the given fact
-- "Each section has a name that is unique to that venue, but another venue
-- might use the same section name."
-- +) Similarly with Concert, we could have used this as an identifier and put
-- this combination PRIMARY KEY instead of creating section_id, but we found
-- carrying one attribute section_id only is more concise and there are places
-- where we do not really need both information(e.g., TABLE Seat).
-- The combination (section_id, vid) is set to be UNIQUE to be able to use a
-- foreign key constraint in TABLE Seat. We know it is trivial as section_id is
-- already declared as a key, but it was really needed to enforce the foreign
-- key constraint in Seat. An explanation for this would be written under Seat.
CREATE TABLE Section (
                        section_id integer DEFAULT NEXTVAL('section_id_seq')
                            PRIMARY KEY,
                        section_name varchar(20) NOT NULL, -- long name nonsense
                        vid integer NOT NULL REFERENCES Venue(vid),
                        UNIQUE (section_name, vid),
                        UNIQUE (section_id, vid) -- we know this is
                                                 -- automatically unique,
                                                 -- but we still need it as
                                                 -- explained above.
);


-- < TABLE Seat >
-- A seat that is in a certain section(specific section of specific venue).
-- ( Similarly with Section, for two seats that both have the same name but in
-- different section(section_id) is considered as two distinct seats. )
--      seat_name: name of the seat
            -- we restricted the length of the string not to be longer than 20
            -- characters, because for seat name, it is non sense to have long
            -- names for each seat of the concert as it is intended to guide
            -- user to a correct seat among at least 10 seats. We gave a little
            -- generosity till 20 for some special cases.
--      section_id: id of the section that this seat belongs to.
            -- this references section_id of the Section table as it is non-
            -- sense if we are to record a seat of a non-existing section.
            -- It should be one of the existing sections(section_id which refers
            -- to a section of specific section_name-vid).
-- The combination of (seat_name, section_id) is set as PRIMARY KEY as by the
-- given fact, "seat names do not repeat within the same section in a venue. But
-- two different sections may have seats with the same name." So it is unique
-- and we can use this combination of information as a primary key.
--      accessibility: boolean that determines if this seat is accessible
            -- the default value is set to be FALSE following the answer to the
            -- piazza post @659.
CREATE TABLE Seat (
                      seat_name varchar(20) NOT NULL, -- long name is non-sense
                      section_id integer NOT NULL REFERENCES Section,
                      PRIMARY KEY (seat_name, section_id),
                      accessibility boolean NOT NULL DEFAULT FALSE
);


-- < TABLE Prices >
-- A price of a ticket-kind(concert, section).
-- As "(*) the price of a ticket depends the *concert* and the *section* in
-- which the seat is located in the venue", e really need (1) a concert
-- information and (2) a section information for each price.
--
-- 1) Concert Information
--      vid: a venue(id) where a concert is held
--      datetime: date and time of a concert
-- (vid, datetime) references Concert(vid, datetime). This is to make sure that
-- we keep prices of (the section at) the *existing concert*. Note this can be
-- enforced as (vid, datetime) was a primary key in Concert table.
--
-- 2) Section Information
--      section_id: a section where this ticket kind belongs to.
            -- we do not need to keep seat, as (*). It would be redundant if we
            -- kept specific seat information as all concert-section
            -- combinations have the same price.
-- (section_id, vid) references Section(section_id, vid). This is to ensure that
-- the price is recorded for the existing section and it is in the venue that
-- the concert is happening(which is specified as vid)(**). Referencing just the
-- section id is not sufficient. We need vid to prevent the case when someone
-- tries to record a price of a ticket to a concert and a section but the
-- section does not belong to a venue that the concert is happening.
-- And this is why we had declared (section_id, vid) UNIQUE in Section table
-- even though it is automatically unique with PRIMARY KEY section_id.
--
-- Design decision:
-- Note we could have used a new attribute concert_id as a primary key instead
-- of carrying (vid, datetime) all the time to refer a specific concert. If we
-- had done that, we wouldn't need datetime information, which is unnecessary.
-- However, as this is the only place we would need a concert information and
-- in here, we still need vid(venue information) to make sure (**), we need
-- vid and cid instead of vid and datetime. On the other hand, making cid is
-- just adding one more additional attribute(concert_id) to Concert table.
-- Therefore, we have decided to set (vid, datetime) as primary key of Concert
-- and use the combination of two in this table as well.
--
-- If we had used cid, we will need a checker in this table using subquery
-- as:
-- constraint sectionNotInConcert
--                         check ( section in (SELECT section
--                                         FROM Concert JOIN Seat
--                                             ON Concert.vid = Seat.vid
--                                         WHERE Concert.cid = Ticket.cid) )
-- However, use of a subquery in checker like this is not supported by psql.
-- So we had to find the other way, which was the way we did: to carry vid as a
-- part of information of the concert. We know this can cause a redundancy,
-- (not about the magic trick but we should input redundant data for example)
-- but we chose to enforce a constraint as we thought it is more important in
-- this case.
--
--      price: a price of a ticket kind in $
            -- type is float instead of integer in case the price is specified
            -- in cents
-- Constraint noNegativePrice: checks if a price is non negative.
-- as negative price for a ticket doesn't make sense(EXTRA CONSTRAINT1). There
-- can be some free concerts, so we have decided to allow price to be 0.
-- PRIMARY KEY of this table is a combination (vid, datetime, section_id),
-- as said, there can be one price for each concert-section combination.
CREATE TABLE Prices (
                       vid integer NOT NULL,
                       datetime timestamp NOT NULL, -- cid but doesn't help much
                       FOREIGN KEY (vid, datetime) REFERENCES
                           Concert(vid, datetime), -- concert info
                       section_id integer NOT NULL,
                       FOREIGN KEY (section_id, vid) REFERENCES
                           Section(section_id, vid), -- section info
                       price float NOT NULL,
                       CONSTRAINT noNegativePrice -- allowing free concerts
                           CHECK ( price >= 0 ),
                       PRIMARY KEY (vid, datetime, section_id)
);




-- < TABLE USER >
-- A user of the app, with username.
--      username: a username of the user
            -- The length of the username is restricted to maximum 30, because
            -- having too long username is non-sense for the ideal app
            -- operation, but allow as much as those user-related famous apps,
            -- like Instagram, do.
CREATE TABLE Users (
    username varchar(30) PRIMARY KEY

);


-- < TABLE PurchasedTicket >
-- A ticket sold. Note it doesn't contain unsold ticket.
--      seat_name: seat name of the ticket's seat.
--      section_id: section id of the ticket's seat.
-- The combination of above 2, (seat_name, section_id), references
-- Seat(seat_name, section_id) so that this seat that a user tried to buy a
-- ticket for exists. This prevents a case of a user buying a ticket
-- that is not existing.
--      vid: venue(vid) of the ticket's seat = where the concert is held
--      concert_datetime: date and time when the concert is held
-- The combination of above 3, (vid, concert_datetime, section_id),
-- references Prices(vid, concert_datetime, section_id), so that we can enforce
-- users buy only the valid ticket-kind. If a certain ticket-kind doesn't exist
-- (-- meaning it is not recorded in the Price table), a user cannot buy one.
-- The combination of all the 5 attributes listed above is set as PRIMARY KEY.
-- The reasons for this is (1) ASSUMPTION4: a purchase of a ticket, which is
-- specified by each value of the 4 attributes, can only be made at most one
-- user AND (2) there is no point of making new attribute(e.g. id) because as it
-- wouldn't be used, it will be just an additional information.
--      username: a username that bought the ticket
            -- references Users(username) as it is non sense to allow a
            -- non-existing user making a purchase of a ticket.
--      purchase_datetime: the date and time of the purchase
-- CONSTRAINT purchaseEndedConcert: Followed by the EXTRA CONSTRAINT 2, it
-- checks if the purchase is being made before the concert. This is to prevent
-- the case where a user buys a ticket of a concert that has already happened.
CREATE TABLE PurchasedTicket (
                                 seat_name varchar(20) NOT NULL,
                                 section_id integer NOT NULL,
                                 FOREIGN KEY (seat_name, section_id) REFERENCES
                                     Seat(seat_name, section_id),
                                 vid integer NOT NULL,
                                 concert_datetime timestamp NOT NULL,
                                 FOREIGN KEY (vid, concert_datetime, section_id)
                                     REFERENCES Prices,
                                 PRIMARY KEY (vid, concert_datetime, section_id,
                                         seat_name),
                                 username varchar(30) NOT NULL REFERENCES Users,
                                 purchase_datetime timestamp NOT NULL,
                                 CONSTRAINT purchaseEndedConcert
                                    CHECK (concert_datetime > purchase_datetime)

);
