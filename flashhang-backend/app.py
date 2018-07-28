"""
app.py

File that is the central location of code for our app.
"""

from flask import Flask, request
import requests

# Create application, and point static path (where static resources like images, css, and js files are stored) to the
# "static folder"
app = Flask(__name__, static_url_path="/static")


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

