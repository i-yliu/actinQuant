clc;
import
% clear all;
addpath('/home/yi/matlab/pakages/CCToolbox/')

% data points here only contains length longer than certain threshold
data_points = load('./data_seg.mat');
% data_points = load('./keypoints_data.mat');
bi_mask = imread('HopE1_Sample1_image1_lifeact_ts1_Maximum intensity projection_predict.png');
bi_mask = logical(bi_mask);
testing = bi_mask * 200;
data_points = data_points.list_object;
fontSize = 20;
order = 3;
choice_of_skeletonization_method = 'bw_skel';
setcctpath

data_points_cell = {};
time_series={}

ops = lrm('options') ;
ops.order = 3;
ops.K = 3;
canvas_reconstruction = zeros(size(bi_mask));
%% 
for n = 1:2:numel(data_points)
        local_x = double(data_points{1,n}); % col
        local_y = double(data_points{1,n+1});    %row    
        local_x_unshifted = local_x;
        local_y_unshifted = local_y;

 % shift to the center for visualization.
        width = max(local_x) - min(local_x);
        height = max(local_y) - min(local_y);
        center_coor_y = (max(local_y) - double((max(local_y) - min(local_y))/2));
        center_coor_x = (max(local_x) - double((max(local_x) - min(local_x))/2));
        
        shifted_val_y = (max(local_y) - double((max(local_y) - min(local_y))/2));
        shifted_val_x = (max(local_x) - double((max(local_x) - min(local_x))/2));
        local_y = local_y - (max(local_y) - double((max(local_y) - min(local_y))/2));
        local_x = local_x - (max(local_x) - double((max(local_x) - min(local_x))/2));
   
 % reconstruct the original segment.
%         width = width + 20;
%         height = height + 20;
        canvas = zeros(height + 1, width + 1); 
        ind = sub2ind(size(canvas),  int64(height/2 + local_y + 1), int64(width/2 + local_x + 1));

        canvas(ind) = 1;
        [ org_local_y, org_local_x] = ind2sub(size(canvas), ind);

        
     %% Skeletonize
    skeletonized = bwmorph(canvas,'skel',Inf);
    [ske_x, ske_y] = ind2sub(size(canvas), find(skeletonized));
        %% prune v1
    B = bwmorph(skeletonized, 'branchpoints');
    E = bwmorph(skeletonized, 'endpoints');
    [y,x] = find(E);
    B_loc = find(B);
    len_B_loc = size(B_loc);
    if len_B_loc ~= 0
        Dmask = false(size(skeletonized));
        for k = 1:numel(x)
            D = bwdistgeodesic(skeletonized,x(k),y(k));
            distanceToBranchPt = min(min(D(B_loc)), 5);
            Dmask(D < distanceToBranchPt) =true;
        end
        skeletonized = skeletonized - Dmask;
    end
    
    %% prune v2
    skeletonized = logical(skeletonized);
    B = bwmorph(skeletonized, 'branchpoints');
    E = bwmorph(skeletonized, 'endpoints');
    [y,x] = find(E);
    E_loc = find(E);
    Dmask = false(size(skeletonized));
    max_len = 0;
    
    for k = 1:numel(x)
        D = bwdistgeodesic(skeletonized,x(k),y(k));
        curr_len = max(D(E_loc));
        if max_len < curr_len
            max_len = curr_len;
        end
        
        if k == 1
            distance_maps = D;
        else
            distance_maps = cat(3, distance_maps, D);
        end

    end
    [~,~,z]= ind2sub(size(distance_maps), find(distance_maps==max_len));
    %% A bug here need to fix. there are two equal values here at the tips.
    % filter branch with same distance
    len_of_longest = 0;
    for k = 1:numel(x)
        for kk = k+1 : numel(x)
            sum_of_two = distance_maps(:,:,k) + distance_maps(:,:,kk);
            len_of_path = numel(find(sum_of_two == max_len));
            if len_of_path > len_of_longest
                longest_path = sum_of_two;
                len_of_longest = len_of_path;
            end
        end
    end
            
    
