clc;
import
%clear all;
% data points here only contains length longer than certain threshold
data_points = load('/home/yi/vimslab/codeToBiomix/intersection_detection/data_seg.mat');
data_points = data_points.list_object;
fontSize = 20;
order = 3;
choice_of_skeletonization_method = 'bw_skel';




for n = 1:2:numel(data_points)
        disp(n);
        
        local_x = double(data_points{1,n});
        local_y = double(data_points{1,n+1});
        
        width = max(local_x) - min(local_x);
        height = max(local_y) - min(local_y);
        
        % shift to the center for visualization.
        
        local_y = local_y - (max(local_y) - double((max(local_y) - min(local_y))/2));
        local_x = local_x - (max(local_x) - double((max(local_x) - min(local_x))/2));
        
        % reconstruct the original segment.
        width = width + 20;
        height = height + 20;
        
        canvas = zeros(width,height); 
            
        ind = sub2ind(size(canvas), uint8(width/2 + local_x), uint8(height/2 + local_y));
        
        canvas(ind) = 1;
        
        % Skeletonize
        skeletonized = bwmorph(canvas,'skel',Inf);
        
        % save original local_y and local_x
        org_local_y = local_y;
        org_local_x = local_x;
        
        % obtain coordinate (x,y) of the skeleton
        ind = find(skeletonized);
        [local_x,local_y] = ind2sub(size(skeletonized),ind);
        
        % shift to the center for visualization.
        
        local_y = local_y - (max(local_y) - double((max(local_y) - min(local_y))/2));
        local_x = local_x - (max(local_x) - double((max(local_x) - min(local_x))/2));
        
        % Obtain orientation of the segment.
        % Fit y = F(x) or x = F(y) according to the orientation angle
        
        region_properties = regionprops(canvas,'orientation');
        orientation = region_properties.Orientation;

        % rotate if orienation is within certain range of angle.
        if orientation > 45 && orientation < 135
            % x = F(y)
            variable = local_x;
            target = local_y;
                   
            org_local_var = org_local_x;
            org_local_tar = org_local_y;
            rotate_flag = true;
        else
            % y = F(x)
            variable = local_y;
            target = local_x;
            
            org_local_var = org_local_y;
            org_local_tar = org_local_x;
            
            rotate_flag = false;
        end

        coefficients = polyfit(variable, target, order);
        
        fitted_target = polyval(coefficients, min(variable):max(variable));
        
        % Display the original image.

        if rotate_flag
            canvas = imrotate(canvas,90);
        end
        figure(1)

%         imshow(canvas, []);

        
        figure1 = figure(2);
        
     % overlay the original points
        plot(org_local_var, org_local_tar,'.','Color','g');
        
        hold on;
        
        plot(variable, target,'.');
        hold on;
        grid on;
        xlabel('X', 'FontSize', fontSize);
        ylabel('Y', 'FontSize', fontSize);

        
        % Overlay the skel points in red.
        hold on;
        plot(min(variable):max(variable), fitted_target, 'LineWidth', 2, 'MarkerSize', 10);
        axis([-25 25 -25 25])
        
       
        
        hold off;
        mkdir './curve_fitting/matlab_curve_fitting_skel/'
        saveas(figure1,strcat('./curve_fitting/matlab_curve_fitting_skel/',num2str(n) ,'.png'))
end
