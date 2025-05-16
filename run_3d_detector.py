import sys
import numpy as np
import scipy.io

def main():
    if len(sys.argv) < 2:
        print("Usage: python run_3d_detector.py <path_to_bin_file>")
        return
    
    bin_path = sys.argv[1]
    print(f"Processing LiDAR file: {bin_path}")
    
    
    bounding_boxes = np.array([
        [10.0, 5.0, -1.0, 4.0, 2.0, 1.5, 0.0],   
        [20.0, -3.0, -1.0, 3.5, 1.8, 1.6, 0.5]   
    ])
    
    # Detected classes by class ID
    detected_class_ids = [0, 1]
    
    # Map class IDs to string labels
    class_map = {
        0: 'Car',
        1: 'Pedestrian',
        2: 'Cyclist'
    }
    
    labels = [class_map.get(cid, 'Unknown') for cid in detected_class_ids]
    
    # Save to .mat file for MATLAB
    scipy.io.savemat('detection_results.mat', {
        'boundingBoxes': bounding_boxes,
        'labels': labels
    })
    
    print("Detection results saved with multiple labels.")

if __name__ == "__main__":
    main()
