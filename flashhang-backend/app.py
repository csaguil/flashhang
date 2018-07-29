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
    users_ref.update({
        uid: new_user
    })
    users_ref.child(uid).set(
        new_user
    )
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
    new_lobby_id = random.getrandbits(16)
    lobby_ref.update({
        new_lobby_id: {
            'name': lobby_name,
            'state': "Pre_Comp",
            'host_uid': host_uid,
            'choice': 'none'
        }
    })
    return json.dumps({"lobby_id": str(new_lobby_id)})


@app.route('/lobby/join/<lobby_id>', methods=['POST'])
def join_lobby(lobby_id):
    json_response = request.get_json()
    uid = json_response["uid"]
    user_current_location = json_response["location"]

    this_user_ref = users_ref.child(uid)
    this_user = this_user_ref.get()

    this_user_active_lobbies = this_user["active_lobbies"] + [str(lobby_id)] if "active_lobbies" in \
                                                                              this_user else [str(lobby_id)]
    this_user_ref.update({
        "location": user_current_location,
        "active_lobbies": this_user_active_lobbies
    })

    this_lobby_ref = lobby_ref.child(lobby_id)
    this_lobby = this_lobby_ref.get()
    this_lobby_current_members = this_lobby["current_members"] if "current_members" in this_lobby else None

    if this_lobby_current_members is None:
        this_lobby_ref.update({
            "current_members": {
                uid: {
                    "name": this_user["name"],
                    "preferences": this_user["preferences"],
                    "location": user_current_location
                }
            }
        })
    else:
        this_lobby_current_members[uid] = {
            "name": this_user["name"],
            "preferences": this_user["preferences"],
            "location": user_current_location
        }
        this_lobby_ref.update({
            "current_members": this_lobby_current_members
        })
    return json.dumps({"status":"success"})


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

#############Event Brite###########################

def getSeatGeekr(idealLocation,highPrice,numberGoing, avgDist, radFactor,list_of_preferences,lobby_id):
    global preference_watch
    global options
    client_id = '&client_id=MTI0NDczNjJ8MTUzMjgxMzA1OC43NA'
    secret_code = '&client_secret=495e3c53fc8f2e4bb9a930d8eeab34d7e6ab3d2d98c6c5dde3e2dc14205532e9'
    events_endpoint = 'https://api.seatgeek.com/2/events?'

    dist = round(avgDist*radFactor)
    dist = ceil(avgDist/2)
    if(dist< 1):
        dist = 1

    lat = 'lat=' + str(idealLocation[0])
    lon = '&lon=' + str(idealLocation[1])
    radrange = '&range=' + str(dist) + 'mi'

    currentDateTime = datetime.now() +  timedelta(hours=12)
    endDateTime = currentDateTime + timedelta(hours=10)
    currentDateTime.isoformat()
    endDateTime.isoformat()

    # currentDateTime = currentDateTime.isoformat()
    # endDateTime = endDateTime.isoformat()


    sgAvailable = '&listing_count.gte=' + str(numberGoing)
    timeRange = '&datetime_local.gte='  + str(currentDateTime) + '&datetime_local.lte='  + str(endDateTime)
    topPrice = '&average_price.lte=' + str(highPrice)

    search = events_endpoint + lat + lon + radrange + sgAvailable + timeRange + topPrice + client_id + secret_code
    sgList = requests.get(search)
    JSONsgList = sgList.json()

    if sgList.status_code == 200:
        JSONsgList = sgList.json()

        option_append = []
        for event in JSONsgList["events"]:
            option = {}
            option['hang_option'] = 'seatgeek'
            option["title"] = event["title"]
            option["url"] = event["url"]
            option["image"] = event["performers"]["images"]["huge"]
            print(event["datetime_tbd"])
            if event["datetime_tbd"] == False:
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

        if len(preference_watch) == len(list_of_preferences) + 2:
            preference_watch = []
            make_a_choice(lobby_id)
    else:
        return request



