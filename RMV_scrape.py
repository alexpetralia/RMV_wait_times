from bs4 import BeautifulSoup
import os, requests
from datetime import date
from datetime import datetime
import time as timer # because of name clash with datetime module

base = os.getcwd()

cities = ['Attleboro','Boston','Braintree','Brockton','Chicopee','Danvers','Easthampton','Fall River','Greenfield','Haverhill','Lawrence','Leominster','Lowell','Martha\'s Vineyard','Milford','Nantucket','Natick','New Bedford','North Adams','Pittsfield','Plymouth','Revere','Roslindale','South Yarmouth','Southbridge','Springfield','Taunton','Watertown','Wilmington','Worcester']

st = timer.time()
while True:
    i = 1
    l = []
    test = [] # TEST
    curr_hr = datetime.now().hour
    weekday = date.today().weekday() 
    
    # if today is not a weekend day [5, 6] and is within business hours
    if weekday != (5 or 6) and (curr_hr >= 9 and curr_hr < 18): 
        print "Pulling data at " + date.strftime(datetime.now(), "%I:%M:%S %p" + ".\n\n")
        
        for c in cities: # parse website
            link = "https://www.massrmv.com/index/tabid/1596/ctl/accessible/mid/4238/Name/%s/Default.aspx" % c
            try:             
                r = requests.get(link, timeout = 10)
                soup = BeautifulSoup(r.text, "html.parser")
                time = soup.find(id = "dnn_ctr4238_ViewBranchAccessible_lblWaitTimesDownloaded")
                wait = soup.find(id = "dnn_ctr4238_ViewBranchAccessible_lblLicensing")
                
                hours, minutes, seconds = 0, 0 ,0
                if wait.string == 'No wait time':
                    mins = 0
                elif wait.string == 'Closed':
                    mins = 999 # for display, 999 will have to be graphed as 0 but highlighted as 'Closed'
                else: # convert strings to minute wait time floats
                    wait_string_array = wait.string.split(',')
                    for measure in wait_string_array:
                        if 'hour' in measure:
                            hours = float(measure.split()[0]) # pull hours number
                        if 'minute' in measure:
                            minutes = float(measure.split()[0]) # pull minutes number
                        if 'second' in measure:
                            seconds = float(measure.split()[0]) # pull seconds number
                    mins = (hours * 60) + minutes + (seconds / 60.)                              
                    
                mins = format(mins, '.2f') # truncate to 2 decimal places
                mins = str(mins) # convert float to string for simple string concats later
                
                if i == 1: # make first item in row the timestamp
                    first_time_check = time
                    l.append(date.strftime(date.today(),"%d/%m/%Y") + " " + time.string)
                    test.append(date.strftime(date.today(),"%d/%m/%Y") + " " + time.string) # TEST
                    
                # ensure all webpages are refreshed at roughly same time (+/- 3 mins) 
                first_time_check_int = int( first_time_check.string.split(':')[1][0:2] )
                time_int = int( time.string.split(':')[1][0:2] )
                if abs(time_int - first_time_check_int) <= 3:
                    l.append(mins)
                    test.append(wait.string) # TEST
                else:
                    l.append('') # if they do not all have the same refresh timestamp, skip it (N/A)
                    test.append('') # TEST
            except Exception as e: # in case URL link fails
                if i == 1: l.append("URL request failed")                
                l.append('')
                print repr(e) + "\n"
                
            i += 1
        
        fname = base + "/wait_times.csv"
        try:
            if os.path.exists(fname): # append to file, depending on whether or not it exists already 
                with open(fname, "a+") as f:
                    f.write( ('%s') % ','.join(l) + '\n')
            else:
                with open(fname, "a+") as f:
                    headers = cities[:]
                    headers.insert(0, "timestamp")
                    f.write( ('%s') % ','.join(headers) + '\n')
                    f.write( ('%s') % ','.join(l) + '\n')
                    
            """ # CHECK FILE (TEST)
            #######################################################
            fname2 = base + "/check.txt"
            if os.path.exists(fname2): # append to file, depending on whether or not it exists already
                with open(fname2, "a+") as f:
                    f.write( ('%s') % '\t'.join(test) + '\n')
            else:
                with open(fname2, "a+") as f:
                    headers = cities[:]
                    headers.insert(0, "timestamp")
                    f.write( ('%s') % '\t'.join(headers) + '\n')
                    f.write( ('%s') % '\t'.join(test) + '\n')
            #######################################################
            """
        except Exception as e: # in case file write fails
            print repr(e) + "\n"
                
    else: print "RMV is closed.\n"
    
    delay = 60.
    timer.sleep(delay - (timer.time() - st) % delay)