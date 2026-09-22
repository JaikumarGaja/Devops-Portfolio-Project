from flask import Flask, jsonify, request
from pymongo import MongoClient
import os
from dotenv import load_dotenv

load_dotenv()
URI = os.getenv("MONGO_URI")

client  = MongoClient(URI)
db = client.test
collection = db['flask-assignment']

app = Flask(__name__)
@app.route('/submit', methods=['POST'])
def submit():
    data = request.get_json()
    name = data.get('name')
    age = data.get('age')
    gender = data.get('gender')
    items = {
        'name': name,
        'age': age,
        'gender': gender
    }
    collection.insert_one(items)

    print(f"Received Form Data: Name: {name}, Age: {age}, Gender: {gender}")
    
    return jsonify({'message': 'Form data submitted successfully'}), 201

@app.route('/node_items', methods=['GET'])
def get_node_items():
    display_items = list(collection.find({}, {'_id': 0}))
    print(f"Fetched Items from MongoDB: {display_items}")
    return jsonify(display_items), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)