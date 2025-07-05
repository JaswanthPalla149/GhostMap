// projector.cpp
#define _USE_MATH_DEFINES
#include <pybind11/pybind11.h>
#include <pybind11/stl.h>
#include <cmath>
#include <fstream>
#include <sstream>
#include <vector>
#include <string>
#include <iostream>
#include <unordered_map>

namespace py = pybind11;

const double EARTH_RADIUS = 6378137.0;

struct UAVMeta {
    double lat;
    double lon;
    double alt;
    double pitch_deg;
    double yaw_deg;
    double fov_deg;
    int img_w;
    int img_h;
};

struct Detection {
    int class_id;
    //std::string label;
    double x; // normalized center x
    double y; // normalized center y
    double w; // normalized width
    double h; // normalized height
};

struct GeoCoord {
    std::string class_id;
    std::string color;
    double lat;
    double lon;
};

inline double deg2rad(double deg) {
    return deg * M_PI / 180.0;
}
std::unordered_map<int, std::string> classIdToLabel;
std::unordered_map<int, std::string> classIdToColor;
bool loadClassMap(const std::string& filepath) {
    std::ifstream file(filepath);
    if (!file.is_open()) {
        std::cerr << "Failed to open class map file: " << filepath << std::endl;
        return false;
    }

    classIdToLabel.clear();
    classIdToColor.clear();
    std::string line;
    int index = 0;

    while (std::getline(file, line)) {
        std::istringstream iss(line);
        std::string label, color;
        iss >> label >> color;

        if (!label.empty()) {
            classIdToLabel[index] = label;
            classIdToColor[index] = color;  // optional now
            index++;
        }
    }

    file.close();
    return true;
}



// === Main function: assumes normalized input, converts to pixel coords, then GPS ===
std::vector<GeoCoord> projectDetectionsToGPS(const std::vector<Detection>& detections, const UAVMeta& meta) {
    std::vector<GeoCoord> output;

    double fx = (meta.img_w / 2.0) / tan(deg2rad(meta.fov_deg / 2.0));
    double fy = fx; // assuming square pixels
    double cx = meta.img_w / 2.0;
    double cy = meta.img_h / 2.0;

    double pitch_rad = deg2rad(meta.pitch_deg);
    double yaw_rad = deg2rad(meta.yaw_deg);

    for (const auto& d : detections) {
        // === Convert normalized values to pixel coordinates ===
        double abs_cx = d.x * meta.img_w;
        double abs_cy = d.y * meta.img_h;
        double abs_w  = d.w * meta.img_w;
        double abs_h  = d.h * meta.img_h;
        double px = abs_cx - abs_w / 2.0;
        double py = abs_cy - abs_h / 2.0;

        // Center of bbox in pixels
        double u = px + abs_w / 2.0;
        double v = py + abs_h / 2.0;

        // Camera space coordinates
        double x_cam = (u - cx) / fx;
        double y_cam = (v - cy) / fy;
        double z_cam = 1.0;

        // Normalize
        double norm = std::sqrt(x_cam * x_cam + y_cam * y_cam + z_cam * z_cam);
        x_cam /= norm; y_cam /= norm; z_cam /= norm;

        // Pitch rotation (X-axis)
        double y1 = cos(pitch_rad) * y_cam - sin(pitch_rad) * z_cam;
        double z1 = sin(pitch_rad) * y_cam + cos(pitch_rad) * z_cam;
        double x1 = x_cam;

        // Yaw rotation (Z-axis)
        double x2 = cos(yaw_rad) * x1 - sin(yaw_rad) * y1;
        double y2 = sin(yaw_rad) * x1 + cos(yaw_rad) * y1;
        double z2 = z1;

        // Ray projection to ground
        double t = -meta.alt / z2;
        double dx = t * x2;
        double dy = t * y2;

        // Convert to lat/lon
        double new_lat = meta.lat + (dy / EARTH_RADIUS) * (180.0 / M_PI);
        double new_lon = meta.lon + (dx / (EARTH_RADIUS * cos(deg2rad(meta.lat)))) * (180.0 / M_PI);
        std::string label = classIdToLabel.count(d.class_id) ? classIdToLabel[d.class_id] : "unknown";
        std::string color = classIdToColor.count(d.class_id) ? classIdToColor[d.class_id] : "#000000";
        output.push_back({ label, color,new_lat, new_lon });
    }

    return output;
}

// === PYBIND bindings ===
PYBIND11_MODULE(projector, m) {
    py::class_<Detection>(m, "Detection")
        .def(py::init<>())
        .def_readwrite("class_id", &Detection::class_id)
        .def_readwrite("x", &Detection::x)
        .def_readwrite("y", &Detection::y)
        .def_readwrite("w", &Detection::w)
        .def_readwrite("h", &Detection::h);

    py::class_<UAVMeta>(m, "UAVMeta")
        .def(py::init<>())
        .def_readwrite("lat", &UAVMeta::lat)
        .def_readwrite("lon", &UAVMeta::lon)
        .def_readwrite("alt", &UAVMeta::alt)
        .def_readwrite("pitch_deg", &UAVMeta::pitch_deg)
        .def_readwrite("yaw_deg", &UAVMeta::yaw_deg)
        .def_readwrite("fov_deg", &UAVMeta::fov_deg)
        .def_readwrite("img_w", &UAVMeta::img_w)
        .def_readwrite("img_h", &UAVMeta::img_h);

    py::class_<GeoCoord>(m, "GeoCoord")
        .def_readonly("class_id", &GeoCoord::class_id)
        .def_readonly("color", &GeoCoord::color)
        .def_readonly("lat", &GeoCoord::lat)
        .def_readonly("lon", &GeoCoord::lon);
    m.def("loadClassMap", &loadClassMap, "Load class ID to label mapping from file");
    m.def("projectDetectionsToGPS", &projectDetectionsToGPS, "Convert normalized detections to GPS");
}
