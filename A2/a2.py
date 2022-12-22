"""
Part2 of csc343 A2: Code that could be part of a ride-sharing application.
csc343, Fall 2022
University of Toronto

--------------------------------------------------------------------------------
This file is Copyright (c) 2022 Diane Horton and Marina Tawfik.
All forms of distribution, whether as given or with any changes, are
expressly prohibited.
--------------------------------------------------------------------------------
"""
from sqlite3 import Cursor
import psycopg2 as pg
import psycopg2.extensions as pg_ext
from typing import Optional, List, Any
from datetime import datetime
import re


class GeoLoc:
    """A geographic location.

    === Instance Attributes ===
    longitude: the angular distance of this GeoLoc, east or west of the prime
        meridian.
    latitude: the angular distance of this GeoLoc, north or south of the
        Earth's equator.

    === Representation Invariants ===
    - longitude is in the closed interval [-180.0, 180.0]
    - latitude is in the closed interval [-90.0, 90.0]

    >>> where = GeoLoc(-25.0, 50.0)
    >>> where.longitude
    -25.0
    >>> where.latitude
    50.0
    """
    longitude: float
    latitude: float

    def __init__(self, longitude: float, latitude: float) -> None:
        """Initialize this geographic location with longitude <longitude> and
        latitude <latitude>.
        """
        self.longitude = longitude
        self.latitude = latitude

        assert -180.0 <= longitude <= 180.0, \
            f"Invalid value for longitude: {longitude}"
        assert -90.0 <= latitude <= 90.0, \
            f"Invalid value for latitude: {latitude}"


