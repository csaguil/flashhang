"""
app.py

File that is the central location of code for our app.
"""

from flask import Flask, request
import requests
import random
import json
import os
import firebase_admin
from firebase_admin import credentials
from firebase_admin import db


#UNIX TIMESTAMP
from datetime import datetime, timedelta
import time
import calendar

from math import radians, sin, cos, atan2, sqrt, ceil
from random import randint

# Create application, and point static path (where static resources like images, css, and js files are stored) to the
# "static folder"
app = Flask(__name__, static_url_path="/static")
cred = credentials.Certificate("flashhang-3b322-firebase-adminsdk-fj9cj-db9b5e44e1.json") # os.environ["FIREBASE_PRIVATE_KEY"]

# Initialize the app with a service account, granting admin privileges
firebase_admin.initialize_app(cred, {
    'databaseURL': 'https://flashhang-3b322.firebaseio.com/' #os.environ
})

# As an admin, the app has access to read and write all data, regardless of Security Rules
ref = db.reference()
users_ref = ref.child("users")
lobby_ref = ref.child("lobbies")

@app.route('/signup', methods=['POST'])
def add_new_user():
    new_user = request.get_json()
    uid = new_user["uid"]
    del new_user["uid"]
    users_ref.set({
        uid: new_user
    })
    return json.dumps({"status":"success"})

@app.route('/loggedin')
def retrieve_user_info():
    uid = request.args.get("uid") # facebook user id
    snapshot = users_ref.child(uid).get()
    if snapshot is None:
        return json.dumps({"error": "User not found"})
    else:
        return json.dumps(snapshot)


@app.route('/lobby/start', methods=['POST'])
def create_new_lobby():
    lobby_details = request.get_json()
    host_uid = lobby_details["uid"]
    lobby_name = lobby_details["lobby_name"]
    new_lobby_id = random.getrandbits(64)
    lobby_ref.set({
        new_lobby_id: {
            'name': lobby_name,
            'state': "Pre_Comp",
            'host_uid': host_uid
        }
    })
    return json.dumps({"lobby_id": new_lobby_id})


@app.route('/lobby/join/<lobby_id>', methods=['POST'])
def join_lobby(lobby_id):
    uid = request.args.get("uid")
    user_current_location = request.args.get("location")
    uid = 'APFmUr3h0XexEANFNsKA6VsqJr72'
    print(uid)
    print(user_current_location)
    this_user_ref = users_ref.child(uid)
    this_user = this_user_ref.get()
    # this_user_active_lobbies = this_user["active_lobbies"] + ", " + str(lobby_id) if "active_lobbies" in \
    #                                                                                  this_user else str(lobby_id)
    this_user_active_lobbies = this_user["active_lobbies"] + str(lobby_id) if "active_lobbies" in \
                                                                              this_user else [str(lobby_id)]
    this_user_ref.update({
        "location": user_current_location,
        "active_lobbies": this_user_active_lobbies
    })
    print('here')
    this_lobby_ref = lobby_ref.child(lobby_id)
    this_lobby = this_lobby_ref.get()
    print(this_lobby)
    this_lobby_current_members = this_lobby["current_members"] if "current_members" in this_lobby else None
    print(this_lobby)
    if this_lobby_current_members is None:
        this_lobby_ref.set({
            "current_members": {
                uid: {
                    "preferences": this_user["preferences"],
                    "location": user_current_location
                }
            }
        })
    else:
        this_lobby_current_members[uid] = {
            "preferences": this_user["preferences"],
            "location": user_current_location
        }
        this_lobby_ref.update({
            "current_members": this_lobby_current_members
        })
    return {"status":"success"}


@app.route('/lobby/<lobby_id>')
def lobby_view(lobby_id):
    lobby = lobby_ref.child(lobby_id).get()
    if lobby is None:
        return json.dumps({"Error": "Lobby not found"})
    return json.dumps(lobby)



###### global Choices ###################################
list_of_cats = ["escapegames","amusementparks", "gokarts", "museums", "cafes","bars", "karaoke", "zoos","makerspaces", "festivals","paintball", "mini_golf", "bowling","spas"]
preference_watch  = []
options = []

