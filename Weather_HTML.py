import json
import time
import os
from datetime import datetime

# =========================
# CONFIG
# =========================
JSON_FILE = "weather.json"      # local JSON file being updated by another service
OUTPUT_HTML = "weather.html"    # HTML file Concerto will display
REFRESH_SECONDS = 300           # check every 5 minutes


# =========================
# HELPER FUNCTIONS
# =========================
def kelvin_to_fahrenheit(kelvin):
    return round((kelvin - 273.15) * 9 / 5 + 32)


def unix_to_local_time(timestamp, timezone_offset):
    local_timestamp = timestamp + timezone_offset
    return datetime.utcfromtimestamp(local_timestamp).strftime("%I:%M %p")


def load_json_file(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def build_html(data):
    city = data.get("name", "Unknown Location")
    country = data.get("sys", {}).get("country", "")
    weather_info = data.get("weather", [{}])[0]
    main = data.get("main", {})
    wind = data.get("wind", {})
    clouds = data.get("clouds", {})
    timezone_offset = data.get("timezone", 0)

    weather_id = weather_info.get("id", 800)
    description = weather_info.get("description", "No description").title()

    current_temp = kelvin_to_fahrenheit(main.get("temp", 0))
    feels_like = kelvin_to_fahrenheit(main.get("feels_like", 0))
    temp_min = kelvin_to_fahrenheit(main.get("temp_min", 0))
    temp_max = kelvin_to_fahrenheit(main.get("temp_max", 0))

    humidity = main.get("humidity", "N/A")
    pressure = main.get("pressure", "N/A")
    wind_speed = wind.get("speed", "N/A")
    wind_deg = wind.get("deg", "N/A")
    cloud_cover = clouds.get("all", "N/A")
    visibility = data.get("visibility", "N/A")

    sunrise = unix_to_local_time(data.get("sys", {}).get("sunrise", 0), timezone_offset)
    sunset = unix_to_local_time(data.get("sys", {}).get("sunset", 0), timezone_offset)

    updated_time = datetime.now().strftime("%Y-%m-%d %I:%M:%S %p")

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="refresh" content="{REFRESH_SECONDS}">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Weather for {city}</title>

    <link rel="stylesheet" href="https://websygen.github.io/owfont/css/owfont-regular.css">

    <style>
        body {{
            font-family: Arial, sans-serif;
            background-color: #f4f4f4;
            margin: 0;
            padding: 30px;
            color: #222;
        }}

        .card {{
            max-width: 900px;
            margin: auto;
            background: white;
            border-radius: 15px;
            padding: 30px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
            overflow: hidden;
        }}

        h1 {{
            margin-top: 0;
            font-size: 42px;
        }}

        .left {{
            float: left;
            width: 45%;
            text-align: center;
        }}

        .right {{
            float: left;
            width: 55%;
        }}

        .temp {{
            font-size: 60px;
            margin: 10px 0;
            font-weight: bold;
        }}

        .label {{
            font-size: 20px;
            color: #666;
        }}

        .details {{
            clear: both;
            margin-top: 30px;
            font-size: 20px;
            line-height: 1.8;
        }}

        .updated {{
            margin-top: 25px;
            font-size: 16px;
            color: #777;
        }}
    </style>
</head>
<body>
    <div class="card">
        <h1>Today in {city}</h1>

        <div class="left">
            <i class="owf owf-{weather_id} owf-5x"></i>
            <p style="font-size: 22px;">{description}</p>
        </div>

        <div class="right">
            <p class="label">Current</p>
            <div class="temp">{current_temp}&deg;F</div>
            <p style="font-size: 22px;">Feels like: {feels_like}&deg;F</p>
            <p style="font-size: 22px;">Low / High: {temp_min}&deg;F / {temp_max}&deg;F</p>
        </div>

        <div class="details">
            <p><strong>Humidity:</strong> {humidity}%</p>
            <p><strong>Pressure:</strong> {pressure} hPa</p>
            <p><strong>Wind:</strong> {wind_speed} m/s at {wind_deg}&deg;</p>
            <p><strong>Cloud Cover:</strong> {cloud_cover}%</p>
            <p><strong>Visibility:</strong> {visibility} meters</p>
            <p><strong>Sunrise:</strong> {sunrise}</p>
            <p><strong>Sunset:</strong> {sunset}</p>
            <p><strong>Country:</strong> {country}</p>
        </div>

        <div class="updated">
            Last updated: {updated_time}
        </div>
    </div>
</body>
</html>
"""
    return html


def write_html_file(path, html_content):
    with open(path, "w", encoding="utf-8") as f:
        f.write(html_content)


# =========================
# MAIN LOOP
# =========================
def main():
    last_modified_time = None

    while True:
        try:
            if not os.path.exists(JSON_FILE):
                print(f"JSON file not found: {JSON_FILE}")
            else:
                current_modified_time = os.path.getmtime(JSON_FILE)

                # Only rebuild HTML if the JSON file changed
                if last_modified_time is None or current_modified_time != last_modified_time:
                    data = load_json_file(JSON_FILE)
                    html_content = build_html(data)
                    write_html_file(OUTPUT_HTML, html_content)

                    last_modified_time = current_modified_time
                    print(f"Updated {OUTPUT_HTML} from {JSON_FILE}")
                else:
                    print("No JSON changes detected.")

        except Exception as e:
            print(f"Error: {e}")

        time.sleep(REFRESH_SECONDS)


if __name__ == "__main__":
    main()


#This assumes something else is already updating weather.json.
#If that JSON uses units=imperial, then you should remove the Kelvin conversion.
