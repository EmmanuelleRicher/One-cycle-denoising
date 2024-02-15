% This function applies the tilts found by maximum correlation on a image 
% to be registered. 
% 
% Input arguments :
%   moving : image to be registered
%   shifts : computed tilts to apply to every a scan
% 
% Return :
%   newMoving : registered image
function newMoving = tiltImage(moving, shifts)

% if images were converted to double (averaged images), we need to convert
% them back to int (0-255)
if max(moving, [], 'all') <=1
    moving = moving*255;
end

largeur = size(moving, 2);

% pad every a scan according to axial displacement to create new
% image
newMoving = zeros(size(moving));
for i=1:largeur
    
    % extract old column
    oldColumn = moving(:, i);
    
    % shift it according to the shift found for that column
    switch shifts(i) < 0
        
        case true
             pad = abs(ceil(shifts(i)));
             newColumn = padarray(oldColumn, pad, 'pre');
             newColumn(end-pad+1:end) = [];
        case false
             pad = abs(ceil(shifts(i)));
             newColumn = padarray(oldColumn, pad, 'post');
             newColumn(1:pad) = [];
    end
    
    % add it into new array
    newMoving(:, i) = newColumn;
end

newMoving = uint8(newMoving);

end