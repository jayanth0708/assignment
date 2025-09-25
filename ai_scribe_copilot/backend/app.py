from flask import Flask, jsonify, request
import uuid
import os

app = Flask(__name__)

# In-memory storage for simplicity.
# In a real application, you'd use a database.
patients = {
    "patient-1": {"name": "John Doe", "id": "patient-1"},
    "patient-2": {"name": "Jane Smith", "id": "patient-2"},
}
sessions = {}
audio_chunks = {}

# Ensure an upload directory exists
if not os.path.exists("uploads"):
    os.makedirs("uploads")

@app.route("/")
def health_check():
    return "Backend is running!"

# Session Management
@app.route("/v1/upload-session", methods=["POST"])
def upload_session():
    data = request.get_json()
    patient_id = data.get("patientId")
    if not patient_id or patient_id not in patients:
        return jsonify({"error": "Invalid patient ID"}), 400

    session_id = f"session-{uuid.uuid4()}"
    sessions[session_id] = {"patientId": patient_id, "chunks": []}
    return jsonify({"sessionId": session_id}), 200

@app.route("/v1/get-presigned-url", methods=["POST"])
def get_presigned_url():
    data = request.get_json()
    session_id = data.get("sessionId")
    if not session_id or session_id not in sessions:
        return jsonify({"error": "Invalid session ID"}), 400

    chunk_id = f"chunk-{uuid.uuid4()}"
    # In a real backend, you would generate a proper presigned URL for a cloud storage service like S3.
    # Here, we'll just return a local URL for our mock server.
    presigned_url = f"{request.host_url}v1/audio-chunk/{chunk_id}"
    audio_chunks[chunk_id] = {"sessionId": session_id, "uploaded": False}
    return jsonify({"url": presigned_url, "chunkId": chunk_id})

@app.route("/v1/audio-chunk/<string:chunk_id>", methods=["PUT"])
def upload_audio_chunk(chunk_id):
    if chunk_id not in audio_chunks:
        return jsonify({"error": "Invalid chunk ID"}), 404

    # Save the uploaded audio data to a file
    chunk_filename = os.path.join("uploads", f"{chunk_id}.wav")
    with open(chunk_filename, "wb") as f:
        f.write(request.data)

    return jsonify({"message": "Chunk uploaded successfully"}), 200


@app.route("/v1/notify-chunk-uploaded", methods=["POST"])
def notify_chunk_uploaded():
    data = request.get_json()
    session_id = data.get("sessionId")
    chunk_id = data.get("chunkId")

    if session_id not in sessions or chunk_id not in audio_chunks:
        return jsonify({"error": "Invalid session or chunk ID"}), 400

    if audio_chunks[chunk_id]["sessionId"] != session_id:
        return jsonify({"error": "Chunk does not belong to this session"}), 400

    audio_chunks[chunk_id]["uploaded"] = True
    sessions[session_id]["chunks"].append(chunk_id)

    print(f"Chunk {chunk_id} for session {session_id} marked as uploaded.")

    return jsonify({"message": "Notification received"}), 200

# Patient Management
@app.route("/v1/patients", methods=["GET"])
def get_patients():
    user_id = request.args.get("userId")
    # In a real app, you'd use the userId to filter patients.
    # Here we return all patients for simplicity.
    return jsonify(list(patients.values()))

@app.route("/v1/add-patient-ext", methods=["POST"])
def add_patient():
    data = request.get_json()
    patient_name = data.get("name")
    if not patient_name:
        return jsonify({"error": "Patient name is required"}), 400

    patient_id = f"patient-{uuid.uuid4()}"
    patients[patient_id] = {"name": patient_name, "id": patient_id}
    return jsonify(patients[patient_id]), 201

@app.route("/v1/fetch-session-by-patient/<string:patient_id>", methods=["GET"])
def fetch_sessions_by_patient(patient_id):
    if patient_id not in patients:
        return jsonify({"error": "Patient not found"}), 404

    patient_sessions = [
        {"sessionId": s_id, **s_data}
        for s_id, s_data in sessions.items()
        if s_data["patientId"] == patient_id
    ]
    return jsonify(patient_sessions)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)