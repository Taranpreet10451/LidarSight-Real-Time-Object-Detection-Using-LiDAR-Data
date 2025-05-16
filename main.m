% ====== Setup paths =======
addpath("C:\Users\Taran\Desktop\Realtime_Object_detection\devkit_object\matlab");

% ====== Step 1: Load and visualize LiDAR point cloud =======
bin_path = 'C:\Users\Taran\Desktop\Realtime_Object_detection\data_object_velodyne\testing\velodyne\000003.bin';

fid = fopen(bin_path, 'rb');
if fid == -1
    error('Cannot open file: %s', bin_path);
end
velo_data = fread(fid, [4 inf], 'single')';
fclose(fid);

% Filter points within 50m ahead, +/- 20m sideways
range_mask = velo_data(:,1) > 0 & velo_data(:,1) < 50 & abs(velo_data(:,2)) < 20;
filtered_points = velo_data(range_mask, :);

figure; 
pcshow(filtered_points(:,1:3), filtered_points(:,4));
xlabel('X'); ylabel('Y'); zlabel('Z');
title('Filtered LiDAR Point Cloud');

% ====== Step 2: Run Python 3D detector on this LiDAR frame =======
python_executable = 'python';  % Or full path to python.exe
python_script = 'run_3d_detector.py'; % Your Python detector script

cmd = sprintf('%s %s "%s"', python_executable, python_script, bin_path);
[status, cmdout] = system(cmd);

if status ~= 0
    error('Python detection failed:\n%s', cmdout);
else
    fprintf('Python detection succeeded:\n%s\n', cmdout);
end

% ====== Step 3: Load detection results saved by Python =======
results_file = 'detection_results.mat';
if ~isfile(results_file)
    error('Detection results file not found: %s', results_file);
end

results = load(results_file);  % expects boundingBoxes [N x 7] and labels {N x 1}
bbox3d = results.boundingBoxes; % [x,y,z,l,w,h,rotation]
labels = results.labels;

% ====== Step 4: Visualize detections on point cloud with interaction =======
figure; 
pcshow(filtered_points(:,1:3), filtered_points(:,4));
xlabel('X'); ylabel('Y'); zlabel('Z');
title('LiDAR with 3D Detection Boxes');
hold on;

% Define colors for boxes
colors = lines(size(bbox3d,1));

% Preallocate handles: Each hBoxes{i} is an array of line handles for edges of the i-th box
hBoxes = cell(size(bbox3d,1),1);
hTexts = gobjects(size(bbox3d,1),1);

for i = 1:size(bbox3d,1)
    [hBoxes{i}, hTexts(i)] = plot3DBoundingBoxInteractive(bbox3d(i,:), labels(i), colors(i,:));
end

hold off;

% ====== Add UI controls =======
btnToggle = uicontrol('Style','pushbutton','String','Toggle Boxes',...
    'Position',[20 20 100 30],'Callback',@(src,event) toggleBoxes(hBoxes,hTexts));

btnHighlight = uicontrol('Style','pushbutton','String','Highlight Boxes',...
    'Position',[140 20 120 30],'Callback',@(src,event) highlightBoxes(hBoxes));

btnChangeColor = uicontrol('Style','pushbutton','String','Change Color',...
    'Position',[280 20 120 30],'Callback',@(src,event) changeColor(hBoxes));

% ====== Local Functions =======

function [hBoxLines, hText] = plot3DBoundingBoxInteractive(box, label, color)
    % box = [x, y, z, l, w, h, rot]
    l = box(4); w = box(5); h = box(6);
    x = box(1); y = box(2); z = box(3);
    ry = box(7);

    % corners before rotation (centered at origin)
    x_corners = [l/2 l/2 -l/2 -l/2 l/2 l/2 -l/2 -l/2];
    y_corners = [0 0 0 0 -h -h -h -h];  % height bottom to top
    z_corners = [w/2 -w/2 -w/2 w/2 w/2 -w/2 -w/2 w/2];

    % Rotation matrix around vertical axis (yaw)
    R = [cos(ry) 0 sin(ry);
         0       1 0;
        -sin(ry) 0 cos(ry)];

    corners = R * [x_corners; y_corners; z_corners];
    corners = corners + [x; y; z];

    edges = [1 2; 2 3; 3 4; 4 1;  % bottom face
             5 6; 6 7; 7 8; 8 5;  % top face
             1 5; 2 6; 3 7; 4 8]; % vertical edges

    hBoxLines = gobjects(size(edges,1),1);
    for e = 1:size(edges,1)
        pts = corners(:, edges(e,:));
        hBoxLines(e) = plot3(pts(1,:), pts(2,:), pts(3,:), 'Color', color, 'LineWidth', 2);
    end

    hText = text(x, y, z + h + 0.5, label, 'Color', 'yellow', 'FontSize', 12, 'FontWeight', 'bold');
end

function toggleBoxes(hBoxes,hTexts)
    % Toggle visibility on/off of all boxes and labels
    if strcmp(hBoxes{1}(1).Visible, 'on')
        newVis = 'off';
    else
        newVis = 'on';
    end
    for i = 1:numel(hBoxes)
        for j = 1:numel(hBoxes{i})
            hBoxes{i}(j).Visible = newVis;
        end
        hTexts(i).Visible = newVis;
    end
end

function highlightBoxes(hBoxes)
    % Highlight boxes by changing linewidth and color temporarily
    for i = 1:numel(hBoxes)
        for j = 1:numel(hBoxes{i})
            hBoxes{i}(j).LineWidth = 4;
            hBoxes{i}(j).Color = [1 0 0]; % bright red highlight
        end
    end
    pause(1.5);
    % Reset to original color and width
    for i = 1:numel(hBoxes)
        for j = 1:numel(hBoxes{i})
            hBoxes{i}(j).LineWidth = 2;
            hBoxes{i}(j).Color = lines(numel(hBoxes)); % reset to default colors
        end
    end
end

function changeColor(hBoxes)
    % Change color of boxes randomly
    for i = 1:numel(hBoxes)
        newColor = rand(1,3);
        for j = 1:numel(hBoxes{i})
            hBoxes{i}(j).Color = newColor;
        end
    end
end
