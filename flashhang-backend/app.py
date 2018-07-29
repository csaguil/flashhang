"""
app.py

File that is the central location of code for our app.
"""

from flask import Flask, request
import random
import json
import os
import firebase_admin
from firebase_admin import credentials
from firebase_admin import db


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
    new_lobby_id = random.getrandbits(16)
    lobby_ref.update({
        new_lobby_id: {
            'name': lobby_name,
            'state': "Pre_Comp",
            'host_uid': host_uid
        }
    })
    return json.dumps({"lobby_id": str(new_lobby_id)})


@app.route('/lobby/join/<lobby_id>', methods=['POST'])
def join_lobby(lobby_id):
    uid = request.args.get("uid")
    user_current_location = request.args.get("location")
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
    this_lobby_ref = lobby_ref.child(lobby_id)
    this_lobby = this_lobby_ref.get()
    this_lobby_current_members = this_lobby["current_members"] if "current_members" in this_lobby else None
    if this_lobby_current_members is None:
        this_lobby_ref.update({
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
