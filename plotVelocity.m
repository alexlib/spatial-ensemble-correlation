
fSize = 12;
load('mng-1-072-B_sequence-001_000001-000999_EnsembleTranslations.mat')

uHead = -1 * u;
uHeadSmooth = -1 * uSmooth; 

% Net flow

uNet = trapz(t, uHeadSmooth);

plot(t, uHead * 10^3, 'k');
hold on;
plot(t, uHeadSmooth * 10^3, '-b', 'LineWidth', 2);
plot([0 max(t)], [uNet uNet] * 10^3, '--b');
plot([0 max(t)], [ 0 0 ], '-k');
hold off
xlabel('Time (seconds)', 'FontSize', fSize);
ylabel('Spatial ensemble of horizontal velocity (mm/s)', 'FontSize', fSize);
title({'Spatial ensemble of horizontal velocity'; 'Zero-mean subtracted'; 'Case mng-1-072-B\_sequence-001'; '1000 image pairs' }, 'FontSize', fSize);
set(gcf, 'color', [ 1 1 1 ]);
set(gca, 'FontSize', fSize);
axis square

imDir = '~/Desktop/sequence_001/raw';

rawImageBase = 'mng-1-072-B_sequence-001_';

imageFilePath = fullfile(imDir, [rawImageBase num2str(startImage, numberFormat) '.tif'] );
img = imread(imageFilePath);
imgFlipped = flipud(fliplr(img));
[rawHeight rawWidth] = size(img);


[height width] = size(img(1:1024, :));

maskTop = GRIDBUFFERY(1) - (rawHeight - height);
maskBottom = height - GRIDBUFFERY(2);

% Image is flipped so reverse the grid left and right buffers
maskLeft = width - GRIDBUFFERX(2);
maskRight = GRIDBUFFERX(1);

% rawMaskTop = GRIDBUFFERY(1);
% rawMaskBottom = rawHeight - GRIDBUFFERY(2);
% rawMaskLeft = GRIDBUFFERX(1);
% rawMaskRight = rawWidth - GRIDBUFFERX(2);

rawMaskTop = rawHeight - GRIDBUFFERY(1);
rawMaskBottom = GRIDBUFFERY(2);
rawMaskLeft = rawWidth - GRIDBUFFERX(1);
rawMaskRight = GRIDBUFFERX(2);


rawMaskPointsX = [rawMaskLeft rawMaskRight rawMaskRight rawMaskLeft rawMaskLeft];
rawMaskPointsY = [rawMaskTop rawMaskTop rawMaskBottom rawMaskBottom rawMaskTop];

[ X Y ] = meshgrid(0:rawWidth - 1, 0 : rawHeight - 1);
% [ X Y ] = meshgrid(width - 1 : 0, height - 1 : 0);

xmm = (X) * Mag * 10^3;
ymm = (Y) * Mag * 10^3;





for k = 1 : nImages
imageFilePath = fullfile(imDir, [rawImageBase num2str(startImage + k - 1, numberFormat) '.tif'] );
img =fliplr(flipud(imread(imageFilePath)));
imgCropped = img(1:1024, :);


subplot(1, 2, 1)
plot(t, uHead * 10^3, 'k');
hold on;
plot(t, uHeadSmooth * 10^3, '-b', 'LineWidth', 2);
plot([0 max(t)], [uNet uNet] * 10^3, '--b');
legend('Raw', 'Smoothed', 'Net', 'Location', 'SouthWest');
plot([0 max(t)], [ 0 0 ], '-k');
plot([t(k) t(k)] , [ -5 5], '--k');


hold off
ylim([-1.5 1]);
xlim([ 0 8]);
xlabel('Time (seconds)', 'FontSize', fSize);
ylabel('Spatial ensemble of horizontal velocity (mm/s)', 'FontSize', fSize);
title({'Spatial ensemble of horizontal velocity'; 'Zero-mean subtracted'; 'Case mng-1-072-B\_sequence-001'; '1000 image pairs'; ['Image ' num2str(startImage + k - 1)] }, 'FontSize', fSize);
set(gcf, 'color', [ 1 1 1 ]);
set(gca, 'FontSize', 12);
axis square

subplot(1, 2, 2);
imagesc(xmm(:), ymm(:), img); axis image; colormap gray
hold on;
plot(Mag * rawMaskPointsX * 10^3, Mag * rawMaskPointsY * 10^3, '-y');
hold off
title('Raw Image (head to left)', 'FontSize', fSize);
xlabel('Horizontal position (mm)', 'FontSize', fSize);
ylabel('Vertical position (mm)', 'FontSize', fSize);

set(gca, 'XDir', 'reverse');
set(gca, 'YDir', 'normal');
% axis image

% pause(0.01);
 
print(1, '-opengl', '-dpng',  '-r200', fullfile('plots', ['mng-1-072-B_sequence-001_' num2str(startImage + k - 1, numberFormat) '_plot.png']));
    
end