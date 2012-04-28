% read in template image
rainbow = rgb2gray(imread('template_rainbow.jpg'));
%imshow(rainbow);

% close all ports
delete(instrfind);

% creates serials port
% ex: serial('COM1');
s = serial('COM8', 'BaudRate', 9600);
% opens for writing
debug = 0;
try
    fopen(s);
catch
    debug = 1;
end

% prepare the sirens
[siren, siren_Fs] = wavread('siren.wav');


% imshow(circle);
% figure
% extract features of template
% [frames_circle, descs_circle] = sift(circle);

search_last = rainbow;
i=0;

%for i=1:1
while(1)   
    % read camera image
    image_rgb = imread('http://192.168.10.6/axis-cgi/jpg/image.cgi?resolution=640x480','jpg');
    %imshow(image_rgb);
    %figure
    image_red = image_rgb(:,:,1);
    %imshow(image_red);
    %figure
    
    panic_image = image_red(5:19,563:576);
    [panic_rows, panic_cols] = size(panic_image);
    panic_sum = sum(sum(panic_image));
    panic_avg = panic_sum/(panic_rows*panic_cols);
    if(panic_avg <200)
        panic_alarm = 1;
    else
        panic_alarm = 0;
    end
    
    if(panic_alarm == 1)
        sound(siren, siren_Fs);
    end
    
    image = rgb2gray(image_rgb);
    % slice it
    % rainbow:
    % search = image(64:(64+137),486:(486+61));
    % imshow(image);
    % figure
    
    search = image(287:450,274:552);
    
    mask_r = [39 10 107 145];
    mask_c = [29 145 242 101];
    mask = roipoly(search, mask_c, mask_r);
    % imshow(mask);
    
    search_masked = uint8(mask).*search;
    % search = image;
    % imshow(search_masked);
    % figure
    
    search_rotated = imrotate(search_masked,-atand(36/140));
    
    a = -0.45;
    T = maketform('affine', [1 0 0; a 1 0; 0 0 1] );

    R = makeresampler({'cubic','nearest'},'fill');
    search_sheared = imtransform(search_rotated,T,R,'FillValues',0);
    search_final = imrotate(search_sheared, 90);
    %imshow(search_final);

    lights_r = [173 168 273 272];
    lights_c = [48 93 86 49];
    lights_mask = roipoly(search_final, lights_c, lights_r);
    lights_masked = uint8(lights_mask).*search_final;
    lights_thresh = lights_masked>150;

    lights_sum = sum(sum(lights_masked));
    
    play_r = [172 171 186 187];
    play_c = [108 119 119 107];
    play_mask = roipoly(search_final, play_c, play_r);
    play_masked = uint8(play_mask).*search_final;

    play_sum = sum(sum(play_masked));
    
    track_r = [223 224 243 243];
    track_c = [104 114 115 103];
    track_mask = roipoly(search_final, track_c, track_r);
    track_masked = uint8(track_mask).*search_final;

    track_sum = sum(sum(track_masked));
    
    vol_r = [211 213 281 280];
    vol_c = [131 137 135 129];
    vol_mask = roipoly(search_final, vol_c, vol_r);
    vol_masked = uint8(vol_mask).*search_final;
    vol_thresh = vol_masked>170;
    %figure
    %imshow(vol_thresh);
    vol_slice = vol_thresh(216:277,132:134);
    [vol_rows, vol_cols] = size(vol_slice);
    level = 0;
    levelSet = 0;
    for j=1:vol_rows
        for k=1:vol_cols
            if (vol_slice(j,k) == 0 && levelSet == 0)
                level = j;
                levelSet = 1;
            end
        end
    end
    if(levelSet == 0)
        level = vol_rows;
    end
    vol_pct = double((double(vol_rows)-double(level))/double(vol_rows));
    vol_sum = sum(sum(vol_masked));
    
    if (lights_sum<800000)
        lights_str = 'on';
        light_send = '1';
    else
        lights_str = 'off';
        light_send = '0';
    end
    
    if (play_sum<34000)
        play_str = 'play';
    else
        play_str = 'pause';
    end
    
    if (track_sum<35000)
        track_str = 'skip';
    else
        track_str = 'no skip';
    end
    i = i+1;
    [int2str(i) '- lights: ' lights_str ' (' int2str(lights_sum) '), music: ' play_str ' (' int2str(play_sum) '), track: ' track_str ' (' int2str(track_sum) '), vol: ' num2str(vol_pct)]

    
    
    if(debug == 0)
        fwrite(s,light_send,'uchar')
    end
    
end



% close the serial port
fclose(s)