##############find ideal location######################
def lat_lon_miles(coord1, coord2):
   R = 3959.0
   lat1 = radians(coord1[0])
   lon1 = radians(coord1[1])
   lat2 = radians(coord2[0])
   lon2 = radians(coord2[1])

   dlon = lon2 - lon1
   dlat = lat2 - lat1

   a = sin(dlat / 2)**2 + cos(lat1) * cos(lat2) * sin(dlon / 2)**2
   c = 2 * atan2(sqrt(a), sqrt(1 - a))

   distance = R * c

   return distance


def getIdealLocation(coordList):
   numPeople = len(coordList)
   lat_sum = 0
   lon_sum = 0

   for peopleCoords in coordList:
       lat_sum += peopleCoords[0]
       lon_sum += peopleCoords[1]

   avgCoord = (lat_sum/numPeople, lon_sum/numPeople)

   totalDistance = 0
   anchorCoord = coordList[0]
   minDist = lat_lon_miles(avgCoord, anchorCoord)
   for peopleCoords in coordList:
       dist_from_avg = lat_lon_miles(avgCoord, peopleCoords)
       totalDistance += dist_from_avg
       if(dist_from_avg<minDist):
           anchorCoord = peopleCoords
           minDist = dist_from_avg

   idealLocation = anchorCoord
   avgDist = totalDistance/numPeople

   return (idealLocation,avgDist)





################### SEATGEEK API ##################
def getSeatGeek(idealLocation,highPrice,numberGoing, avgDist, list_of_preferences):
    global preference_watch
    global options

    client_id = '&client_id=MTI0NDczNjJ8MTUzMjgxMzA1OC43NA'
    secret_code = '&client_secret=495e3c53fc8f2e4bb9a930d8eeab34d7e6ab3d2d98c6c5dde3e2dc14205532e9'
    events_endpoint = 'https://api.seatgeek.com/2/events?'

    dist = ceil(avgDist/2)

    lat = 'lat=' + str(idealLocation[0])
    lon = '&lon=' + str(idealLocation[1])
    r = '&range=' + str(dist) + 'mi'

    #change this
    currentDateTime = datetime.now() +  timedelta(hours=12)
    endDateTime = currentDateTime + timedelta(hours=10)
    currentDateTime.isoformat()
    endDateTime.isoformat()


    sgAvailable = '&listing_count.gte=' + str(numberGoing)
    timeRange = '&datetime_local.gte='  + str(currentDateTime) + '&datetime_local.lte='  + str(endDateTime)
    topPrice = '&average_price.lte=' + str(highPrice)

    search = events_endpoint + lat + lon + r + sgAvailable + timeRange + topPrice + client_id + secret_code
    sgList = requests.get(search)
    if sgList.status_code == 200:
        JSONsgList = sgList.json()

        option_append = []
        for event in JSONsgList["events"]:
            option = {}
            option['hang_option'] = 'seatgeek'
            option["title"] = event["title"]
            option["url"] = event["url"]
            print(event["datetime_tbd"])
            if event["datetime_tbd"] == False:
                #print(event["datetime_tbd"])
                # print('Hi')
                # print(time.mktime(event["datetime_local"]).timetuple )
                # print(time.strftime('%d',time.mktime(event["datetime_local"]).timetuple ))
                # print(time.strftime('%d of %B at %H%M', time.gmtime(event["datetime_local"])))
                # print( datetime(event["datetime_local"]).strptime("%d" + " of " + "%B" +  " at " + "%H%M"))
                # presentableTime = datetime(event["datetime_local"])
                option["time"] = event["datetime_local"]
                pass
            if 'name' in event["venue"]:
                option["address"] = event["venue"]["name"]
            elif address in event["venue"]:
                option["address"] = event["venue"]["address"]
            elif slug in event["venue"]:
                option["address"] = event["venue"]["slug"]
            else:
                print('no venue made available');
            option_append.append(option)
        options = options + option_append
        preference_watch.append('1')

        if len(preference_watch) == len(list_of_preferences) + 1:
            preference_watch = []
            make_a_choice()
    else:
        return request