class Assignment2:
    """A class that can work with data conforming to the schema in schema.ddl.

    === Instance Attributes ===
    connection: connection to a PostgreSQL database of ride-sharing information.

    Representation invariants:
    - The database to which connection is established conforms to the schema
      in schema.ddl.
    """
    connection: Optional[pg_ext.connection]

    def __init__(self) -> None:
        """Initialize this Assignment2 instance, with no database connection
        yet.
        """
        self.connection = None

    def connect(self, dbname: str, username: str, password: str) -> bool:
        """Establish a connection to the database <dbname> using the
        username <username> and password <password>, and assign it to the
        instance attribute <connection>. In addition, set the search path to
        uber, public.

        Return True if the connection was made successfully, False otherwise.
        I.e., do NOT throw an error if making the connection fails.

        >>> a2 = Assignment2()
        >>> # This example will work for you if you change the arguments as
        >>> # appropriate for your account.
        >>> a2.connect("csc343h-dianeh", "dianeh", "")
        True
        >>> # In this example, the connection cannot be made.
        >>> a2.connect("nonsense", "silly", "junk")
        False
        """
        try:
            self.connection = pg.connect(
                dbname=dbname, user=username, password=password,
                options="-c search_path=uber,public"
            )
            # This allows psycopg2 to learn about our custom type geo_loc.
            self._register_geo_loc()
            return True
        except pg.Error:
            return False

    def disconnect(self) -> bool:
        """Close the database connection.

        Return True if closing the connection was successful, False otherwise.
        I.e., do NOT throw an error if closing the connection failed.

        >>> a2 = Assignment2()
        >>> # This example will work for you if you change the arguments as
        >>> # appropriate for your account.
        >>> a2.connect("csc343h-dianeh", "dianeh", "")
        True
        >>> a2.disconnect()
        True
        >>> a2.disconnect()
        False
        """
        try:
            if not self.connection.closed:
                self.connection.close()
            return True
        except pg.Error:
            return False

    # ======================= Driver-related methods ======================= #

    def clock_in(self, driver_id: int, when: datetime, geo_loc: GeoLoc) -> bool:
        """Record the fact that the driver with id <driver_id> has declared that
        they are available to start their shift at date time <when> and with
        starting location <geo_loc>. Do so by inserting a row in both the
        ClockedIn and the Location tables.

        If there are no rows are in the ClockedIn table, the id of the shift
        is 1. Otherwise, it is the maximum current shift id + 1.

        A driver can NOT start a new shift if they have an ongoing shift.

        Return True if clocking in was successful, False otherwise. I.e., do NOT
        throw an error if clocking in fails.

        Precondition:
            - <when> is after all dates currently recorded in the database.
        """
        cur = self.connection.cursor()

        max_shift_id_so_far = """SELECT (CASE WHEN max(shift_id) IS NOT NULL
                                        THEN max(shift_id)
                                        ELSE 0 END) as max_shift_id 
                                FROM ClockedIn;
                                """

        # checker if there is an ongoing shift before when( had this, but
        # negligible:
        # (ClockedIn.datetime <= '{when}' and '{when}' < ClockedOut.datetime))
        cannotclockin_shiftnotend = f"""SELECT ClockedOut.datetime 
                            FROM ClockedIn LEFT JOIN ClockedOut USING (shift_id) 
                            WHERE driver_id = {driver_id} 
                                AND ClockedOut.datetime IS NULL;"""
        try:
            # wrong type given in the first place
            if not isinstance(driver_id, int) or\
                    not isinstance(geo_loc, GeoLoc):
                return False

            # get next shift id from ClockedIn
            cur.execute(max_shift_id_so_far)
            for record in cur:  # should be exactly one row actually
                next_shift_id = int(record[0]) + 1
                # check if works without casting int

            cur.execute(cannotclockin_shiftnotend)
            for record in cur:  # should be 0 row
                return False

            ClockedIn_insert = f"""INSERT INTO ClockedIn VALUES (
                                {next_shift_id}, {driver_id}, '{when}');"""
            Location_insert = f"""INSERT INTO Location VALUES ({next_shift_id},
             '{when}', '({geo_loc.longitude}, {geo_loc.latitude})');"""
            cur.execute(ClockedIn_insert)
            cur.execute(Location_insert)
            self.connection.commit()
            return True
        except pg.Error as ex:
            # You may find it helpful to uncomment this line while debugging,
            # as it will show you all the details of the error that occurred:
            # print(ex) # comment this back after debugging
            self.connection.rollback()
            return False
        finally:
            cur.close()
            # connection close will be done automatically for this assignment

    def pick_up(self, driver_id: int, client_id: int, when: datetime) -> bool:
        """Record the fact that the driver with driver id <driver_id> has
        picked up the client with client id <client_id> at date time <when>.

        If (a) the driver is currently on an ongoing shift, and
           (b) they have been dispatched to pick up the client, and
           (c) the corresponding pick-up has not been recorded
        record it by adding a row to the Pickup table, and return True.
        Otherwise, return False.

        You may not assume that the dispatch actually occurred, but you may
        assume there is no more than one outstanding dispatch entry for this
        driver and this client.

        Return True if the operation was successful, False otherwise. I.e.,
        do NOT throw an error if this pick up fails.

        Precondition:
            - <when> is after all dates currently recorded in the database.
        """
        cur = self.connection.cursor()
        # (a) the driver is currently on an ongoing shift (Should be 1 row)
        # includes when the clockout happens, i.e.,
        # (ClockedIn.datetime <= '{when}' and '{when}' <= ClockedOut.datetime)
        ongoing_shift = f"""SELECT ClockedIn.shift_id
                            FROM ClockedIn LEFT JOIN ClockedOut USING (shift_id) 
                            WHERE driver_id = {driver_id} 
                                AND ClockedOut.datetime IS NULL;"""

        try:
            cur.execute(ongoing_shift)
            if cur.rowcount:
                for row in cur:
                    current_shift_id = row[0]
            else:
                # print(f"driver not ongoing shift")
                return False

            # (b) they have been dispatched to pick up the client
            # (Should be 1 row)
            was_dispatched = f"""SELECT Dispatch.request_id
                                FROM Request JOIN Dispatch 
                                ON Request.request_id = Dispatch.request_id
                                WHERE Request.client_id = {client_id} 
                                    AND Dispatch.shift_id = {current_shift_id}
                                ;"""
            cur.execute(was_dispatched)
            if cur.rowcount:
                for row in cur:
                    current_request_id = row[0]
            else:
                # print(f"was not dispatched")
                return False

            # (c) the corresponding pick-up has not been recorded
            # (Should be 0 row)
            p_already_recorded = f"""SELECT *
                                FROM PickUp
                                WHERE request_id = {current_request_id}
                                ;"""
            cur.execute(p_already_recorded)
            if cur.rowcount > 0:
                # print("already recorded")
                return False
            else:
                pickup_insert = f"""INSERT INTO PickUp VALUES (
                                    {current_request_id}, '{when}');"""
                cur.execute(pickup_insert)
                # print(f"pickup successfully done for CLIENT {client_id}
                #  and for DRIVER {driver_id}")# debugging 디버깅
                self.connection.commit()
                return True

        except pg.Error as ex:
            # You may find it helpful to uncomment this line while debugging,
            # as it will show you all the details of the error that occurred:
            # raise ex
            self.connection.rollback()
            return False
        finally:
            cur.close()
            # connection close will be done automatically for this assignment

    # ===================== Dispatcher-related methods ===================== #
    def _clients_in_area(self, nw: GeoLoc, se: GeoLoc) -> bool:
        """
        (This method is called once, per dispatch method.)
        Create table RidsToDispatch that contains request_id in this area (i.e.,
         whose request has a source location in this area) and a driver has not
        been dispatched to them yet, dispatch drivers to them one at a time,
        from the client with the highest total billings down to the client
        with the lowest total billings, or until there are no more drivers
        available.
        """
        cina = self.connection.cursor()

        # rids that are not dispatched yet
        dropNotAlreadyDispatched = """DROP VIEW IF EXISTS 
                                    NotAlreadyDispatched CASCADE;"""
        createNotAlreadyDispatched = """CREATE VIEW NotAlreadyDispatched AS (
                                     (SELECT request_id, client_id
                                     FROM Request)
                                     EXCEPT
                                     (SELECT request_id, client_id
                                     FROM Request JOIN Dispatch USING (request_id)));"""

        # clients and their total billings
        dropClientsTotalBillings = """DROP VIEW IF EXISTS 
                                    ClientsTotalBillings CASCADE;"""
        createClientsTotalBillings = """CREATE VIEW ClientsTotalBillings AS (
                                     SELECT Client.client_id, (
                                     CASE WHEN sum(amount) IS NOT NULL 
                                     THEN sum(amount) ELSE 0 END) as total
                                     FROM Client LEFT JOIN (Request JOIN Billed  
                                    ON Billed.request_id = Request.request_id) 
                                    ON Client.client_id = Request.client_id
                                     GROUP BY Client.client_id
                                     );"""

        # rids that are in this area ordered by decreasing clients' total billings
        dropRidsToDispatch = """DROP VIEW IF EXISTS RidsToDispatch CASCADE;"""
        createRidsToDispatch = f"""CREATE VIEW RidsToDispatch AS 
        (SELECT request_id 
        FROM NotAlreadyDispatched JOIN ClientsTotalBillings USING (client_id) 
            JOIN Request USING (request_id)
        WHERE {nw.longitude} <= source[0] AND
                 source[0] <= {se.longitude} AND 
                {se.latitude} <= source[1] AND
                 source[1] <= {nw.latitude} 
        ORDER BY total DESC);"""
        try:
            cina.execute(dropNotAlreadyDispatched)
            cina.execute(createNotAlreadyDispatched)
            cina.execute(dropClientsTotalBillings)
            cina.execute(createClientsTotalBillings)
            cina.execute(dropRidsToDispatch)
            cina.execute(createRidsToDispatch)
            self.connection.commit()
            return True
        except pg.Error as ex:
            print(ex)
            self.connection.rollback()
            return False
        finally:
            cina.close()

    def _drivers_available(self, nw: GeoLoc, se: GeoLoc) -> bool:
        """(This method is called once, per dispatch method.)
        Only drivers who meet all of these conditions are dispatched:
            (a) They are currently on an ongoing shift.
            (b) They are available and are NOT currently dispatched or on
            an ongoing ride.
            (c) Their most recent recorded location is in the area bounded by
            <nw> and <se>.

           Return driver_id, shift_id, and the most recent location of such drivers.
        """
        da = self.connection.cursor()
        # (a) drivers on onging shift and their shift id
        # (b) driver not on ongoing ride AND not dispatched yet
        # request id 가 같은 dropoff 이 없는 dispatch...= ongoing ride
        dropABcombined = "DROP VIEW IF EXISTS ABcombined CASCADE;"
        createABcombined = """CREATE VIEW ABcombined AS (
                            SELECT driver_id, ClockedIn.shift_id
                            FROM ClockedIn LEFT JOIN ClockedOut USING (shift_id) 
                            WHERE ClockedOut.datetime IS NULL
                                  AND ClockedIn.shift_id NOT IN 
                                  (SELECT shift_id
                                    FROM Dispatch LEFT JOIN Dropoff
                                        ON Dispatch.request_id = Dropoff.request_id
                                    WHERE Dropoff.request_id IS NULL)
                                                        );"""

        # (c) drivers whose most recent recorded location is in the area bounded
        # by <nw> and <se>.
        dropMostRecentDate = """DROP VIEW IF EXISTS MostRecentDate CASCADE;"""
        createMostRecentDate = """CREATE VIEW MostRecentDate AS 
                                    (SELECT shift_id, max(datetime) as recent
                                    FROM Location
                                    GROUP BY shift_id);"""

        dropMostRecentLocationGood = """DROP VIEW IF EXISTS 
                                        MostRecentLocationGood CASCADE;"""
        createMostRecentLocationGood = f"""CREATE VIEW MostRecentLocationGood AS
                     (SELECT MostRecentDate.shift_id, location 
                    FROM Location JOIN MostRecentDate 
                    ON Location.shift_id = MostRecentDate.shift_id 
                    AND Location.datetime = MostRecentDate.recent 
                    WHERE {nw.longitude} <= location[0] AND 
                            location[0]<= {se.longitude} AND 
                            {se.latitude} <= location[1] AND 
                            location[1] <= {nw.latitude});
                                            """
        # table to delete, instead of view...
        # DETAIL:  Views that do not select from a single table 
        # or view are not automatically updatable.
        # HINT:  To enable deleting from the view, provide an INSTEAD OF DELETE
        #  trigger or an unconditional ON DELETE DO INSTEAD rule.
        dropAvailableDrivers = "DROP TABLE IF EXISTS AvailableDrivers CASCADE;"
        createAvailableDrivers = """CREATE TABLE AvailableDrivers AS( 
                     SELECT driver_id, ABcombined.shift_id, location 
                     FROM ABcombined JOIN MostRecentLocationGood 
                     ON ABcombined.shift_id = MostRecentLocationGood.shift_id
                                                                    );"""

        try:
            da.execute(dropABcombined)
            da.execute(createABcombined)
            da.execute(dropMostRecentDate)
            da.execute(createMostRecentDate)
            da.execute(dropMostRecentLocationGood)
            da.execute(createMostRecentLocationGood)
            da.execute(dropAvailableDrivers)
            da.execute(createAvailableDrivers)
            self.connection.commit()
            return True
        except pg.Error as ex:
            print(ex)
            self.connection.rollback()
            return False
        finally:
            da.close()

    def _dist(self, a: tuple, b: tuple) -> float:
        """Return the absolute value of the sqaure distance between
        a and b.
        Note we don't even need to square root it."""
        if isinstance(a, GeoLoc):
            aob = [0, 0]
            aob[0] = a.longitude
            aob[1] = a.latitude
        else:
            aob = a
        if isinstance(b, GeoLoc):
            bob = [0, 0]
            bob[0] = b.longitude
            bob[1] = b.latitude
        else:
            bob= b
        x_dist = aob[0] - bob[0]
        y_dist = aob[1] - bob[1]
        return (x_dist**2) + (y_dist**2)

    def _best_driver_to_this_request(self, rid: int) -> Any:
        """When choosing a driver for a particular client, if there are several
        drivers to choose from, choose the one closest to the client's source
        location. In the case of a tie, any one of the tied drivers may be
        dispatched.

        Return such driver's current shift_id.
        If something bad happens, return a string, which indicates that.
        """
        try:
            source_cur = self.connection.cursor()
            best = self.connection.cursor()
            source_cur.execute(f"""SELECT source 
                                    FROM Request 
                                    WHERE request_id = {rid};""")
            for row in source_cur:    # Always exactly one row
                client_loc = row[0]
            source_cur.close()

            best.execute("""SELECT shift_id, location
                            FROM AvailableDrivers;""")
            if best.rowcount == 0:
                return "No available driver!"

        # note best_driver really means their shift, but we are assuming there
            if best.rowcount == 1:  # only one available driver
                for row in best:
                    best_driver = row[0]
                    best_driver_loc = row[1]
                deleting_cur = self.connection.cursor()
                deleting_cur.execute(f"""DELETE FROM AvailableDrivers 
                                WHERE shift_id = {best_driver};""")
                self.connection.commit()
                deleting_cur.close()
                return (best_driver, best_driver_loc)
            else:
                best_driver = None  # place holder
                best_driver_loc = None
                best_dc_dist = float('inf')
                for row in best:
                    cur_driver = row[0]
                    cur_driver_loc = row[1]
                    cur_dc_dist = self._dist(client_loc, cur_driver_loc)
                    if cur_dc_dist < best_dc_dist:
                        best_driver = cur_driver
                        best_driver_loc = cur_driver_loc
                        best_dc_dist = cur_dc_dist
                deleting_cur = self.connection.cursor()
                deleting_cur.execute(f"""DELETE FROM AvailableDrivers 
                                WHERE shift_id = {best_driver};""")
                self.connection.commit()
                deleting_cur.close()
                return (best_driver, best_driver_loc)
        except pg.Error as ex:
            print(ex)
            self.connection.rollback()
            return "Error occurred!"
        finally:
            best.close()

    def dispatch(self, nw: GeoLoc, se: GeoLoc, when: datetime) -> None:
        """Dispatch drivers to the clients who have requested rides in the area
        bounded by <nw> and <se>, such that:
            - <nw> is the longitude and latitude in the northwest corner of this
            area
            - <se> is the longitude and latitude in the southeast corner of this
            area
        and record the dispatch time as <when>.

        Area boundaries are inclusive. For example, the point (4.0, 10.0)
        is considered within the area defined by
                    NW = (1.0, 10.0) and SE = (25.0, 2.0)
        even though it is right at the upper boundary of the area.

        NOTE: + longitude values decrease as we move further west, and
                latitude values decrease as we move further south.
              + You may find the PostgreSQL operators @> and <@> helpful.

        For all clients who have requested rides in this area (i.e., whose
        request has a source location in this area) and a driver has not
        been dispatched to them yet, dispatch drivers to them one at a time,
        from the client with the highest total billings down to the client
        with the lowest total billings, or until there are no more drivers
        available.

        Only drivers who meet all of these conditions are dispatched:
            (a) They are currently on an ongoing shift.
            (b) They are available and are NOT currently dispatched or on
            an ongoing ride.
            (c) Their most recent recorded location is in the area bounded by
            <nw> and <se>.
        When choosing a driver for a particular client, if there are several
        drivers to choose from, choose the one closest to the client's source
        location. In the case of a tie, any one of the tied drivers may be
        dispatched.

        Dispatching a driver is accomplished by adding a row to the Dispatch
        table. The dispatch car location is the driver's most recent recorded
        location. All dispatching that results from a call to this method is
        recorded to have happened at the same time, which is passed through
        parameter <when>.

        If an exception occurs during dispatch, rollback ALL changes.

        Precondition:
            - <when> is after all dates currently recorded in the database.
        """
        cur = self.connection.cursor()
        try:
            if self._clients_in_area(nw, se):
                # RidsToDispatch (in order) created.
                if self._drivers_available(nw, se):  # AvailableDrivers created.
                    cur.execute("SELECT request_id FROM RidsToDispatch;")
                    for row in cur:
                        rid = row[0]
                        result = self._best_driver_to_this_request(rid)
                        if isinstance(result, tuple):
                            inserting_cur = self.connection.cursor()
                            sid = result[0]
                            loc = pg_ext.AsIs(f"'({result[1].longitude}, {result[1].latitude})'::geo_loc")
                            insert_dispatch = f"""INSERT INTO Dispatch VALUES
                                ({rid}, {sid}, {loc}, '{when}');"""
                            inserting_cur.execute(insert_dispatch)
                            inserting_cur.close()
                    self.connection.commit()
        except pg.Error as ex:
            # You may find it helpful to uncomment this line while debugging,
            # as it will show you all the details of the error that occurred:
            # raise ex
            print(ex)
            self.connection.rollback()
            return
        finally:
            cur.close()

    # =======================     Helper methods     ======================= #

    # You do not need to understand this code. See the doctest example in
    # class GeoLoc (look for ">>>") for how to use class GeoLoc.

    def _register_geo_loc(self) -> None:
        """Register the GeoLoc type and create the GeoLoc type adapter.

        This method
            (1) informs psycopg2 that the Python class GeoLoc corresponds
                to geo_loc in PostgreSQL.
            (2) defines the logic for quoting GeoLoc objects so that you
                can use GeoLoc objects in calls to execute.
            (3) defines the logic of reading GeoLoc objects from PostgreSQL.

        DO NOT make any modifications to this method.
        """

        def adapt_geo_loc(loc: GeoLoc) -> pg_ext.AsIs:
            """Convert the given geographical location <loc> to a quoted
            SQL string.
            """
            longitude = pg_ext.adapt(loc.longitude)
            latitude = pg_ext.adapt(loc.latitude)
            return pg_ext.AsIs(f"'({longitude}, {latitude})'::geo_loc")

        def cast_geo_loc(value: Optional[str], *args: List[Any]) \
                -> Optional[GeoLoc]:
            """Convert the given value <value> to a GeoLoc object.

            Throw an InterfaceError if the given value can't be converted to
            a GeoLoc object.
            """
            if value is None:
                return None
            m = re.match(r"\(([^)]+),([^)]+)\)", value)

            if m:
                return GeoLoc(float(m.group(1)), float(m.group(2)))
            else:
                raise pg.InterfaceError(f"bad geo_loc representation: {value}")

        with self.connection, self.connection.cursor() as cursor:
            cursor.execute("SELECT NULL::geo_loc")
            geo_loc_oid = cursor.description[0][1]

            geo_loc_type = pg_ext.new_type(
                (geo_loc_oid,), "GeoLoc", cast_geo_loc
            )
            pg_ext.register_type(geo_loc_type)
            pg_ext.register_adapter(GeoLoc, adapt_geo_loc)


