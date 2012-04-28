% Hack-the-PopShop: Whiteboard-Controlled Workspace Management
% -- Cornell Hackathon 2012 --
% -- MATLAB Image Processing Code --

% set lo-res mode: imprecise but faster
lores = 1;

% close all ports
delete(instrfind);

% create & open serial port
arduino_port = 'COM8';
s = serial(arduino_port, 'BaudRate', 9600);

% debug variables are used so that the system can process images without
% server or arduino connection
server_debug = 0;
arduino_debug = 0;

% test arduino connection
try
    fopen(s);
catch
    fprintf('arduino failed to connect\n');
    arduino_debug = 1;
end

% prepare the sirens
[siren, siren_Fs] = wavread('siren.wav');

% config the music server
t = tcpip('192.168.10.13', 10000);

% test server connection
try
    fopen(t);
    fclose(t);
catch
    fprintf('server failed to connect\n');
    server_debug = 1;
end

% used for averaging light box values
light_old_1 = 0;
light_old_2 = 0;
light_old_3 = 0;

% last command sent to lights
light_send_old = '0';

% configure Axis cam image capture
image_url = 'http://192.168.10.6/axis-cgi/jpg/image.cgi?resolution=';
if (lores == 1)
    image_url = [image_url '320x240'];
else
    image_url = [image_url '640x480'];
end

% used for "skip track" button
track_next_flag = 0;

% defining regions of interest
if (lores == 0)
    mask_r = [39 10 107 145];
    mask_c = [29 145 242 101];
    
    lights_r = [173 168 273 272];
    lights_c = [48 93 86 49];
    lights_thresh_val = 800000;
    
    play_r = [172 171 186 187];
    play_c = [108 119 119 107];
    play_thresh_val = 31000;
    
    track_r = [223 224 243 243];
    track_c = [104 114 115 103];
    track_thresh_val = 30000;
    
    vol_r = [211 213 281 280];
    vol_c = [131 137 135 129];
else
    mask_r = [round(39/2) round(10/2) round(107/2) round(145/2)];
    mask_c = [round(29/2) round(145/2) round(242/2) round(101/2)];

    lights_r = [round(173/2) round(168/2) round(273/2) round(272/2)];
    lights_c = [round(48/2) round(93/2) round(86/2) round(49/2)];
    lights_thresh_val = 160000;

    play_r = [round(172/2) round(171/2) round(186/2) round(187/2)];
    play_c = [round(108/2) round(119/2) round(119/2) round(107/2)];
    play_thresh_val = 5000;

    track_r = [round(223/2) round(224/2) round(243/2) round(243/2)];
    track_c = [round(104/2) round(114/2) round(115/2) round(103/2)];
    track_thresh_val = round(30000/4);

    vol_r = [round(211/2) round(213/2) round(281/2) round(280/2)];
    vol_c = [round(131/2) round(137/2) round(135/2) round(129/2)];
end

i=0;

% comment out one of these lines to choose continuous or debug mode

