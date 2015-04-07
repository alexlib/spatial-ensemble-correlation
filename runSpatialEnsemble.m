% Add SPC directories
spc_parent_dir = ['/Users/matthewgiarra/Documents/School/VT/Research/' ...
    'Aether/SPC/analysis/src/spectral-phase-correlation'];

addpath(fullfile(spc_parent_dir, 'correlation_algorithms'));
addpath(fullfile(spc_parent_dir, 'correlation_algorithms',...
    'polyfitweighted2'));

addpath(fullfile(spc_parent_dir, 'filtering'));
addpath(fullfile(spc_parent_dir, 'phase_unwrapping'));
addpath(fullfile(spc_parent_dir, 'scripts'));

% Image directory
image_parent_dir = ['/Users/matthewgiarra/Documents/School/VT/Research/EFRI' ...
    '/analysis/data/Argonne_2014-07-21/grasshopper_xray/' ...
    'mng-1-163-C'];

% Raw image directory
raw_image_dir = fullfile(image_parent_dir, 'highpass_r_40');
% raw_image_dir = fullfile(image_parent_dir, 'div');

% Image base name
image_base_name = 'mng-1-163-C_meandiv_highpass_r_40_';
% image_base_name = 'mng-1-163-C_div_';

% Mask directory
mask_dir = fullfile(image_parent_dir, 'masks');

% Mask file name
mask_file_name = 'mng-1-163-C_static_mask_small.tif';
% mask_file_name = 'mng-1-163-C_static_mask.tif';

% Image extension
image_extension = '.tif';

% Correlation type
correlation_type = 'rpc';

% Number of digits
nDigits = 6;

% Start, end, skip images
start_image = 25;
end_image = 5450;
skip_image = 2;

% Correlation step
correlation_step = 2;

% Region size
region_size = 128 * [1, 1];

% Window fraction
spatial_window_fraction = 0.5 * [1, 1];

% RPC diameter
spatial_rpc_diameter = 8;

% Grid spacing
grid_spacing = 16 * [1, 1];

% Grid buffer X
grid_buffer_X = [64, 64];

% Grid buffer Y
grid_buffer_Y = [64, 64];

% Image lists
image_list_01 = start_image : skip_image : end_image;
image_list_02 = image_list_01 + correlation_step;

% Number of images
num_images = length(image_list_01);

% Number format
num_format = ['%0' num2str(nDigits) 'd'];

% Allocate the velocity vectors
% Three columns for three peaks.
U = zeros(num_images, 1);
V = zeros(num_images, 1);

% Allocate correlation planes
rpc_plane_list = zeros([region_size, num_images]);

% Load the mask
mask_file_path = fullfile(mask_dir, mask_file_name);
mask = double(imread(mask_file_path));

% Mask method 
mask_method = '';

% Compiled flag
compiled = 1;

% Loop over the images
for k = 1 : num_images
    
    fprintf(1, 'Processing image pair %d of %d...\n', k, num_images);
    
    % Image 1 name
    image_name_01 = [image_base_name num2str(image_list_01(k),...
        num_format), image_extension];
    
    % Image 2 name
    image_name_02 = [image_base_name num2str(image_list_02(k),...
        num_format), image_extension];
    
    % Image paths
    image_path_01 = fullfile(raw_image_dir, image_name_01);
    image_path_02 = fullfile(raw_image_dir, image_name_02);
    
    % Load the images
    image_01 = imread(image_path_01);
    image_02 = imread(image_path_02); 
    
    % Perform the spatial ensemble correlations.
    [V(k), U(k), rpc_plane_list(:, :, k)] = rpcSpatialEnsemble(image_01, ...
        image_02, grid_spacing, grid_buffer_Y, grid_buffer_X, ...
        region_size, spatial_window_fraction, correlation_type, spatial_rpc_diameter, ...
        mask, mask_method, compiled);
    
%     r = rpc_plane_list(:, :, k);
%     
%     subplot(1, 2, 1);
%     imagesc(image_01); axis image; colormap gray;
%     
%     subplot(1, 2, 2); 
%     mesh(r ./ max(r(:)), 'edgeColor', 'black');
%     axis square;
%     pause(0.1);
    
    
    
    
end

% Transform the data to get the axial velocity
% Note that Positive X is to the right in images 
% but to the left in the animal (toward the head),
% and positive Y is down in thet images 
% but up in the animal (toward the dorsal surface).

% This is the angle of the heart flow axis to the left-horizontal axis
% measured from the images using ImageJ
th = deg2rad(10);

% This is the magnitude of the measured flow displacement
% along the heart flow axis
u_axial_pix = -(U * cos(th) - V * sin(th));

% This is the camera magnification
mm_per_pix = 1E-3;

% This is the frame rate
frames_per_second = 500;



% This is the time vector
time_vect = image_list_01 / frames_per_second;


% Valid lists
valid_time_list = time_vect(~isnan(U));
valid_u_pix = u_axial_pix(~isnan(U));

% This is the measured axial velocity in mm/sec
u_axial_mm = valid_u_pix * mm_per_pix * frames_per_second...
            / correlation_step;

% Window size for smoothing
win_size = 20;
c = ones(win_size, 1) ./ win_size;

% Smooth the data
valid_u_pix_smoothed = conv(valid_u_pix, c, 'same');
valid_u_mm_smoothed = valid_u_pix_smoothed * mm_per_pix * ...
    frames_per_second / correlation_step;

% Plot the velocity vs time
f = plot(valid_time_list, valid_u_pix, '-k');
% f = plot(valid_time_list, u_axial_mm, '-k');

set(f, 'color', 0.5 * [1, 1, 1]);
xlabel('Time (seconds)', 'FontSize', 16);
ylabel('Displacement (pixels / frame)', 'FontSize', 16);
% ylabel('Velocity (mm / sec)', 'FontSize', 16);
set(gca, 'FontSize', 16);
% axis square;

hold on;
plot(valid_time_list, valid_u_pix_smoothed, '-k', 'LineWidth', 2);
% plot(valid_time_list, valid_u_mm_smoothed, '-k', 'LineWidth', 2);

plot([0, 1.5 * max(valid_time_list)], [0, 0], '--k');
xlim([0 max(valid_time_list)]);

ylim([-16, 16]);

h = legend('Raw signal', 'Moving-mean');
set(h, 'FontSize', 16);

grid on;
grid minor;

title(...
{'Spatial-average ensemble correlation in grasshopper heart',...
['RPC (filter diameter ' num2str(spatial_rpc_diameter) ' pix), Correlation step 2']});

hold off

set(gcf,'papersize',[12,4]);
set(gcf,'paperposition',[0,0,12,4]);













