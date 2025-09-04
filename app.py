from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.get("/")
def root():
    return jsonify(message="Hello, world! Flask on Kubernetes")
@app.get("/health")
def health():
    return "ok", 200

if __name__ == "__main__":
    port = int(os.getend("PORT", "8000"))
    app.run(host="0.0.0.0", port=port)