% for i=1:1
while(1)   
    % read camera image
    image_rgb = imread(image_url,'jpg'); % note, to read .cgi as image (e.g., from Axis cam), you must specify a format

    % red filtering for Panic button
    image_red = image_rgb(:,:,1);
    
    % Panic button segment
    if (lores == 0)
        panic_image = image_red(5:19,563:576);
    else
        panic_image = image_red(2:10,281:288);
    end
    
    % Panic button thresholding
    % Calculates how "red" the region is and compares it to a threshold
    % Threshold depends on current lighting
    [panic_rows, panic_cols] = size(panic_image);
    panic_sum = sum(sum(panic_image));
    panic_avg = panic_sum/(panic_rows*panic_cols);
    if(strcmp(lights_str, 'on') == 1)
        panic_thresh = 200;
    else
        panic_thresh = 140;
    end
    if(panic_avg < panic_thresh)
        panic_alarm = 1;
    else
        panic_alarm = 0;
    end
    
    % Trigger sirens if panic alarm goes off
    % if(panic_alarm == 1)
    %   sound(siren, siren_Fs);
    % end
    
    % Convert to grayscale for speed
    image = rgb2gray(image_rgb);
    
    % Whiteboard region of interest
    if (lores == 0)
        search = image(287:450,274:552);
    else
        search = image(round(287/2):round(450/2),round(274/2):round(552/2));
    end
    
    % Defines the exact polygon of the whiteboard space, and creates a mask
    mask = roipoly(search, mask_c, mask_r);

    % Filters camera image using that mask
    search_masked = uint8(mask).*search;
    
    % Correct for alignment of whiteboard/camera:
    % 1. Rotate
    search_rotated = imrotate(search_masked,-atand(36/140));
    
    % 2. Shear
    a = -0.45;
    T = maketform('affine', [1 0 0; a 1 0; 0 0 1] );
    R = makeresampler({'cubic','nearest'},'fill');
    search_sheared = imtransform(search_rotated,T,R,'FillValues',0);
    search_final = imrotate(search_sheared, 90);

    % Region of interest: light box
    lights_mask = roipoly(search_final, lights_c, lights_r);
    lights_masked = uint8(lights_mask).*search_final;
    lights_thresh = lights_masked>150;

    lights_sum = sum(sum(lights_masked));
    
    % Region of interest: play button
    play_mask = roipoly(search_final, play_c, play_r);
    play_masked = uint8(play_mask).*search_final;

    play_sum = sum(sum(play_masked));
    
    % Region of interest: track skip button
    track_mask = roipoly(search_final, track_c, track_r);
    track_masked = uint8(track_mask).*search_final;

    track_sum = sum(sum(track_masked));
    
    % Region of interest: volume slider
    vol_mask = roipoly(search_final, vol_c, vol_r);
    vol_masked = uint8(vol_mask).*search_final;
    vol_thresh = vol_masked>120;
    if (lores == 0)
        vol_slice = vol_thresh(216:277,132:133);
    else
        vol_slice = vol_thresh(110:138,66:67);
    end
    [vol_rows, vol_cols] = size(vol_slice);
    level = 0;
    levelSet = 0;
    
    % Starts at the top of the volume slider and searches down for the
    % first black pixel
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
    
    % Convert to a percentage
    vol_pct = double((double(vol_rows)-double(level))/double(vol_rows));
    vol_sum = sum(sum(vol_masked));
    
    % Time-average the light box values
    lights_combined = (lights_sum+light_old_1)/2;
    light_old_3 = light_old_2;
    light_old_2 = light_old_1;
    light_old_1 = lights_sum;
    
    % Choose light command
    if (lights_combined<lights_thresh_val)
        lights_str = 'on';
        light_send = '1';
    else
        lights_str = 'off';
        light_send = '0';
    end
    
    % Delay if the light state changed. With low-res cameras like the Axis,
    % turning on/off the lights creates temporary flicker that sometimes 
    % oscillates the lights, this corrects for that.
    if(strcmp(light_send, light_send_old) ~= 1)
        pause(1);
    end
    
    % Choose play/pause command
    if (play_sum<play_thresh_val)
        play_str = 'PLAY';
    else
        play_str = 'PAUSE';
    end
    
    % Choose track skip command
    % Has three states, "stay" -- don't do anything, "NEXT" -- tells iTunes
    % to advance to the next track, "wait" -- wait until the block has been
    % removed until sending another NEXT command
    if (track_sum<track_thresh_val)
        if(track_next_flag == 0)
            track_str = 'NEXT';
            track_next_flag = 1;
        else
            track_str = 'wait';
        end
    else
        track_str = 'stay';
        track_next_flag = 0;
    end
    
    % Command window output
    i = i+1;
    output_string = [int2str(i) '-lts:' lights_str '(' int2str(lights_sum) ') msc:' play_str '(' int2str(play_sum) '), trk:' track_str '(' int2str(track_sum) '), vol:' num2str(vol_pct) ', pnc:' int2str(panic_alarm) '(' int2str(panic_sum) ')'];
    fprintf([output_string '\n']);

    % Send commands to the server
    % We found it was necessary to open a connection for each command
    if(server_debug == 0)
        fopen(t);
        fprintf(t, sprintf('%d', round(vol_pct*100)));
        fclose(t);
        fopen(t);
        fprintf(t, sprintf('%s', play_str));
        fclose(t);
        if (strcmp(track_str,'NEXT') == 1)
            fopen(t);
            fprintf(t, sprintf('%s', track_str));
            fclose(t);   
        end
        if (panic_alarm == 1)
            fopen(t);
            fprintf(t, sprintf('%s', 'PANIC'));
            fclose(t);   
        end
        % Potentially pause if server is overloaded
        % pause(0.5);
    end
    
    if(arduino_debug == 0)
        % Flicker the lights, disabled because this got annoying
        % if (panic_alarm == 1)
        %     for q=1:2
        %         fwrite(s,'1','uchar');
        %         pause(0.5);
        %         fwrite(s,'0','uchar');
        %         pause(0.5);
        %     end
        % end
        fwrite(s,light_send,'uchar');
    end
    
    light_send_old = light_send;
    
end

% close the serial port
fclose(s);

% close the TCP/IP port
fclose(t);