%     ep = unique(z);
% 
%     for pp = 1:numel(ep)
%         if pp == 1
%             n_match_points = numel(find(z==ep(pp)));
%         else
%             cur_mp = numel(find(z==ep(pp)));
%             n_match_points = [n_match_points, cur_mp];           
%         end
%     end
%     [~, ind_p]= sort(n_match_points);
%     ep_1 = ep(ind_p(end));
%     ep_2 = ep(ind_p(end - 1));
% 
% 
%     longest_path = distance_maps(:,:,ep_1)+ distance_maps(:,:,ep_2);

    Dmask(longest_path == max_len) = true;
    skeletonized = Dmask;      
        %%
        
    end_point = bwmorph(skeletonized, 'endpoints');
    [y,x] = find(end_point);
    dist = bwdistgeodesic(logical(skeletonized),x(1),y(1));
    dist = dist(:)';
    [sorted, ind_sorted] = sort(dist);
    sorted = sorted(1:max(sorted(~isinf(sorted))));
    ind_sorted = ind_sorted(1:max(sorted(~isinf(sorted))));


    [local_y_,local_x_] = ind2sub(size(skeletonized),ind_sorted); 

%     org_local_y = org_local_y - min(local_y_);
%     org_local_x = org_local_x - min(local_x_);
%     org_local_y_skel = ske_y - min(local_y_);
%     org_local_x_skel = ske_x - min(local_x_);
% 
%     local_y = local_y_ - min(local_y_);
%     local_x = local_x_ - min(local_x_);
% 
    local_y = local_y_ ;
    local_x = local_x_ ;
    
        %%
    t = 1 : numel(local_x);

    p_x = polyfit(t, local_x, 3);
    p_y = polyfit(t, local_y, 3);

    p_x_pre = polyval(p_x, t);
    p_y_pre = polyval(p_y, t);


        
        %% data points for clustering
%         data_points_cell{floor(n/2)+1} = transpose([p_x_pre;p_y_pre]);
        
        %% curvature

    pd_x = polyder(p_x);
    pd_y = polyder(p_y);
    pdd_x = polyder(pd_x);
    pdd_y = polyder(pd_y);

    tt = 1:0.2:numel(local_x);
    p_x_val = polyval(p_x, tt);
    p_y_val = polyval(p_y, tt);
    pd_x_val = polyval(pd_x, tt);
    pd_y_val = polyval(pd_y, tt);
    pdd_x_val = polyval(pdd_x, tt);
    pdd_y_val = polyval(pdd_y, tt);

    curvature = (pd_x_val.* pdd_y_val - pd_y_val .* pdd_x_val) ./ (pd_x_val .^ 2 + pd_y_val .^ 2) .^ (3/2);

        width = uint8(max(p_y_val)-min(p_y_val)+ 1);
        height =  uint8(max(p_x_val) - min(p_x_val) + 1);
        
        new_canvas = zeros(height,width); 
        new_ind = sub2ind(size(new_canvas), int64(p_x_val - min(p_x_val) + 1), int64(p_y_val - min(p_y_val) + 1));
        
        center_val_x = (max(p_x_val) - double((max(p_x_val) - min(p_x_val))/2));
        center_val_y = (max(p_y_val) - double((max(p_y_val) - min(p_y_val))/2));
        shift_y = center_coor_y - center_val_y;
        shift_x = center_coor_x - center_val_x;
        ind_reconstruction = sub2ind(size(canvas_reconstruction),int64(p_y_val + shift_y ),  int64(p_x_val + shift_x ));
        ind_reconstruction_org_mask = sub2ind(size(canvas_reconstruction),int64(local_y_unshifted + 1),  int64(local_x_unshifted + 1));
        
        norm_curvature = curvature - min(curvature(:))+0.5;
        norm_curvature = norm_curvature ./ max(norm_curvature(:));
        new_canvas(new_ind) = norm_curvature;
        
%         canvas_reconstruction(ind_reconstruction) = norm_curvature;
        canvas_reconstruction(ind_reconstruction) = norm_curvature;
        
%         new_canvas = uint8(floor(new_canvas * 255));
%         rgbImage = ind2rgb(new_canvas, jet(256));
%         figure(2);
%         imshow(rgbImage)
        
        %%
%         figure1 = figure(1);
%                 
% 
%         plot(org_local_y, org_local_x,'.','color', 'b');
%         hold on;
% 
% 
% %         plot(org_local_y_skel, org_local_x_skel,'.','color', 'c');
% %         hold on;
% %         
%         plot(local_y, local_x,'.','color', 'r');
%         hold on;
%         plot(p_y_pre, p_x_pre,'.', 'color','g')
%         hold on;
%         axis([-30 50 -30 50])
%         grid on;
% 
%         hold off;
%         
        mkdir './curve_fitting/matlab_curve_fitting_ft)/'
        saveas(figure1,strcat('./curve_fitting/matlab_curve_fitting_ft/',num2str(n) ,'.png'))
        tt = logical(canvas_reconstruction>0);
        testing(ind_reconstruction_org_mask) = 100;
        testing (tt) = 156;
        rgbImage = ind2rgb(testing, jet(256));
