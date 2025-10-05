// can't be less than 0 and shouldn't be more than 2 seconds
[Setting name="Resolution"]
float resolution;

// ensures the settings are within their valid range
void EnsureSettings() {
    if (resolution < 0) { resolution = 0; }
    else if (resolution > 2) { resolution = 2; }
}

void RenderSettings() {
    // ensures settings are within valid ranges
    EnsureSettings();

    UI::Text("Hello");
}