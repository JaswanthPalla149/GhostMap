import rasterio
import numpy as np
from PIL import Image
import os

# Configuration
INPUT_TIFF = 'satellite_buildings_overlay_bangalore.tif'
OUTPUT_PNG = 'satellite_bangalore.png'

try:
    with rasterio.open(INPUT_TIFF) as src:
        # 1. Read RGB bands
        img = src.read([1, 2, 3])
        
        # 2. Critical: Apply contrast stretching
        img_normalized = np.zeros_like(img, dtype=np.uint8)
        for i in range(3):
            band = img[i].astype(float)
            
            # Handle special case: Constant value bands
            if np.min(band) == np.max(band):
                img_normalized[i] = band.astype(np.uint8)
                continue
                
            # Calculate 2nd and 98th percentiles
            p2, p98 = np.percentile(band, (2, 98))
            
            # Apply contrast stretch
            band = (band - p2) / (p98 - p2) * 255
            img_normalized[i] = np.clip(band, 0, 255).astype(np.uint8)

        # 3. Transpose and save
        img_out = np.transpose(img_normalized, (1, 2, 0))
        Image.fromarray(img_out).save(OUTPUT_PNG)
        
        # 4. Print bounds for QML
        bounds = src.bounds
        print(f"✅ Saved enhanced image to {OUTPUT_PNG}")
        print("\n🔥 Set these in RasterMap.qml:")
        print(f"mapMinLat: {bounds.bottom}")
        print(f"mapMaxLat: {bounds.top}")
        print(f"mapMinLon: {bounds.left}")
        print(f"mapMaxLon: {bounds.right}")
        
except Exception as e:
    print(f"❌ Conversion failed: {str(e)}")
    if not os.path.exists(INPUT_TIFF):
        print(f"File not found: {os.path.abspath(INPUT_TIFF)}")
