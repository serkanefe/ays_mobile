# -*- coding: utf-8 -*-
from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/test')
def test():
    return jsonify({"status": "OK", "message": "API working"})

@app.route('/')
def home():
    return jsonify({"message": "Home page"})

if __name__ == '__main__':
    app.run(debug=False)
