import rasterio
import matplotlib.pyplot as plt
import numpy as np
from rasterio.plot import show

# Path to your exported GeoTIFF
geotiff_path = 'satellite_buildings_overlay_bangalore.tif'

# Define GPS points (lat, lon)
gps_points = [
    (12.912427, 77.595997),  # Soldier
    (12.912429, 77.596022),  # Soldier
    (12.912590, 77.596188),  # Soldier
    (12.912640, 77.595788)   # Armed vehicle
]

with rasterio.open(geotiff_path) as src:
    # Read RGB bands directly — no normalization needed for uint8
    img = src.read([1, 2, 3])  # shape: (3, height, width)

    # Rearrange for matplotlib (height, width, bands)
    img = np.transpose(img, (1, 2, 0))  # shape: (height, width, 3)

    # Plot image
    fig, ax = plt.subplots(figsize=(12, 12))
    ax.imshow(img)

    # Plot GPS points
    for lat, lon in gps_points:
        row, col = rasterio.transform.rowcol(src.transform, lon, lat)
        color = 'blue' if (lat, lon) == (12.912640, 77.595788) else 'red'
        ax.plot(col, row, 'o', markersize=10,
                markerfacecolor=color,
                markeredgecolor='white',
                markeredgewidth=2)

    plt.title('UAV Detections on Satellite Map with Buildings Overlay')
    plt.axis('off')
    plt.tight_layout()
    plt.show()