#################YELP API#################
def run_yelp_graph_query(query, headers, list_of_preferences): # A simple function to use requests.post to make the API call. Note the json= section.
    global preference_watch
    global options
    request = requests.post('https://api.yelp.com/v3/graphql', json={'query': query}, headers=headers)
    if request.status_code == 200:
        yelp_return = request.json()

        option_append = []
        for option in yelp_return['data']['search']['business']:
            option["hang_option"] = 'yelp'
            option_append.append(option)
        options = options + option_append

        preference_watch.append('1')
        if len(preference_watch) == len(list_of_preferences) + 1:
            preference_watch = []
            make_a_choice()
    else:
        return request
        # raise Exception("Query failed to run by returning code of {}. {}".format(request.status_code, query))



#intergrate with yelp api
def get_yelp_choices(list_of_preferences, ideal_location):
    #TODO CHANGE THIS
    list_of_preferences = list_of_cats
    latitude = 0
    longitude = 1
    #get user choices and location on firebase
    headers = {"Authorization": "Bearer kcrW1LFhNRzg41MUjDtZRICXQKy3dFfnAtmSalYlR0Kr9lMYwKzpFeZZ5qQ2A_h6_Pe0SPc8M-8bzvb9TBRoKrjv3wXtfC97t-f64Utx4wNhhXwZNyIqzrP9XwldW3Yx"}
    next_two_hours = datetime.now() + timedelta(hours = 2)
    unixtime = calendar.timegm(next_two_hours.utcnow().utctimetuple())

    for counter, category  in enumerate(list_of_preferences):
        query_with_locations =  """
        {
            search(categories: \"""" + category + """\",
            latitude:""" + str(ideal_location[latitude])  + """,
            longitude:""" + str(ideal_location[longitude])  + """,
            open_at:""" + str(unixtime)  +  """,

            limit: 5)
            {
                total
                business {
                    name
                    rating
                    review_count
                    display_phone
                    reviews {
                        id
                    }
                    location {
                        address1
                        city
                        state
                        country
                    }
                }
            }
        }
        """
        run_yelp_graph_query(query_with_locations,headers,list_of_preferences)


def test():
    ideal_location = []
    ideal_location.append(37.780126)
    ideal_location.append(-122.410536)
    getSeatGeek(ideal_location,1000,100, 100,list_of_cats)
    get_yelp_choices('things',ideal_location)


def begin_compromise(lobby):
    list_of_preferences = []
    list_of_user_coords = []
    for uuid in  lobby["current_members"]:
        for preference in lobby["current_members"][uuid]["preferences"]:
            list_of_preferences.append(preference)
        list_of_user_coords.append(lobby["current_members"][uuid]["location"])

    #get ideal location
    location_return = getIdealLocation(coordList)
    ideal_location = location_return[0]
    radius = location_return[1]
    #Remove this
    ideal_location = [37.780126, -122.410536]
    getSeatGeek(ideal_location,1000,100, 100,list_of_cats)
    get_yelp_choices(list(set(list_of_preferences)), ideal_location)


def update_lobby_on_firebase(choices):
    this_lobby_ref = lobby_ref.child(lobby_id)
    
    this_lobby_ref.set({
            "choices": {
                "0": choices[0],
                "1": choices[1],
                "2": choices[3]
        }
    })
    return {"status":"success"}


def make_a_choice():
    global options
    choices = []
    choice_1 = randint(0, len(options))
    choice_2 = randint(0, len(options))
    while(choice_1 == choice_2):
        choice_2 = randint(0, len(options))
    choice_3 = randint(0, len(options))
    while(choice_3 == choice_2):
        choice_3 = randint(0, len(options))
    while(choice_3 == choice_1):
        choice_3 = randint(0, len(options))
    choices.append(options[choice_1])
    choices.append(options[choice_2])
    choices.append(options[choice_3])
    # update_lobby_on_firebase(choices)
    #write --> to firebase
    options = []



@app.route('/lobby/start_search/<lobby_id>', methods=['POST'])
def make_choice(lobby_id):
    #get user ids: -> call back
    # for each user -> get yelp choices
    #               ->  get seat_geek choices
    # make choice -> post to firebase
    #get lobby object with call back ->
    # get a set of preferences
    snapshot = lobby_ref.child(lobby_id).get()
    if snapshot is None:
        return json.dumps({"error": "User not found"})
    else:
        lobby = json.dumps(snapshot)
        #begin_compromise(lobby)
        return {"status":"success"}
        

