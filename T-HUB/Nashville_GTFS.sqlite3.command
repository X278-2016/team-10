sqlite3 Nashville_GTFS.sqlite3
CREATE TABLE calendar (service_id text,start_date integer,end_date integer,monday integer,tuesday integer,wednesday integer,thursday integer,friday integer,saturday integer,sunday integer);
.mode csv
.import calendar.txt calendar

CREATE TABLE calendar_dates (service_id text,date integer,exception_type integer);
.mode csv
.import calendar_dates.txt calendar_dates

CREATE TABLE routes (route_long_name text,route_type integer,route_text_color text,route_color text,agency_id text,route_id text,route_url text,route_desc text,route_short_name text);
.mode csv
.import routes.txt routes

CREATE TABLE stop_times (trip_id text,arrival_time text,departure_time text,stop_id text,stop_sequence integer,stop_headsign text,pickup_type integer,drop_off_type integer,shape_dist_traveled integer, timepoint text);
.mode csv
.import stop_times.txt stop_times

CREATE TABLE stops (stop_lat real,wheelchair_boarding integer,stop_code text,stop_lon real,stop_timezone text,stop_url text,parent_station text,stop_desc text,stop_name text,location_type integer,stop_id text,zone_id text);
.mode csv
.import stops.txt stops

CREATE TABLE trips (block_id text,bikes_allowed text,route_id text,wheelchair_accessible text,direction_id integer,trip_headsign text,shape_id text,service_id text,trip_id text,trip_short_name text);
.mode csv
.import trips.txt trips

CREATE TABLE shapes (shape_id text, shape_pt_lat real, shape_pt_lon real, shape_pt_sequence integer, shape_dist_traveled real);
.mode csv
.import shapes.txt shapes