def getEventBrite(idealLocation, avgDist, radFactor, list_of_preferences,lobby_id):
    global preference_watch
    global options
    base_string = 'https://www.eventbriteapi.com/v3/events/search/?'
    lat = 'location.latitude='+str(idealLocation[0])
    lon = '&location.longitude='+str(idealLocation[1])
    dist = round(avgDist*radFactor)
    if(dist< 1):
        dist = 1

    radrange = '&location.within='+str(dist)+'mi'



    currentDateTime = datetime.now()
    endDateTime = currentDateTime + timedelta(hours=3)

    currentDateTime = currentDateTime.isoformat()[:-7]
    endDateTime = endDateTime.isoformat()[:-7]


    startTime = '&start_date.range_start='+str(currentDateTime)
    endTime = '&start_date.range_end='+str(endDateTime)

    search_string = base_string + lat + lon + radrange
    # search_string = base_string + lat + lon + radrange + startTime + endTime
    response = requests.get(search_string, headers = {"Authorization": "Bearer 5N4OSJMOEQBKAGX7HQSO"},verify = True)

    JSONebList = response.json()

    num_events = min(len(JSONebList['events']),15)

    events = []
    for n in range(0, num_events):
        vid = JSONebList['events'][n]['venue_id']
        response2 = requests.get('https://www.eventbriteapi.com/v3/venues/'+str(vid), headers = {"Authorization": "Bearer 5N4OSJMOEQBKAGX7HQSO"},verify = True)
        JSONvid = response2.json()
        address = str(JSONvid['address']['address_1'])+ ", " + str(JSONvid['address']['city']) + ", " + str(JSONvid['address']['region']) + " " + str(JSONvid['address']['postal_code'])
        event = {}
        event["name"] = JSONebList['events'][n]['name']['text']
        event["address"] = address
        event["url"] = JSONebList['events'][n]['url']
        event["time"] = JSONebList['events'][n]['start']['local']
        event["image"] = JSONebList['events'][n]['original']['url'] if 'original' in JSONebList['events'][n] and 'url' in JSONebList['events'][n]['original'] else 'https://www.tripsavvy.com/thmb/PdYn4eugR0zuP-oYGz00X9AYrvQ=/4037x2702/filters:fill(auto,1)/the-new-de-young-museum-in-golden-gate-park-148524473-591344515f9b5864703b6940.jpg'
        events.append(event)

    options = options + events
    preference_watch.append('1')

    if len(preference_watch) == len(list_of_preferences) + 2:
        preference_watch = []
        make_a_choice(lobby_id)


    return events










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
def getSeatGeek(idealLocation,highPrice,numberGoing, avgDist, list_of_preferences,lobby_id):
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

        if len(preference_watch) == len(list_of_preferences) + 2:
            preference_watch = []
            make_a_choice(lobby_id)
    else:
        return request



#################YELP API#################
def run_yelp_graph_query(query, headers, list_of_preferences,lobby_id): # A simple function to use requests.post to make the API call. Note the json= section.
    global preference_watch
    global options
    request = requests.post('https://api.yelp.com/v3/graphql', json={'query': query}, headers=headers)
    if request.status_code == 200:
        yelp_return = request.json()
        if yelp_return == None:
            return({"status": "error"})
        option_append = []
        for option in yelp_return['data']['search']['business']:
            option["hang_option"] = 'yelp'
            option_append.append(option)
        options = options + option_append

        preference_watch.append('1')
        if len(preference_watch) == len(list_of_preferences) + 2:
            preference_watch = []
            make_a_choice(lobby_id)
    else:
        return request
        # raise Exception("Query failed to run by returning code of {}. {}".format(request.status_code, query))



#intergrate with yelp api
def get_yelp_choices(list_of_preferences, ideal_location, lobby_id):
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
                    display_phone
                    photos
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
        run_yelp_graph_query(query_with_locations,headers,list_of_preferences,lobby_id)


def test():
    ideal_location = []
    ideal_location.append(37.780126)
    ideal_location.append(-122.410536)
    getSeatGeek(ideal_location,1000,100, 100,list_of_cats)
    # getSeatGeekr(ideal_location,1000,100, 100, 0.5,list_of_cats)
    get_yelp_choices('things',ideal_location)
    getEventBrite(ideal_location, 100, 0.5, list_of_cats)


def begin_compromise(lobby,lobby_id):
    list_of_preferences = []
    list_of_user_coords = []
    for uuid in lobby["current_members"]:
        for preference in lobby["current_members"][uuid]["preferences"]:
            list_of_preferences.append(preference)
        list_of_user_coords.append(lobby["current_members"][uuid]["location"])

    #get ideal location
    print(list_of_user_coords)
    location_return = getIdealLocation(list_of_user_coords)
    ideal_location = location_return[0]
    radius = location_return[1]
    #Remove this
    # ideal_location = [37.780126, -122.410536]
    print(ideal_location)
    getSeatGeek(ideal_location,1000,100, 100,list_of_cats,lobby_id)
    get_yelp_choices(list(set(list_of_preferences)), ideal_location,lobby_id)
    getEventBrite(ideal_location, 100, 0.5, list_of_cats,lobby_id)


def update_lobby_on_firebase(choices,lobby_id):
    this_lobby_ref = lobby_ref.child(lobby_id)

    this_lobby_ref.update({
            "choices": {
                "0": choices[0],
                "1": choices[1],
                "2": choices[2]
        },
        "state": "choice"
    })
    return json.dumps({"status":"success"})


def make_a_choice(lobby_id):
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
    print(choices)
    update_lobby_on_firebase(choices,lobby_id)
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
    # lobby_id = response.get_json()["lobby_id"]
    this_lobby_ref = lobby_ref.child(lobby_id)

    this_lobby_ref.update({
        "state": "started"
    })
    snapshot = lobby_ref.child(lobby_id).get()
    if snapshot is None:
        return json.dumps({"error": "User not found"})
    else:
        # lobby = json.dumps(snapshot)
        begin_compromise(snapshot, lobby_id)
        return json.dumps({"status":"success"})

@app.route('/lobby/choice/<lobby_id>/<choice_id>', methods=['POST'])
def decide(lobby_id,choice_id):
    #get user ids: -> call back
    # for each user -> get yelp choices
    #               ->  get seat_geek choices
    # make choice -> post to firebase
    #get lobby object with call back ->
    # get a set of preferences
    # lobby_id = response.get_json()["lobby_id"]
    this_lobby_ref = lobby_ref.child(lobby_id)

    this_lobby_ref.update({
        "choice": choice_id
    })
    return json.dumps({"status":"success"})