%         figure(3)
%         imshow(rgbImage)


end
    figure1 = figure(3);
    
    saveas(figure1,strcat('./curve_fitting/matlab_curve_fitting_ft/','_000' ,'.png'))
    
    new_canvas = int64(floor(new_canvas * 255));
    rgbImage = ind2rgb(new_canvas, jet(256));
    figure(2);
    imshow(rgbImage)

%% convert to skeleton
for n = 1:2:numel(data_points)
        disp(n);
        
        local_x = double(data_points{1,n});
        local_y = double(data_points{1,n+1});        
        

 % shift to the center for visualization.
        width = max(local_x) - min(local_x);
        height = max(local_y) - min(local_y);
        
        local_y = local_y - (max(local_y) - double((max(local_y) - min(local_y))/2));
        local_x = local_x - (max(local_x) - double((max(local_x) - min(local_x))/2));
   
 % reconstruct the original segment.
        width = width + 20;
        height = height + 20;
        
        canvas = zeros(width,height); 
            
        ind = sub2ind(size(canvas), uint8(width/2 + local_x), uint8(height/2 + local_y));
 
        canvas(ind) = 1;
        [org_local_x, org_local_y] = ind2sub(size(canvas), ind);

        %% Skeletonize
        skeletonized = bwmorph(canvas,'skel',Inf);
        [ske_x, ske_y] = ind2sub(size(canvas), find(skeletonized));
        if n == 53
           bbbb = 1;
        end
        
        %% prune v1
        B = bwmorph(skeletonized, 'branchpoints');
        E = bwmorph(skeletonized, 'endpoints');
        [y,x] = find(E);
        B_loc = find(B);
        len_B_loc = size(B_loc);
        if len_B_loc ~= 0
            Dmask = false(size(skeletonized));
            for k = 1:numel(x)
                D = bwdistgeodesic(skeletonized,x(k),y(k));
                distanceToBranchPt = min(min(D(B_loc)), 5);
                Dmask(D < distanceToBranchPt) =true;
            end
            skeletonized = skeletonized - Dmask;
        end
