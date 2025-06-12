# temp_server.py

from fastapi import FastAPI
from fastapi.responses import JSONResponse
import threading
import time
import json

app = FastAPI()

# Configuration
DATA_FILE = "fake_server_data.json"
DEVICES_PER_RESPONSE = 5  # Number of devices to return in each response

try:
    with open(DATA_FILE, "r") as f:
        full_data = json.load(f)

        # Extract individual devices as a list of (device_id, device_data) tuples
        device_items = list(full_data.items())

        # Create batches of devices for rotation
        json_outputs = []

        for i in range(0, len(device_items), DEVICES_PER_RESPONSE):
            # Get a batch of devices (up to DEVICES_PER_RESPONSE)
            batch = device_items[i:i + DEVICES_PER_RESPONSE]

            # Create a multi-device response with this batch
            batch_response = {}
            for device_id, device_data in batch:
                batch_response[device_id] = device_data

            json_outputs.append(batch_response)

        print(f"Loaded {len(device_items)} total devices")
        print(f"Created {len(json_outputs)} batches of {DEVICES_PER_RESPONSE} devices each")

        # Show the device IDs in each batch
        for i, batch in enumerate(json_outputs):
            batch_device_ids = list(batch.keys())
            print(f"Batch {i}: {batch_device_ids}")

except Exception as e:
    print(f"Error reading data file '{DATA_FILE}': {e}")
    json_outputs = []

# Shared index for current response
current_index = 0


def rotate_output():
    global current_index
    while True:
        time.sleep(10)  # Rotate every 10 seconds (change to 60 if needed)
        if len(json_outputs) > 1:
            current_index = (current_index + 1) % len(json_outputs)
            current_device_ids = list(json_outputs[current_index].keys())
            print(f"Rotated to batch {current_index}: {current_device_ids}")


# Start background thread for rotating output
if json_outputs:
    threading.Thread(target=rotate_output, daemon=True).start()


@app.get("/data")
def get_data():
    if not json_outputs:
        return JSONResponse(content={"error": "No data loaded"}, status_code=500)
    current_response = json_outputs[current_index]
    current_device_ids = list(current_response.keys())
    print(f"Serving batch {current_index} with {len(current_device_ids)} devices: {current_device_ids}")

    return JSONResponse(content=current_response)


@app.get("/health")
def health():
    current_devices = []
    if json_outputs:
        current_devices = list(json_outputs[current_index].keys())

    return {
        "status": "ok",
        "total_devices": sum(len(batch) for batch in json_outputs),
        "total_batches": len(json_outputs),
        "devices_per_batch": DEVICES_PER_RESPONSE,
        "current_batch": current_index,
        "current_devices": current_devices
    }


@app.get("/devices")
def list_devices():
    """Debug endpoint to show all loaded device IDs and batch information"""
    all_device_ids = []
    batch_info = []

    for i, batch in enumerate(json_outputs):
        batch_devices = list(batch.keys())
        all_device_ids.extend(batch_devices)
        batch_info.append({
            "batch_index": i,
            "device_count": len(batch_devices),
            "device_ids": batch_devices
        })

    return {
        "total_devices": len(all_device_ids),
        "total_batches": len(json_outputs),
        "devices_per_batch": DEVICES_PER_RESPONSE,
        "current_batch": current_index,
        "all_devices": all_device_ids,
        "batch_details": batch_info
    }


@app.get("/config")
def get_config():
    """Endpoint to show current configuration"""
    return {
        "devices_per_response": DEVICES_PER_RESPONSE,
        "rotation_interval_seconds": 10,
        "data_file": DATA_FILE
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)