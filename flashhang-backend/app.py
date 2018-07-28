"""
app.py

File that is the central location of code for our app.
"""

from flask import Flask, request
import sqlalchemy
import random
import json
import requests

# Create application, and point static path (where static resources like images, css, and js files are stored) to the
# "static folder"
app = Flask(__name__, static_url_path="/static")
sql_engine = sqlalchemy.create_engine('mysql://flash:hang@localhost/db')


@app.route('/get')
def simple_get():
    """
    Get example
    """
    return "hi"  # Render the template located in "templates/index.html"


@app.route('/post', methods=['POST'])
def simple_post():
    """
    Post example
    """
    data = request.form.get("data") # "request.form" is an example of a form that contains a "data" field
    return data


@app.route('/loggedin', methods=['POST'])
def retrieve_user_info():
    uid = request.form.get("uid") # facebook user id
    query_for_user = """
        SELECT *
        FROM users
        WHERE user_id=:user_id
    """
    conn = sql_engine.connect()
    result = conn.execute(query_for_user, user_id=uid)
    if result is None:
        return json.dumps({"error": "User not found"})
    else:
        return json.dumps(dict(result))


@app.route('/startlobby', methods=['POST'])
def create_new_lobby():
    host_uid = request.form.get("uid")
    lobby_name = request.form.get("lobby_name")
    new_lobby_id = random.getrandbits(128)
    insert_new_lobby_query = """
    INSERT INTO LOBBIES (ID,NAME,STATE,HOST_ID)
    VALUES (:id, :name, "Pre_Comp", :host_id);
    """
    conn = sql_engine.connect()
    result = conn.execute(insert_new_lobby_query, id=new_lobby_id, name=lobby_name, host_id=host_uid)
    return json.dumps({"lobby_id": new_lobby_id})