%         
        %% prune v2
        skeletonized = logical(skeletonized);
        B = bwmorph(skeletonized, 'branchpoints');
        E = bwmorph(skeletonized, 'endpoints');
        [y,x] = find(E);
        E_loc = find(E);
        Dmask = false(size(skeletonized));
        max_len = 0;
        for k = 1:numel(x)
            D = bwdistgeodesic(skeletonized,x(k),y(k));
            curr_len = max(D(E_loc));
            if max_len < curr_len
                max_len = curr_len;
            end
            if k == 1
                distance_maps = D;
            else
                distance_maps = cat(3, distance_maps, D);
            end

        end
        [~,~,z]= ind2sub(size(distance_maps), find(distance_maps==max_len));
        
        % filter branch with same distance
        ep = unique(z);

        for pp = 1:numel(ep)
            if pp == 1
                n_match_points = numel(find(z==ep(pp)));
            else
                cur_mp = numel(find(z==ep(pp)));
                n_match_points = [n_match_points, cur_mp];           
            end
        end
        [~, ind_p ]= sort(n_match_points);
        ep_1 = ep(ind_p(end));
        ep_2 = ep(ind_p(end - 1));
        
        longest_path = distance_maps(:,:,ep_1)+ distance_maps(:,:,ep_2);
        
        Dmask(longest_path == max_len) = true;
        skeletonized = Dmask;      
        %%
        
        end_point = bwmorph(skeletonized, 'endpoints');
        [y,x] = find(end_point);
        dist = bwdistgeodesic(logical(skeletonized),x(1),y(1));
        dist = dist(:)';
        [sorted, ind_sorted] = sort(dist);
        sorted = sorted(1:max(sorted(~isinf(sorted))));
        ind_sorted = ind_sorted(1:max(sorted(~isinf(sorted))));

        
        [local_x_,local_y_] = ind2sub(size(skeletonized),ind_sorted); 
        
        org_local_y = org_local_y - min(local_y_);
        org_local_x = org_local_x - min(local_x_);
        org_local_y_skel = ske_y - min(local_y_);
        org_local_x_skel = ske_x - min(local_x_);

        local_y = local_y_ - min(local_y_);
        local_x = local_x_ - min(local_x_);
        

        %%
        t = 1 : numel(local_x);
        
        p_x = polyfit(t, local_x, 3);
        p_y = polyfit(t, local_y, 3);
        
        p_x_pre = polyval(p_x, t);
        p_y_pre = polyval(p_y, t);
        
        
        
        %% data points for clustering
        data_points_cell{floor(n/2)+1} = transpose([p_x_pre;p_y_pre]);
        
        %% curvature

        pd_x = polyder(p_x);
        pd_y = polyder(p_y);
        pdd_x = polyder(pd_x);
        pdd_y = polyder(pd_y);
        
        tt = 1:0.2:numel(local_x);
        p_x_val = polyval(p_x, tt);
        p_y_val = polyval(p_y, tt);
        pd_x_val = polyval(pd_x, tt);
        pd_y_val = polyval(pd_y, tt);
        pdd_x_val = polyval(pdd_x, tt);
        pdd_y_val = polyval(pdd_y, tt);
        
        curvature = (pd_x_val.* pdd_y_val - pd_y_val .* pdd_x_val) ./ (pd_x_val .^ 2 + pd_y_val .^ 2) .^ (3/2);
        
        width = uint8(max(p_y_val)-min(p_y_val)+ 1);
        height =  uint8(max(p_x_val) - min(p_x_val) + 1);
        
        new_canvas = zeros(height,width); 
        new_ind = sub2ind(size(new_canvas), uint8(p_x_val - min(p_x_val) + 1), uint8(p_y_val - min(p_y_val) + 1));
        norm_curvature = curvature - min(curvature(:))+0.5;
        norm_curvature = norm_curvature ./ max(norm_curvature(:));
        new_canvas(new_ind) = norm_curvature;
        new_canvas = uint8(floor(new_canvas * 255));
        rgbImage = ind2rgb(new_canvas, jet(256));
        figure(2);
        imshow(rgbImage)
        
        %%
        figure1 = figure(1);
                

        plot(org_local_y, org_local_x,'.','color', 'b');
        hold on;


        plot(org_local_y_skel, org_local_x_skel,'.','color', 'c');
        hold on;
        
        plot(local_y, local_x,'.','color', 'r');
        hold on;
        plot(p_y_pre, p_x_pre,'.', 'color','g')
        hold on;
        axis([-30 50 -30 50])
        grid on;

        hold off;
%         
        mkdir './curve_fitting/matlab_curve_fitting_ft)/'
        saveas(figure1,strcat('./curve_fitting/matlab_curve_fitting_ft/',num2str(n) ,'.png'))
%         shift to the center for visualization.

end
length = size(data_points_cell);
data_points_cell = reshape(data_points_cell,[length(2),1]);

%% 

for i = 1:2:numel(data_points)
    data_points_cell{floor(i/2)+1} = transpose([double(data_points{1,i}); double(data_points{1,i+1})]);
    shape = size(data_points{1,i});
  
    
end
length = size(data_points_cell);
data_points_cell = reshape(data_points_cell,[length(2),1]);

model = curve_clust(data_points_cell,ops);


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
        

        % Obtain orientation of the segment.
        % Fit y = F(x) or x = F(y) according to the orientation angle
        
        region_properties = regionprops(canvas,'orientation');
        orientation = region_properties.Orientation;

        % rotate if orienation is within certain range of angle.
        if orientation > 45 && orientation < 135
            % x = F(y)
            variable = local_x;
            target = local_y;
            rotate_flag = true;
        else
            % y = F(x)
            variable = local_y;
            target = local_x;

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
        plot(variable, target,'.');
        
        grid on;
        xlabel('X', 'FontSize', fontSize);
        ylabel('Y', 'FontSize', fontSize);
        
        % Overlay the original points in red.
        hold on;
        plot(min(variable):max(variable), fitted_target, 'LineWidth', 2, 'MarkerSize', 10);
        axis([-25 25 -25 25])
        hold off;
        
        saveas(figure1,strcat('./curve_fitting/matlab_curve_fitting_ft/',num2str(n) ,'.png'))
end