def sample_test_function() -> None:
    """A sample test function."""
    a2 = Assignment2()
    try:
        connected = a2.connect("csc343h-kangyou8", "kangyou8", "")
        print(f"[Connected] Expected True | Got {connected}.")

        # TODO: Test one or more methods here, or better yet, make more testing
        #   functions, with each testing a different aspect of the code.

        # ------------------- Testing Clocked In -----------------------------#

        # These tests assume that you have already loaded the sample data we
        # provided into your database.

        # This driver doesn't exist in db
        clocked_in = a2.clock_in(
            989898, datetime.now(), GeoLoc(-79.233, 43.712)
        )
        print(f"[ClockIn] Expected False | Got {clocked_in}.")

        # This drive does exist in the db
        clocked_in = a2.clock_in(
            22222, datetime.now(), GeoLoc(-79.233, 43.712)
        )
        print(f"[ClockIn] Expected True | Got {clocked_in}.")

        # Same driver clocks in again
        clocked_in = a2.clock_in(
            22222, datetime.now(), GeoLoc(-79.233, 43.712)
        )
        print(f"[ClockIn] Expected False | Got {clocked_in}.")

        clocked_in = a2.clock_in(
            1, datetime.now(), GeoLoc(-70.7070, 70.707)
        )
        print(f"who doesnt have existing shift now {clocked_in}")

        # ------------------------------------------------------------------
        # pu = a2.pick_up(
        # driver_id=19920506, client_id= 20010619, 
        # when=datetime.now())
        # print(f"check if bh picked her up.{pu}")
        # ------------------- Testing Dispatch -----------------------------#
        # Case 1. that there is a valid client and valid driver to dispatch
        # nw = GeoLoc(-21.0, 50.0)
        # se = GeoLoc(-20.5, 45)
        # when = datetime(2022, 10, 31, 11, 00, 00)
        # a2.dispatch(nw, se, when)
        # print("DISPATCH------------")
        # a2.dispatch(nw=GeoLoc(-170, 5),
        #  se=GeoLoc(170,-5), when=datetime.now())
    finally:
        a2.disconnect()

# -------------- tests can go in here-----------------------
# def proof_of_concept_test() -> None:
#     a2 = Assignment2()
#     try:
#         a2.connect("csc343h-dianeh", "dianeh", "")
#         n = a2.num_drivers()
#         print(n)
#     finally:
#         a2.disconnect()


if __name__ == "__main__":
    # Un comment-out the next two lines if you would like all the doctest
    # examples (see ">>>" in the method and class docstrings) to be run
    # and checked.
    # import doctest
    # doctest.testmod()

    # TODO: Put your testing code here, or call testing functions such as
    #   this one:
    sample_test_function()
    # proof_of_concept_test()
