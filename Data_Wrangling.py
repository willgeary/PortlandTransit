
# coding: utf-8

# # Manipulating Portland GTFS Data

# Data source: http://www.gtfs-data-exchange.com/agency/trimet/
# 
# Data zipfile: http://developer.trimet.org/schedule/gtfs.zip
# 
# *Latest GTFS File (trimet-archiver_20160505_0144.zip) posted on May 05 2016*

# ### Download and unzip the data

# In[12]:

get_ipython().run_cell_magic(u'bash', u'', u'\nmkdir gtfs\ncd gtfs\nwget http://developer.trimet.org/schedule/gtfs.zip ## Portland GTFS\nunzip gtfs.zip')


# ### Import Python libraries

# In[34]:

import pandas as pd
import numpy as np
from datetime import datetime, timedelta, date


# ### Read the GTFS files into dataframes

# In[206]:

agency = pd.read_csv('gtfs/agency.txt')
calendar_dates = pd.read_csv('gtfs/calendar_dates.txt')
try:
    calendar = pd.read_csv('gtfs/calendar.txt')
except:
    pass
routes = pd.read_csv('gtfs/routes.txt')
shapes = pd.read_csv('gtfs/shapes.txt')
stop_times = pd.read_csv('gtfs/stop_times.txt')
stops = pd.read_csv('gtfs/stops.txt')
trips = pd.read_csv('gtfs/trips.txt')


# ### Join tables

# Join calendar_dates and trips tables on service_id.

# In[207]:

trip_dates = pd.merge(calendar_dates,trips)
trip_dates['date'] = trip_dates['date'].astype(str)
trip_dates.head()


# ### Add  dates to times

# Here is the stop_times table:

# In[209]:

stop_times['stop_id'] = stop_times['stop_id'].astype(str)
stop_times.head()


# The arrival_time and departure_time columns are times, not datetimes. For the animation, we need to assign a date to this time to make it a datetime.

# In[210]:

date1 = '20170414' ## input date


# In[211]:

date2 = datetime.strptime(date1, "%Y%m%d").date() + timedelta(1)
our_dates = [date1, date2]


# Define functions to add dates to times, dealing with times that are after midnight as well.

# In[212]:

def add_arrival_date(df, dates = arbitrary_dates):
    df = df.copy()
    arrival_date = []
    arrival_time = []

    for i in df['arrival_time']:
        hour = i[:i.find(':')]
        minute = i[i.find(':')+1:i.find(':',4)]
        second = i[i.find(':',5)+1:]
        
        if int(hour) < 24:
            arrival_date.append(dates[0])
            arrival_time.append(i)
        elif 24 <= int(hour) < 48:
            arrival_date.append(dates[1])
            hour = int(hour) - 24
            arrival_time.append(str(hour)+":"+minute+":"+second)
        else:
            arrival_date.append('NA')
            
    df['arrival_date'] = arrival_date
    df['arrival_time'] = arrival_time
    return df

def add_departure_date(df, dates = arbitrary_dates):
    df = df.copy()
    departure_date = []
    departure_time = []

    for i in df['departure_time']:
        hour = i[:i.find(':')]
        minute = i[i.find(':')+1:i.find(':',4)]
        second = i[i.find(':',5)+1:]
        
        if int(hour) < 24:
            departure_date.append(dates[0])
            departure_time.append(i)
        elif 24 <= int(hour) < 48:
            departure_date.append(dates[1])
            hour = int(hour) - 24
            departure_time.append(str(hour)+":"+minute+":"+second)
        else:
            departure_date.append('NA')
            
    df['departure_date'] = departure_date
    df['departure_time'] = departure_time
    return df


# Let's create a dataframe containing all of the trips on our date.

# In[218]:

our_date = trip_dates[trip_dates['date'] == date1]


# In[219]:

our_date.head()


# In[220]:

print "There are ", len(our_date), "trips on", date1


# Get all of the trip id's on our date:

# In[221]:

our_trip_ids = our_date['trip_id']


# For every trip in this list, create a dataframe. Add dates and duration, do some joining, and store every trip as a dataframe in a list of dataframes.

# In[237]:

triplist = []
count = 0

for i in our_trip_ids:
    count += 1
    df = stop_times[stop_times['trip_id'] == i]
    
    # add arrival and departure dates
    df = add_arrival_date(df, dates = our_dates)
    df = add_departure_date(df, dates = our_dates)
    df['arrival_date'] = df['arrival_date'].astype(str)
    df['departure_date'] = df['departure_date'].astype(str)
    df['arrival_datetime'] = pd.to_datetime(df['arrival_date'] + ' ' + df['arrival_time'])
    df['departure_datetime'] = pd.to_datetime(df['departure_date'] + ' ' + df['departure_time'])

    # join df with stops
    df = pd.merge(df, stops[['stop_id', 'stop_name', 'stop_lat', 'stop_lon']],left_on='stop_id', right_on='stop_id')

    # join df with trips to get direction and route id
    try:
        df = pd.merge(df, trips[['trip_id', 'direction_id', 'route_id']], left_on='trip_id', right_on='trip_id', how='left')
    except:
        df = pd.merge(df, trips[['trip_id', 'route_id']], left_on='trip_id', right_on='trip_id', how='left')
    
    # join df with routes to get route id
    df = pd.merge(df, routes[['route_id', 'route_long_name']], left_on='route_id', right_on='route_id', how='left')
    
    # create new dataframe to store results
    legs = pd.DataFrame()
    legs['type_id'] = df['route_id']
    legs['starttime'] = df['departure_datetime']
    legs['stoptime'] = df['arrival_datetime'].shift(-1).fillna(method='ffill')
    legs['tripduration'] = ((legs['stoptime'] - legs['starttime'])/np.timedelta64(1, 's')).astype(int)
    legs['start_lat'] = df['stop_lat']
    legs['start_lon'] = df['stop_lon']
    legs['end_lat'] = legs['start_lat'].shift(-1).fillna(method='ffill')
    legs['end_lon'] = legs['start_lon'].shift(-1).fillna(method='ffill')
    
    # append results to triplist
    triplist.append(legs)
    
    if count % 1000 == 0:
        print str(datetime.now()), "finished trip number", count, "/", len(our_trip_ids)


# This is what the first dataframe in the list looks like:

# In[225]:

triplist[0]


# Concatenate all of the dataframes into that list into a single long dataframe.

# In[226]:

data = pd.concat(triplist)


# In[227]:

data.head()


# Remove trips with zero duration or zero lat/lon coordinates.

# In[228]:

data = data[data.tripduration != 0]
data = data[data.start_lon != 0]
data = data[data.start_lat != 0]
data = data[data.end_lon != 0]
data = data[data.end_lat != 0]


# In[229]:

data = data.sort_values(by='starttime')
data = data.reset_index(drop=True)


# ### Assign type_id

# This is useful for color schemes, i.e. (1 = yellow cab, 2 = green cab, etc)

# In[235]:

data['type_id'] = 1 # 1 = TriMet


# ### Save the output to a csv

# In[241]:

data.to_csv("data/portland_{}.csv".format(date1))


# # Animate the CSV with Processing

# See: https://github.com/willgeary/PortlandTransit

# In[240]:

from IPython.display import Image
Image("http://i.imgur.com/MRoojVa.png")

