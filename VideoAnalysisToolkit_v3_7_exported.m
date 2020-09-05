classdef VideoAnalysisToolkit_v3_7_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        VideoAnalysisToolkit          matlab.ui.Figure
        GetintrinsicsButton           matlab.ui.control.Button
        Function1GetcameraintrinsicsLabel  matlab.ui.control.Label
        Function2ElimatevideodistortionLabel  matlab.ui.control.Label
        Function4GetcarspeedLabel     matlab.ui.control.Label
        CalibratevideoButton          matlab.ui.control.Button
        GetextrinsicsButton           matlab.ui.control.Button
        Function3GetcameraextrinsicsLabel  matlab.ui.control.Label
        WorkflowLabel                 matlab.ui.control.Label
        SpeedCalculationModus         matlab.ui.control.Switch
        GetcarspeedButton             matlab.ui.control.Button
        VideoAmount1                  matlab.ui.control.Switch
        ExportvideoframeLabel         matlab.ui.control.Label
        ExportButton                  matlab.ui.control.Button
        VideoAmount2                  matlab.ui.control.Switch
        CompareButton                 matlab.ui.control.Button
        ComparedifferentframeLabel    matlab.ui.control.Label
        Schachbrettmuster             matlab.ui.control.Button
        CalculateButton               matlab.ui.control.Button
        CalculatefieldofviewLabel     matlab.ui.control.Label
        MustHaveLabel                 matlab.ui.control.Label
        AdditionalLabel               matlab.ui.control.Label
        MethodDropDownLabel           matlab.ui.control.Label
        MethodDropDown                matlab.ui.control.DropDown
        Version37Updatedate15Aug2020Label  matlab.ui.control.Label
        CalculateheightButton         matlab.ui.control.Button
        CalculatecameraheightLabel    matlab.ui.control.Label
        ExtrinsicsCalculationModus    matlab.ui.control.Switch
        checkerboardprintedCheckBox   matlab.ui.control.CheckBox
        checkerboardcapturedCheckBox  matlab.ui.control.CheckBox
        cameraintrinsicscomputedCheckBox  matlab.ui.control.CheckBox
        cameraextrinsicscomputedCheckBox  matlab.ui.control.CheckBox
        videocorrectedCheckBox        matlab.ui.control.CheckBox
        vehicletrajectoryexportedCheckBox  matlab.ui.control.CheckBox
        videoinDataFromSkyuploadedCheckBox  matlab.ui.control.CheckBox
        speedcomputedCheckBox         matlab.ui.control.CheckBox
        Button                        matlab.ui.control.Button
        UITable                       matlab.ui.control.Table
        PreCheckLabel                 matlab.ui.control.Label
        Function5GetTTCandPETLabel    matlab.ui.control.Label
        GetTTCandPETButton            matlab.ui.control.Button
        ComputerVisionToolboxinstalledCheckBox  matlab.ui.control.CheckBox
    end



    methods (Access = private)

        % Button pushed function: GetintrinsicsButton
        function GetintrinsicsButtonPushed(app, event)
        % Define images to process
        uiwait(msgbox('Step 1: Load 10 and 20 checkerboard images.','Intrinsics','modal'));
        % Load images
        [imagefile,imagepath] = uigetfile({'*.jpg';'*.png';'*.gif';'*.bmp'},'MultiSelect','on','Please select images');
        imageFileNames = fullfile(imagepath, imagefile);        
        % Generate a dialog box to collect the length of the checkerboard
        uiwait(msgbox('Step 2: Enter square size of the checkerboard.','Intrinsics','modal'));
        prompt = {'Enter square size (in millimeters):'};
        dlgtitle = 'Set parameters';
        dims = [1 55];
        definput = {'59.7'};  % default size
        answer = inputdlg(prompt,dlgtitle,dims,definput);
        squareSize = str2num(answer{1});        
        f1 = uifigure;
        d1 = uiprogressdlg(f1,'Title','Please Wait','Message','detecting checkerboard points...','Cancelable','on','ShowPercentage','on');
        d1.Value = 0.2;                
        % Detect checkerboards in images and filter out images which are not suitable
        [imagePoints, boardSize, imagesUsed] = detectCheckerboardPoints(imageFileNames);
        imageFileNames = imageFileNames(imagesUsed);     
        d1 = uiprogressdlg(f1,'Title','Please Wait','Message','calibration finished...','Cancelable','on','ShowPercentage','on');
        d1.Value = 0.7;
        % Read the first image to obtain image size
        originalImage = imread(imageFileNames{1});
        [mrows, ncols, ~] = size(originalImage);
        % Generate world coordinates of the corners of the squares
        worldPoints = generateCheckerboardPoints(boardSize, squareSize);
        % Calibrate the camera.
        % Default calibration options: consider radial distortion, tangential distortion and skew.    
        [CAM, ~, ~] = estimateCameraParameters(imagePoints, worldPoints, 'EstimateSkew', true, 'EstimateTangentialDistortion', true, ...
                      'NumRadialDistortionCoefficients', 3, 'WorldUnits', 'millimeters', 'InitialIntrinsicMatrix', [], 'InitialRadialDistortion', ...
                      [], 'ImageSize', [mrows, ncols]);
        figure('Name','Calibration Results','Position',[20,70,1200,650]);
        close(f1);
        close(d1);
        subplot(2,2,1); showExtrinsics(CAM, 'CameraCentric');
        subplot(2,2,2); showReprojectionErrors(CAM);     
        subplot(2,2,[3,4]); imshowpair(originalImage,undistortImage(originalImage, CAM),'montage'); title('First Image (left: original, right: undistorted)');
        if CAM.MeanReprojectionError <= 1
            uiwait(msgbox('According to the error value, the calibration quality is good.','Success','modal')); 
            uiwait(msgbox('Please also compare the corrected image with the original to see the effect.'));
        else
            uiwait(msgbox('The mean reprojection error shows the calibration is not good. Please remove the image with high error, adjust the photos and try again.','Failure','modal'));
        end
        uisave({'CAM'},'CameraIntrinsics_GoPro_1080p_M_1.mat');
        % Export all the parameters to a .mat-fileuisave({'CAM'},'CameraIntrinsics_GoPro_1080p_M_1.mat'); 
        msgbox('Saved. Click OK to exit.');
        end

        % Button pushed function: GetextrinsicsButton
        function GetextrinsicsButtonPushed(app, event)
        switch app.MethodDropDown.Value
            case '4 points'
                %% Input phase
                % Input camera intrinsics
                uiwait(msgbox('Step 1: Please load camera intrinsics to workspace.','4 points','modal'));
                [filename_intrinsics,filepath_intrinsics] = uigetfile('.mat','Please select MAT file calculated by "Get intrinsics".');
                camera_intrinsics = fullfile(filepath_intrinsics, filename_intrinsics);
                load(camera_intrinsics);
                
                % Input the video frame
                uiwait(msgbox('Step 2: Load one frame of the video. (See additional - export video frame)','Load frame','modal'));
                [filename_image,filepath_image] = uigetfile({'*.jpg';'*.png';'*.gif';'*.bmp'},'Please select a frame, which comes from the video to be calibrated.');                               
                calibration_image = fullfile(filepath_image, filename_image);
                image_check = questdlg('Has the image distortion already been removed?','Option','Yes, removed','Not yet','Yes, removed');
                switch image_check
                    case 'Yes, removed'
                        check_result = 1;
                    case 'Not yet'
                        check_result = 2;
                    case ''
                        Msgbox('you cancelled.');
                end
                
                % Select Mode
                Mode = {'Using on-site measured coordinates (in meter)','Using GNSS coordinates'};
                [mode_index,mode_check] = listdlg('ListString',Mode,'SelectionMode','single','InitialValue',1,'PromptString','Select the intersection:');
                
                %% Define calibration points
                if mode_check ~= 1 % effective selection
                    msgbox('You exitted.','Attention');
                else
                    switch mode_index
                        case 1  % using in-field measurement
                            uiwait(msgbox('In this mode, you will not get the GNSS coordinates in the end.','on-site mode','modal'));
                            figure('Name','Calibration','NumberTitle','off','position',[0,0,1520,1080]);
                            imshow(calibration_image,'InitialMagnification','fit');            
                            ImagePoints = zeros(4,2);
                            WorldPoints = zeros(4,2);
                            
                            title(strcat('Please select the coordinate origin in the image.'));
                            ImagePoints(1,:) = ginput(1);           
                            WorldPoints(1,:) = [0,0];
                            Message      = strcat('Coordinate origin (0,0)');
                            text(ImagePoints(1,1),ImagePoints(1,2),Message,'FontSize',13);
                            
                            for i = 2:4
                                title(strcat('Please select the',32,num2str(i),'. point in the image.'));
                                ImagePoints(i,:) = ginput(1);
                                prompt2      = strcat('point',32,num2str(i));
                                dlgtitle2    = 'Please give on-site measured coordinate in meter.';
                                definput2    = {'x, y in meter (e.g. 2,3)'};
                                dims2        = [1 50];
                                answer2      = inputdlg(prompt2,dlgtitle2,dims2,definput2);     
                                WorldPoints(i,:)     = str2num(answer2{1});
                                Message      = strcat('point',32,num2str(i),32,'(',answer2{1},')');
                                text(ImagePoints(i,1),ImagePoints(i,2),Message,'FontSize',13);
                            end
                            
                            for i = 5:100
                                answer3 = questdlg('You have reached minimum number of points for calibration. Would you like to add more points?','Configuration','Yes','No','Yes');
                                % Handle response
                                switch answer3
                                    case 'Yes'
                                        title(strcat('Please select the',32,num2str(i),'. point in the image.'));
                                        ImagePoints(i,:) = ginput(1);
                                        prompt2      = strcat('point',32,num2str(i));
                                        answer2      = inputdlg(prompt2,dlgtitle2,dims2,definput2);
                                        WorldPoints(i,:)     = str2num(answer2{1});
                                        Message      = strcat('point',32,num2str(i),32,'(',answer2{1},')');
                                        text(ImagePoints(i,1),ImagePoints(i,2),Message,'FontSize',13);
                                    case 'No'
                                        break;
                                    case ''
                                        break;
                                end
                            end
                            
                        case 2  % using GNSS coordinates
                            figure('Name','Calibration','NumberTitle','off','position',[0,0,1520,1080]);
                            imshow(calibration_image,'InitialMagnification','fit');            
                            ImagePoints = zeros(4,2);
                            GPS         = zeros(4,2);
                            
                            title(strcat('Please select the coordinate origin in the image.'));
                            ImagePoints(1,:) = ginput(1);            
                            prompt2      = {'Coordinate origin:'};
                            dlgtitle2    = 'Please give GPS coordinate.';
                            dims2        = [1 50];
                            definput2    = {'latitude,longitude (e.g. 51.1234,65.5678)'};
                            answer2      = inputdlg(prompt2,dlgtitle2,dims2,definput2);
                            GPS(1,:)     = str2num(answer2{1});
                            Message      = strcat('Coordinate origin (',answer2{1},')');
                            text(ImagePoints(1,1),ImagePoints(1,2),Message,'FontSize',13);
                            
                            LatA = GPS(1,1);
                            LonA = GPS(1,2);
                            
                            for i = 2:4
                                title(strcat('Please select the',32,num2str(i),'. point in the image.'));
                                ImagePoints(i,:) = ginput(1);
                                prompt2      = strcat('Point',32,num2str(i));
                                answer2      = inputdlg(prompt2,dlgtitle2,dims2,definput2);     
                                GPS(i,:)     = str2num(answer2{1});
                                Message      = strcat('Point',32,num2str(i),32,'(',answer2{1},')');
                                text(ImagePoints(i,1),ImagePoints(i,2),Message,'FontSize',13);
                            end
                            
                            for i = 5:100
                                answer3 = questdlg('You have reached minimum number of points for calibration. Would you like to add more points?','Configuration','Yes','No','Yes');
                                % Handle response
                                switch answer3
                                    case 'Yes'
                                        title(strcat('Please select the',32,num2str(i),'. point in the image.'));
                                        ImagePoints(i,:) = ginput(1);
                                        prompt2      = strcat('Point',32,num2str(i));
                                        answer2      = inputdlg(prompt2,dlgtitle2,dims2,definput2);
                                        GPS(i,:)     = str2num(answer2{1});
                                        Message      = strcat('Point',32,num2str(i),32,'(',answer2{1},')');
                                        text(ImagePoints(i,1),ImagePoints(i,2),Message,'FontSize',13);
                                    case 'No'
                                        break;
                                    case ''
                                        break;
                                end
                            end
                            
                          % calculate world points (see: https://www.cnblogs.com/0201zcr/p/4673924.html)
                            WorldPoints = GPS; % initialize a WorldPoints matrix with the same size of GPS
                            alphaX = sin(GPS(1,1)/57.2958).*sin(GPS(:,1)/57.2958)+ cos(GPS(1,1)/57.2958).*cos(GPS(:,1)/57.2958);
                            alphaY = sin(GPS(1,1)/57.2958)*sin(GPS(1,1)/57.2958)+ cos(GPS(1,1)/57.2958)*cos(GPS(1,1)/57.2958).*cos((GPS(1,2)-GPS(:,2))/57.2958);
                            WorldPoints(:,1) = 6371004*acos(alphaX).*sign(GPS(:,1)-GPS(1,1));
                            WorldPoints(:,2) = 6371004*acos(alphaY).*sign(GPS(:,2)-GPS(1,2));    
                    end
                    
                    %% Compute camera extrinsics
                    close all;
                    if check_result == 2
                        ImagePoints = undistortPoints(ImagePoints,CAM);
                    end
                    
                    [Rotation_Matrix, Translation_Vector] = extrinsics(ImagePoints,1000*WorldPoints,CAM);
                    Translation_Vector = Translation_Vector/1000;                        
                    Unit = 'meter';
                    
                    % Read out important camera parameters
                    r1=      Rotation_Matrix(1);
                    r2=      Rotation_Matrix(2);
                    r3=      Rotation_Matrix(3);
                    r4=      Rotation_Matrix(4);
                    r5=      Rotation_Matrix(5);
                    r6=      Rotation_Matrix(6);
                    r7=      Rotation_Matrix(7);
                    r8=      Rotation_Matrix(8);
                    r9=      Rotation_Matrix(9);
                    Tr1=     Translation_Vector(1);
                    Tr2=     Translation_Vector(2);
                    Tr3=     Translation_Vector(3);   
                    
                    % Export all important parameters to a .mat-file
                    uiwait(msgbox('Computing finished, please choose a location to save it.','Success','modal'));
                    uisave({'CAM','Rotation_Matrix','r1','r2','r3','r4','r5','r6','r7','r8','r9','Unit','Translation_Vector','Tr1','Tr2','Tr3','LatA','LonA'},'Camera_Parameters.mat');
                    msgbox('Saved.');
                    
                end
                                
            case 'T-Calibration'
                uiwait(msgbox('Please follow the instruction (Page 5 - 7), open and use T-Calibration.','T-Calibration','modal'));
                open T_Analyst_Manual.pdf
        end
        end

        % Button pushed function: GetcarspeedButton
        function GetcarspeedButtonPushed(app, event)
            switch app.SpeedCalculationModus.Value 
                case 'Hybrid'
                    %% Imput phase
                    % Camera parameters
                    uiwait(msgbox('Please import camera parameter computed by T-Calibration.','Hybrid modus','modal'));
                    [T_Calibration_filename,T_Calibration_filepath] = uigetfile('.tacal','Please select camera parameter by T-Calibration');
                    T_Calibration_filename = fullfile(T_Calibration_filepath,T_Calibration_filename);
                    [~,values]         = textread(T_Calibration_filename,'%s%n');
                    
                    % File containing pixel coordinates
                    uiwait(msgbox('Please select the DataFromSky trajectory csv file you want to convert.','Select DFS file','modal'));
                    [DFS_filename, DFS_filepath] = uigetfile('*.csv','Please select DataFromSky output csv-file');
                    DataFromSky_csv           = fullfile(DFS_filepath, DFS_filename);
                    [num_table, ~, raw_table] = xlsread(DataFromSky_csv);
                    
                    % Date and time
                    prompt      = {'Enter the video start time (Year).','Month','Day','Hour','Minute'};
                    dlgtitle    = 'Date and time';
                    dims        = [1 45];
                    definput    = {'2019','09','20','16','30'};  % default value
                    DateAndTime = inputdlg(prompt,dlgtitle,dims,definput);
                    Video_Year         = str2num(DateAndTime{1});
                    Video_Month        = str2num(DateAndTime{2});
                    Video_Day          = str2num(DateAndTime{3});
                    Video_StartHour    = str2num(DateAndTime{4});
                    Video_StartMinute  = str2num(DateAndTime{5});
                    Video_Date         = datetime(Video_Year,Video_Month,Video_Day,Video_StartHour,Video_StartMinute,0);
                    
                    % Imput the street length to calculate the traffic density
                    prompt       = {'Enter the distance between two gates on the main street (in meter), in order to calculate the traffic density.'};
                    dlgtitle     = 'Street length';
                    dims         = [1 55];
                    definput     = {'40'};  % default value
                    StreetLength = inputdlg(prompt,dlgtitle,dims,definput);
                    L                  = str2num(StreetLength{1});
                    
                    %% Read and initialize
                    
                    % Set up progress display bar
                    fig1 = uifigure;
                    d = uiprogressdlg(fig1,'Title','Please Wait',...
                        'Message','Calculation in processing...','Cancelable','on','ShowPercentage','on');
                    
                    % Read and create camera parameter objects
                    dx                 = values(1);
                    dy                 = values(2);
                    Cx                 = values(3);
                    Cy                 = values(4);
                    Sx                 = values(5);
                    f                  = values(6);
                    k                  = values(7);
                    Tx                 = values(8);
                    Ty                 = values(9);
                    Tz                 = values(10);
                    r1                 = values(11);
                    r2                 = values(12);
                    r3                 = values(13);
                    r4                 = values(14);
                    r5                 = values(15);
                    r6                 = values(16);
                    r7                 = values(17);
                    r8                 = values(18);
                    r9                 = values(19);
                    
                    Intrinsics_Matrix  = [f,0,0;0,f,0;Cx,Cy,1];
                    Intrinsics_Object  = cameraParameters('IntrinsicMatrix',Intrinsics_Matrix);
                    rotation_Matrix    = [r1, r4, r7; r2, r5, r8; r3, r6, r9];
                    translation_Vector = [Tx, Ty, Tz];
                    
                    % Read and copy DataFromSky_csv table
                    Output_table              = raw_table(:,1:8);
                    
                    % Find out the track number
                    Number_of_Tracks = size(num_table,1);
                    
                    % Initialize basic matrixs: number of points of each track, entry and exit
                    % time of each track
                    Number_of_Points = zeros(Number_of_Tracks,1);
                    EntryTime        = Number_of_Points;
                    ExitTime         = Number_of_Points;
                    
                    %% Coordinate convertion
                    for p = 1 : Number_of_Tracks         % p is the track index
                        d.Value             = p/Number_of_Tracks;    % d.Value represents the progress (%)
                    
                        EntryTime(p)        = num_table(p,4);   % Entry and exit time of current track
                        ExitTime(p)         = num_table(p,6);
                    
                        Data                = num_table(p,:);   % Data saves numerical data of current track
                        Data(isnan(Data))   = [];
                        Number_of_Elements  = length(Data);
                        Number_of_Points(p) = (Number_of_Elements-7)/5;
                        deltaT              = Data(17)-Data(12);% deltaT represents time interval of the near two points
                    
                        pixel               =  zeros(Number_of_Points(p),2); % pixel represents the distorted pixel coordinate
                        Distort             =  pixel;                        % Distort represents the distorted image coordinate
                        Undistort           =  pixel;                        % Undistort represents undistorted PIXEL coordinate
                        World               =  pixel;                        % World represents the world coordinate
                    
                        for q = 1 : Number_of_Points(p)
                            pixel(q,:)      = [Data(5*q+3),Data(5*q+4)];
                        end
                    
                        % Coordinate converting
                        Distort             =  pixel - [Cx, Cy];
                        Undistort           =  Distort.*(1+k*(Distort(:,1).^2 + Distort(:,2).^2)) + [Cx,Cy];    
                        World               =  pointsToWorld(Intrinsics_Object,rotation_Matrix,translation_Vector,Undistort);
                    
                        % Speed and acceleration computing
                        delta               =  World(2:end,:) - World(1:end-1,:); % delta represents the distance of every near two trajectory points 
                        speed               =  sqrt(delta(:,1).^2 + delta(:,2).^2)/deltaT; % speed represents the average speed between every near two trajectory points
                        deltaV              =  speed(2:end) - speed(1:end-1); % deltaV represents the speed difference
                        Accel               =  deltaV/deltaT; % Accel represents the acceleration between every near two points
                    
                        % Results saving
                        for q = 1 : Number_of_Points(p)
                    
                            % coordinates saving
                            Output_table{p+1,5*q+5}      =   World(q,1);
                            Output_table{p+1,5*q+6}      =   World(q,2);
                    
                            % speed saving
                            if q <= Number_of_Points(p) - 1 % the last item doesn't have a speed value
                                Output_table{p+1,5*q+7}  =   speed(q);
                            end
                    
                            % acceleration saving
                            if q <= Number_of_Points(p) - 2 % the last two items don't have acceleration value
                                Output_table{p+1,5*q+8}  =   Accel(q);
                            end
                    
                            % Time-info saving
                            Output_table{p+1,5*q+4}      =   Data(12)+deltaT*(q-1);
                    
                        end
                    
                        % the track with "has stopped"-maneuver will be marked
                        check = 0; % default value 0 means non-stopped
                        for q = 1 : Number_of_Points(p)-1
                            if speed(q) <= 0.5 % threshold speed: 0.5 m/s (1.8 km/h) Reason: considering the unstable point shifting
                                check = 1;
                                break
                            end        
                        end
                        Output_table{p+1,7} = check;
                    
                        % avg. Speed in Output-table saving
                        Output_table{p+1,8} = mean(speed);
                    
                        % Maneuver in Output-table saving
                        Output_table{p+1,3} = strcat(num2str(Output_table{p+1,3}),'--',num2str(Output_table{p+1,5}));
                    
                        % Date and time in Output-table saving
                        Date = Video_Date + seconds(EntryTime(p));
                        Output_table{p+1,5} = datestr(Date);    
                    
                    end
                                       
                    
                    %% Traffic density computing
                    for ego = 1 : Number_of_Tracks % ego is the index of current track
                    
                        Number_Common_Tracks = 1; % the number of tracks appearing in the same time window. "1" represents itself
                    
                        for TN = 1 : Number_of_Tracks % TN is index of the Verkehrsteilnehmer
                    
                            if strcmp(Output_table{TN+1,9},Output_table{ego+1,9}) == 1 % check if both tracks are with same maneuver
                    
                                if EntryTime(TN) > EntryTime(ego) && EntryTime(TN) < ExitTime(ego)               
                                    % TN runs after ego.
                                    Number_Common_Tracks = Number_Common_Tracks + 1;
                                end
                    
                                if ExitTime(TN) > EntryTime(ego) && ExitTime(TN) < ExitTime(ego)
                                    % TN runs before ego.
                                    Number_Common_Tracks = Number_Common_Tracks + 1;
                                end
                    
                                if EntryTime(TN) > EntryTime(ego) && ExitTime(TN)< ExitTime(ego)
                                    % TN runs after ego at the beginning, and surpasses ego in the end.
                                    Number_Common_Tracks = Number_Common_Tracks - 1;
                                end
                    
                                Output_table{ego+1,10}   = 1000 * Number_Common_Tracks/L; % Unit: [1/km]
                    
                            end
                    
                        end
                    
                    end
                    
                    
                    %% Create title of the table
                    for q = 1:max(Number_of_Points)
                        Output_table(1,5*q+5)    =   {'X Coordinate [m]'};
                        Output_table(1,5*q+6)    =   {'Y Coordinate [m]'};
                        Output_table(1,5*q+7)    =   {'Speed [m/s]'};
                        Output_table(1,5*q+8)    =   {'Accel. [m/s2]'};
                        Output_table(1,5*q+4)    =   {'Time [s]'};
                    end
                    
                    Output_table(1,7) = {'Has Stopped'};
                    Output_table(1,5) = {'Entry Time (YYMMDD)'};
                    Output_table(1,8) = {'Avg. Speed [m/s]'};
                    Output_table(1,3) = {'Maneuver'};
                    Output_table(1,6) = {'Traffic Density [1/km]'};
                    
                    %% Write the table to file
                    d = uiprogressdlg(fig1,'Title','Please Wait',...
                        'Message','Saving file...','Cancelable','on','ShowPercentage','on');
                    sheet = 1;
                    xlRange = 'A1';
                    newname = strcat('Output_',DFS_filename(1:end-4),'.xlsx');
                    xlswrite(newname,Output_table,sheet,xlRange);
                    close(d);
                    close(fig1);
                    msgbox(strcat('Finished. The result (',newname,') is saved under workspace root.'),'Success');
                
                case 'Pure Matlab'
                    %% Imput phase
                    
                    % Camera parameters
                    
                    uiwait(msgbox('Please import camera parameter computed by Function 3.','Pure Matlab modus','modal'));
                    
                    [Camera_Parameter_name,Camera_Parameter_path] = uigetfile('.mat','Please select camera parameter!');
                    
                    load(fullfile(Camera_Parameter_path,Camera_Parameter_name));
                    
                    fx = CAM.FocalLength(1);
                    fy = CAM.FocalLength(2);
                    Cx = CAM.PrincipalPoint(1);
                    Cy = CAM.PrincipalPoint(2);
                    
                    
                    % File containing pixel coordinates
                    
                    uiwait(msgbox('Please select the DataFromSky trajectory csv file you want to convert.', ...
                        'Select DFS file','modal'));
                    
                    [DFS_filename, DFS_filepath] = uigetfile('*.csv','Please select DataFromSky output csv-file');
                    
                    DataFromSky_csv = fullfile(DFS_filepath, DFS_filename);
                    
                    [num_table, ~, raw_table] = xlsread(DataFromSky_csv);
                    
                    
                    % Date and time
                    
                    prompt_0 = {'Enter the video start time (Year).','Month','Day','Hour', ...
                        'Minute'};
                    dlgtitle_0 = 'Date and time';
                    dims_0 = [1 45];
                    definput_0 = {'2019','09','17','10','00'};  % default value
                    
                    DateAndTime = inputdlg(prompt_0,dlgtitle_0,dims_0,definput_0);
                    
                    Video_Year = str2num(DateAndTime{1});
                    Video_Month = str2num(DateAndTime{2});
                    Video_Day = str2num(DateAndTime{3});
                    Video_StartHour = str2num(DateAndTime{4});
                    Video_StartMinute = str2num(DateAndTime{5});
                    Video_Date = datetime(Video_Year,Video_Month,Video_Day, ...
                        Video_StartHour,Video_StartMinute,0);
                    
                    
                    % object height
                    
                    prompt_1 = {'Type: Car (Unit: m)','Type: Medium Vehicle (Unit: m)', ...
                        'Type: Heavy Vehicle (Unit: m)', 'Type: Bus (Unit: m)','Type: Motorcycle (Unit: m)', ...
                        'Type: Bicycle (Unit: m)','Type: Pedestrian (Unit: m)', ...
                        'Type: Undefined (Unit: m)'};
                    dlgtitle_1 = 'Please define object height';
                    dims_1 = [1 60];
                    definput_1 = {'1.5', ... % car (VW Golf: 1456mm)
                                     '2.4', ... % medium vehicle (Mercedes Sprinter: 2365mm)
                                     '3.5', ... % heavy vehicle (Mercedes Actros: 3419mm)
                                     '3.5', ... % bus (Mercedes Tourismo: 3680mm,(wegen Klimaanlage ein bisschen niedriger))
                                     '1.75', ... % motorcycle
                                     '1.5', ... % bicycle
                                     '1.75', ... % pedestrian
                                     '2'}; % undefined
                                 % default value
                                 % reference: https://de.automobiledimension.com/
                                            % https://www.mercedes-benz.de/
                                            % file:///C:/Users/s4308286/AppData/Local/Temp/mbt-cab-gigaspace-solostar-de.pdf
                                 
                    object_height = inputdlg(prompt_1,dlgtitle_1,dims_1,definput_1);
                    
                    car_H = str2num(object_height{1});
                    mediumV_H = str2num(object_height{2});
                    heavyV_H = str2num(object_height{3});
                    bus_H = str2num(object_height{4});
                    motorcycle_H = str2num(object_height{5});
                    bicycle_H = str2num(object_height{6});
                    pedestrian_H = str2num(object_height{7});
                    undef_H = str2num(object_height{8});
                    
                    
                    % Imput the street length to calculate the traffic density
                    
                    prompt_2 = {'Enter the distance between two gates on the main street (in meter), in order to calculate the traffic density.'};
                    dlgtitle_2 = 'Street length';
                    dims_2 = [1 55];
                    definput_2 = {'65'};  % default value
                    
                    StreetLength = inputdlg(prompt_2,dlgtitle_2,dims_2,definput_2);
                    
                    L = str2num(StreetLength{1});
                    
                    
                    %% Read and initialize
                    
                    % Set up progress display bar
                    
                    fig1 = uifigure;
                    d = uiprogressdlg(fig1,'Title','Please Wait',...
                        'Message','Calculation in processing...','Cancelable','on','ShowPercentage','on');
                    
                    % Read and copy DataFromSky_csv table
                    
                    Output_table = raw_table(:,1:8);
                    
                    % Find out the track number
                    
                    Number_of_Tracks = size(num_table,1);
                    
                    % Initialize some inportant matrixs: number of points of each track, 
                    % entry and exit time of each track
                    
                    Number_of_Points = zeros(Number_of_Tracks,1);
                    EntryTime = Number_of_Points;
                    ExitTime = Number_of_Points;
                    
                    %% Coordinate convertion
                    for p = 1 : Number_of_Tracks         % p is the track index
                        d.Value = p/Number_of_Tracks;    
                        % d.Value represents the progress (%)
                    
                        EntryTime(p) = num_table(p,4);   
                        % Entry and exit time of current track
                        ExitTime(p) = num_table(p,6);
                        
                        vehicle_type = raw_table{p+1,2};
                        % get vehicle type from original table
                        switch vehicle_type
                            case ' Car'
                                zw = -car_H/2;
                            case ' Medium Vehicle'
                                zw = -mediumV_H/2;
                            case ' Heavy Vehicle'
                                zw = -heavyV_H/2;
                            case ' Bus'
                                zw = -bus_H/2;
                            case ' Motorcycle'
                                zw = -motorcycle_H/2;
                            case ' Bicycle'
                                zw = -bicycle_H/2;
                            case ' Pedestrian'
                                zw = -pedestrian_H/2;
                            case ' Undefined'
                                zw = -undef_H/2;
                        end
                    
                        Data = num_table(p,:);
                            % Data saves numerical data of current track
                            
                        Data(isnan(Data)) = [];
                        
                        Number_of_Elements = length(Data);
                        
                        Number_of_Points(p) = (Number_of_Elements-7)/5;
                        
                        deltaT = Data(17)-Data(12);
                            % deltaT represents time interval of the near two points
                    
                        % Initialize some inportant matrixs: pixel/norm_pixel/world/GPS coordinates
                        
                        pixel = zeros(Number_of_Points(p),2);
                            % pixel represents the pixel coordinate (corrected)
                            
                        pixel_norm = pixel;
                            % pixel_norm represents the normilized corrected pixel coordinate
                            
                        World = pixel;
                            % World represents the world coordinate
                            
                        GPS = pixel;
                            % GPS represents the latitude and longitude coordinate
                                            
                        for q = 1 : Number_of_Points(p)
                            
                            pixel(q,:) = [Data(5*q+3),Data(5*q+4)];
                        
                            % Coordinate converting
                            
                            pixel_norm(q,:) =  pixel(q,:) - [Cx, Cy];
                            x_norm = pixel_norm(q,1);
                            y_norm = pixel_norm(q,2);
                            
                            % syms xw yw x y z
                            % e1 = r1*xw + r2*yw + r3*zw + Tr1 - x;
                            % e2 = r4*xw + r5*yw + r6*zw + Tr2 - y;
                            % e3 = r7*xw + r8*yw + r9*zw + Tr3 - z;
                            % e4 = fx*x/z - x_norm;
                            % e5 = fy*y/z - y_norm;
                            % [xw0,yw0,x0,y0,z0] = solve(e1,e2,e3,e4,e5,xw,yw,x,y,z,'Real', 1);
                            % Following calculation is the simplification of these five equations
                            
                            gx = x_norm / fx;
                            gy = y_norm / fy;
                            gz = r9*zw + Tr3;
                    
                            matrix1 = [(r1-gx*r7), (r2-gx*r8); (r4-gy*r7), (r5-gy*r8)];
                            matrix2 = [(gx*gz - (r3*zw+Tr1)); (gy*gz-(r6*zw+Tr2))];
                            
                            ans_World = matrix1\matrix2;
                            World(q,1) = ans_World(1);
                            World(q,2) = ans_World(2);
                            
                            % GPS convertion is based on:
                            % https://www.cnblogs.com/0201zcr/p/4673924.html (in Chinese)
                            GPS(q,1) = LatA + World(q,1)/6371004 * 57.2958;
                            Part = (cos(abs(World(q,2)/6371004)) - sin(LatA/57.2958)* ...
                                sin(LatA/57.2958)) / (cos(LatA/57.2958)*cos(LatA/57.2958));
                            GPS(q,2) = LonA + 57.2958*acos(Part)*sign(World(q,2));
                       
                        end
                        
                        % Speed and acceleration computing
                        
                        delta = World(2:end,:) - World(1:end-1,:);
                            % delta represents the distance of every near two trajectory points
                            
                        speed = sqrt(delta(:,1).^2 + delta(:,2).^2)/deltaT;
                            % speed represents the speed between two nearby trajectory points
                            
                        deltaV = speed(2:end) - speed(1:end-1);
                            % deltaV represents the speed difference
                            
                        Accel = deltaV/deltaT;
                            % Accel represents the acceleration between every near two points
                    
                            
                        % Results saving
                        
                        for q = 1 : Number_of_Points(p)
                    
                            % coordinates saving
                            Output_table{p+1,5*q+5} = GPS(q,1);
                            Output_table{p+1,5*q+6} = GPS(q,2);
                    
                            % speed saving
                            if q <= Number_of_Points(p) - 1
                                    % the last item doesn't have a speed value
                                Output_table{p+1,5*q+7} = speed(q);
                            end
                    
                            % acceleration saving
                            if q <= Number_of_Points(p) - 2
                                    % the last two items don't have acceleration value
                                Output_table{p+1,5*q+8} = Accel(q);
                            end
                    
                            % Time-info saving
                            Output_table{p+1,5*q+4} = Data(12)+deltaT*(q-1);
                    
                        end
                    
                        % the track with "has stopped"-maneuver will be marked
                        
                        check = 0; % default value 0 means non-stopped
                        
                        for q = 1 : Number_of_Points(p)-1
                            
                            if speed(q) <= 0.5
                                    %threshold speed: 0.5 m/s (1.8 km/h)
                                    %Reason: considering the unstable point shifting
                                    
                                check = 1;
                                
                                break
                                
                            end
                            
                        end
                        
                        Output_table{p+1,7} = check;
                    
                        % avg. Speed in Output-table saving
                        Output_table{p+1,8} = mean(speed);
                    
                        % Maneuver in Output-table saving
                        Output_table{p+1,3} = strcat(num2str(Output_table{p+1,3}), ...
                            '--',num2str(Output_table{p+1,5}));
                    
                        % Date and time in Output-table saving
                        Date = Video_Date + seconds(EntryTime(p));
                        Output_table{p+1,5} = datestr(Date);    
                    
                    end
                    
                    %% Traffic density computing
                    
                    for ego = 1 : Number_of_Tracks % ego is the index of current track
                    
                        Number_Common_Tracks = 1;
                        % the number of tracks appearing in the same time window.
                        % "1" represents itself
                    
                        for TN = 1 : Number_of_Tracks % TN is index of the Verkehrsteilnehmer
                    
                            if strcmp(Output_table{TN+1,9},Output_table{ego+1,9}) == 1
                                % check if both tracks are with same maneuver
                    
                                if EntryTime(TN) > EntryTime(ego) && EntryTime(TN) < ...
                                        ExitTime(ego)
                                    % TN runs after ego.
                                    Number_Common_Tracks = Number_Common_Tracks + 1;
                                end
                    
                                if ExitTime(TN) > EntryTime(ego) && ExitTime(TN) < ...
                                        ExitTime(ego)
                                    % TN runs before ego.
                                    Number_Common_Tracks = Number_Common_Tracks + 1;
                                end
                    
                                if EntryTime(TN) > EntryTime(ego) && ExitTime(TN)< ...
                                        ExitTime(ego)
                                    % TN runs after ego at the beginning, 
                                    % and surpasses ego in the end.
                                    Number_Common_Tracks = Number_Common_Tracks - 1;
                                end
                    
                                Output_table{ego+1,10} = 1000 * Number_Common_Tracks/L;
                                % Unit: [1/km]
                    
                            end
                    
                        end
                    
                    end
                    
                    %% Create title of the table
                    
                    for q = 1:max(Number_of_Points)
                        Output_table(1,5*q+5) = {'Latitude'};
                        Output_table(1,5*q+6) = {'Longitude'};
                        Output_table(1,5*q+7) = {'Speed [m/s]'};
                        Output_table(1,5*q+8) = {'Accel. [m/s2]'};
                        Output_table(1,5*q+4) = {'Time [s]'};
                    end
                    
                    Output_table(1,7) = {'Has Stopped'};
                    Output_table(1,5) = {'Entry Time (YYMMDD)'};
                    Output_table(1,8) = {'Avg. Speed [m/s]'};
                    Output_table(1,3) = {'Maneuver'};
                    Output_table(1,6) = {'Traffic Density [1/km]'};
                    
                    Output_table = Output_table'; % transpose
                    
                    %% Write the table to file
                    
                    d = uiprogressdlg(fig1,'Title','Please Wait','Message','Saving file...', ...
                        'Cancelable','on');
                    sheet = 1;
                    xlRange = 'A1';
                    
                    xlswrite(strcat('Output_',DFS_filename(1:end-4),'.xlsx'),Output_table, ...
                        sheet,xlRange);
                    
                    close(d);
                    close(fig1);
                    msgbox("finished. The result is saved under workspace root.");
            end
        end

        % Button pushed function: CalibratevideoButton
        function CalibratevideoButtonPushed(app, event)
            switch app.VideoAmount1.Value
                case 'Multi videos'
                    [CameraIntrinsics,path] = uigetfile('.mat','Please select camera intrinsics');
                    CameraIntrinsics = fullfile(path,CameraIntrinsics);
                    load(CameraIntrinsics);
                    % opens up user interface to select video file
                    [videofile,videopath] = uigetfile('*.mp4','MultiSelect','on','Please select videos (at least two!)');
                    VideoFileList = fullfile(videopath, videofile);
                    len = length(VideoFileList);
                    f1 = uifigure('Position',[600,500,400,200]);
                    f2 = uifigure('Position',[600,270,400,200]);
                    D = uiprogressdlg(f1,'Title','Progress of total videos',...
                                'Message','Conversion in processing...','Cancelable','on','ShowPercentage','on');
                    d = uiprogressdlg(f2,'Title','Progress of current video',...
                                'Message','Conversion in processing...','Cancelable','on','ShowPercentage','on');
                   
                    for File_Number = 1:len
                    % gets input file name
                    fileVideoUndist = VideoFileList{File_Number}; 
                    % Video file reader variable 
                    vfrUndist = vision.VideoFileReader(fileVideoUndist);
                    % Player window
                    vpUndist = vision.VideoPlayer('Position', [100, 100, 1920, 1080]);
                    obj = VideoReader(fileVideoUndist);
                    numFrames = obj.NumberOfFrames;
                    % writer
                    % prompts the user to name the new video file
                    NewFileName = strcat(videopath, 'cal_', strtok(videofile{File_Number}, '.'),'.mp4');
                    % sets up the video file writer variable and its parameters
                    vfwUndist = vision.VideoFileWriter(NewFileName,...
                                                        'FrameRate',vfrUndist.info.VideoFrameRate,...
                                                        'FileFormat','MPEG4');
                    D.Value = File_Number/len;
                    i = 1;
                    % loop to read in video frame, pass it into the undistort function, and 
                    % save as a new video file
                    while ~isDone(vfrUndist)
                    % reads in frame from video file
                        frame_undist = step(vfrUndist);
                    % uses the camera paramters to undistort the image
                        frame = undistortImage(frame_undist, CAM);
                    % writes to video file
                        step(vfwUndist,frame);
                        d.Value = i/numFrames;
                        i=i+1;
                    end
                    end
                    % Close dialog box
                    close(d);
                    close(D);
                    close(f1);
                    close(f2);
                    release(vpUndist);
                    release(vfrUndist);
                    release(vfwUndist);
                    msgbox(strcat('Congratulations!',32,num2str(len),32,'videos are calibrated. Please go to the folder of original video.'),'Success');
            
                case 'Single video'
                    % Pass in the camera parameters varibale from a saved work space
                    [CameraIntrinsics,path] = uigetfile('.mat','Please select camera intrinsics');
                    CameraIntrinsics = fullfile(path,CameraIntrinsics);
                    load(CameraIntrinsics);
                    % opens up user interface to select video file
                    [filename,filepath] = uigetfile('.mp4','Please select a video');
                    % gets input file name
                    fileVideoUndist = fullfile(filepath,filename); 
                    % prompts the user to name the new video file
                    NewFileName = strcat(filepath, 'cal_', strtok(filename, '.'),'.mp4');
                    % Video file reader variable 
                    obj=VideoReader(fileVideoUndist);
                    numFrames = obj.NumberOfFrames;
                    vfrUndist = vision.VideoFileReader(fileVideoUndist);
                    % Player window
                    vpUndist = vision.VideoPlayer('Position', [100, 100, 1920, 1080]);              
                    % sets up the video file writer variable and its parameters
                    vfwUndist = vision.VideoFileWriter(NewFileName, 'FrameRate',vfrUndist.info.VideoFrameRate, 'FileFormat', 'MPEG4');
                    % loop to read in video frame, pass it into the undistort function, and 
                    % save as a new video file
                    f = uifigure;
                    d = uiprogressdlg(f,'Title','Please Wait',...
                                'Message','Conversion in processing...','Cancelable','on','ShowPercentage','on');
                    i = 1;
                    while ~isDone(vfrUndist)
                    % reads in frame from video file
                        frame_undist = step(vfrUndist);
                    % uses the camera paramters to undistort the image
                        frame = undistortImage(frame_undist, CAM);
                    % writes to video file
                        step(vfwUndist,frame);
                        d.Value = i/numFrames;
                        i=i+1;
                    end
                    % Close dialog box
                    close(d);
                    close(f);
                        
                    release(vpUndist);
                    release(vfrUndist);
                    release(vfwUndist);
                    %% finish
                    msgbox('Conversion completed. Please go to the folder of original video.','Success');
            end
        end

        % Button pushed function: ExportButton
        function ExportButtonPushed(app, event)
            switch app.VideoAmount2.Value
                case 'Multi videos'
                    [filename,filepath] = uigetfile('*.MP4','MultiSelect','on');
                    len = length(filename);
                    prompt = {'Enter the frame sequence number you want to export. (Frame sequence number = seconds * FPS):'};
                    dlgtitle = 'When?';
                    dims = [1 55];
                    definput = {'25'};  % default size
                    answer = inputdlg(prompt,dlgtitle,dims,definput);
                    FrameNumber = str2num(answer{1});
                   
                    for k = 1 : len
                    videoname = fullfile(filepath,filename{k});
                    obj = VideoReader(videoname);
                    frame = read(obj,FrameNumber);
                    imwrite(frame,strcat(filepath,'Frame_',filename{k}(1:end-4),'_',answer{1},'.jpg'));
                    end
                    msgbox(strcat('Congratulations! The frame of',32,num2str(len),32,'videos are exported to the video folder.'),'Success');
          
                case 'Single video'
                    [filename,filepath] = uigetfile('*.MP4');
                    
                    prompt = {'Enter the frame sequence number you want to export. (Frame sequence number = seconds * FPS):'};
                    dlgtitle = 'When?';
                    dims = [1 55];
                    definput = {'25'};  % default size
                    answer = inputdlg(prompt,dlgtitle,dims,definput);
                    FrameNumber = str2num(answer{1});
                    
                    videoname = fullfile(filepath,filename);
                    obj = VideoReader(videoname);
                    frame = read(obj,FrameNumber);
                    imshow(frame);
                    imwrite(frame,strcat(filepath,'Frame_',filename(1:end-4),'_',answer{1},'.jpg'));
                    msgbox(strcat('Congratulations! The frame is exported to the video folder.'),'Success');
            end
        end

        % Button pushed function: CompareButton
        function CompareButtonPushed(app, event)
            [filename,filepath] = uigetfile({'*.jpg';'*.png';'*.gif';'*.bmp'},'MultiSelect','on');
            len = length(filename);
            imagename = fullfile(filepath,filename);
            
            for k = 2 : len
            imag1 = imagename{k-1};
            imag2 = imagename{k};
            I = imread(imag1);
            J = imread(imag2);
            
            figure('position',[0,0,1135,850])
            subplot(3,2,1);
            imshow(I);
            title(strrep(filename{k-1},'_','\_'));
            
            subplot(3,2,2);
            imshow(J);
            title(strrep(filename{k},'_','\_'));
            
            subplot(3,2,[3,4,5,6]);
            imshowpair(I,J,'falsecolor');
            title('Image difference');
            
            uiwait(msgbox('Continue?'));
            close all;
            end
            msgbox('Compare finished.');
        end

        % Button pushed function: Schachbrettmuster
        function SchachbrettmusterButtonPushed(app, event)
            open checkerboardPattern.pdf
        end

        % Button pushed function: CalculateButton
        function CalculateButtonPushed(app, event)
            prompt = {'Enter camera height: (m)';'Enter horizontal angle of view: (degree value offered by manufacturer)';'Enter vertical angle of view: (degree value offered by manufacturer)'};
            dlgtitle = 'Calculate field of view';
            dims = [1 55];
            definput = {'50';'110';'85'};  % default value
            answer = inputdlg(prompt,dlgtitle,dims,definput);
            y = str2num(answer{1});
            alpha = str2num(answer{2});
            beta = str2num(answer{3});
            
            b=abs(2*y*tan(alpha*pi/180/2));
            h=abs(2*y*tan(beta*pi/180/2));
            
            msgbox(strcat('Estimated field of view is:',10,10,'Horizontal direction:',32,num2str(b),'m',32,32,32,32,'Vertical direction:',32,num2str(h),'m'),'Result');
        end

        % Value changed function: MethodDropDown
        function MethodDropDownValueChanged(app, event)
            value = app.MethodDropDown.Value;
        end

        % Button pushed function: CalculateheightButton
        function CalculateheightButtonPushed(app, event)
            switch app.ExtrinsicsCalculationModus.Value
                
                case 'T-Calibration'
                    
                    uiwait(msgbox('Please import camera parameters computed by T-Calibration.','Calculate camera height','modal'));
                    
                    [T_Analyst_Params,filepath] = uigetfile('.tacal','Please select camera parameters by T-Calibration');
                    T_Analyst_Params = fullfile(filepath,T_Analyst_Params);
                    
                    [~,values] = textread(T_Analyst_Params,'%s%n');
                    
                    dx=      values(1);
                    dy=      values(2);
                    Cx=      values(3);
                    Cy=      values(4);
                    Sx=      values(5);
                     f=      values(6);
                     k=      values(7);
                    Tx=      values(8);
                    Ty=      values(9);
                    Tz=      values(10);
                    r1=      values(11);
                    r2=      values(12);
                    r3=      values(13);
                    r4=      values(14);
                    r5=      values(15);
                    r6=      values(16);
                    r7=      values(17);
                    r8=      values(18);
                    r9=      values(19);
                    
                    syms xc yc h;
                    e1 = r1 * xc + r2 * yc - r3 * h + Tx;
                    e2 = r4 * xc + r5 * yc - r6 * h + Ty;
                    e3 = r7 * xc + r8 * yc - r9 * h + Tz;
                    
                    [x0,y0,h0] = solve(e1,e2,e3,xc,yc,h,'Real',1);
                    CameraHeight = double(h0); 
            
                case '4 points'
                    
                    uiwait(msgbox('Please import camera extrinsics. This is mat file calculated by 4 points method.','Extrinsics','modal'));
                    
                    [CameraExtrinsics,path] = uigetfile('.mat','Please select camera extrinsics');
                    CameraExtrinsics = fullfile(path,CameraExtrinsics);
                    load(CameraExtrinsics);
                                        
                    syms xc yc h;
                    e1 = r1 * xc + r2 * yc + r3 * h - Tr1;
                    e2 = r4 * xc + r5 * yc + r6 * h - Tr2;
                    e3 = r7 * xc + r8 * yc + r9 * h - Tr3;
                    
                    [x0,y0,h0] = solve(e1,e2,e3,xc,yc,h,'Real',1);
                    CameraHeight = double(h0); 
            end
                    
            uiwait(msgbox(strcat('According to calibration result, the camera height shows to be',32,num2str(CameraHeight),'m.'),'Evaluate calibration accuracy','modal'));
            
        end

        % Button pushed function: Button
        function ButtonPushed(app, event)
            q = zeros(9,1);
            q(1) = app.ComputerVisionToolboxinstalledCheckBox.Value;
            q(2) = app.checkerboardprintedCheckBox.Value;
            q(3) = app.checkerboardcapturedCheckBox.Value;
            q(4) = app.cameraintrinsicscomputedCheckBox.Value;
            q(5) = app.videocorrectedCheckBox.Value;
            q(6) = app.videoinDataFromSkyuploadedCheckBox.Value;            
            q(7) = app.cameraextrinsicscomputedCheckBox.Value;
            q(8) = app.vehicletrajectoryexportedCheckBox.Value;
            q(9) = app.speedcomputedCheckBox.Value;
            s = cell(9,1);
            s{1} = "Please install Matlab Computer Vision Toolbox firstly.";
            s{2} = "Please click checkerboard button in Function 1.";
            s{3} = "Please capture the checkerboard with the same camera setting.";
            s{4} = "Please click Get intrinsics in Function 1.";
            s{5} = "Please run Function 2.";
            s{6} = "Please upload videos to DFS after Function 2.";
            s{7} = "Please run Function 3.";
            s{8} = "Please set gates and export trajectory in DFS-Viewer.";
            s{9} = "Please run Function 4 (and Function 5 if necessary).";
            
            j = 1;
            g = cell(9,2);
            for i = 1:9
                if q(i) == 0
                    g{j,1} = j;
                    g{j,2} = s{i}; 
                    j = j+1;
                end
            end
            result = cell2table(g(1:j-1,1:2));
            app.UITable.Data = result;
        end

        % Button pushed function: GetTTCandPETButton
        function GetTTCandPETButtonPushed(app, event)
             % hier ist die xlsx-Datei zu importieren.
            answer1 = questdlg('If you want to calculate TTC and PET, please make sure that you has set the time step to 1 during trajectory exporting in DataFromSky.',...
                'Attention','Yes','No','Yes');
            
            switch answer1
                case 'Yes'
                    % Load real trajectory file
                    uiwait(msgbox('Please select the real trajectory file you want to convert.','Select file','modal'));
                        [DFS_filename, DFS_filepath] = uigetfile('*.xlsx','Please select converted xlsx-file');
                    
                    % Define car length, which is essential for calculating
                    % TTC
                    prompt = {'Lower bound (Unit: m)','Mean (Unit: m)','Upper bound (Unit: m)','TTC-Sensitivity (Range: 0.5-2)','PET-Controll angle (Unit: degree)'};
                    dlgtitle = 'Configuration';
                    dims = [1 55];
                    definput = {'0.86','4.8103','8.76','1.5','20'};  % default value
                    answer = inputdlg(prompt,dlgtitle,dims,definput);
                    L_min =         str2num(answer{1});
                    L_avg =         str2num(answer{2});
                    L_max =         str2num(answer{3});
                    TTC_Sensitivity =        str2num(answer{4});
                    Degree =        str2num(answer{5});
                    
                    DateiName = fullfile(DFS_filepath, DFS_filename);
                    
                    f = uifigure('Position',[600,270,400,200]);
                    d = uiprogressdlg(f,'Title','Progress',...
                        'Message','Initializing...','Cancelable','on','ShowPercentage','on');
            
                    [num, ~, Ergebnis] = xlsread(DateiName);
                    
                    % Initializing
                    Number_of_Vehicles = size(num,1);
                    EntryTime          = zeros(Number_of_Vehicles,1);
                    ExitTime           = zeros(Number_of_Vehicles,1);
                    Maneuver = Ergebnis(2:end,3);
                    Track = num(:,1);
                    deltaT = num(1,14)-num(1,9);
                    
                    % Setting the loop to process every trajektory
                    for p = 1 : Number_of_Vehicles
                        if d.CancelRequested
                            break
                        end
                        d.Value = p/Number_of_Vehicles;
                        
                        Data = num(p,:);
                        Data(isnan(Data)) = [];
                        Number_of_Points = (length(Data)-2)/5;
                        
                        % Read out the time information
                        EntryTime(p) = num(p,4);
                        ExitTime(p)  = EntryTime(p)+deltaT*(Number_of_Points-2);
                        
                        for q = 1 : Number_of_Points - 1            
                             X_position(p,q)    = Data(5*q+2);
                             Y_position(p,q)    = Data(5*q+3);
                             Speed_Array(p,q)   = Data(5*q+4);
                        end
                        
                        %% Find vehicle trajectory by polynomial fitting
                        % Matrix D saves the coefficient of the polynomial
                        % function, in order to detect two overlapping
                        % trajectories
                        % Matrix E saves the coefficient of linear
                        % regression, in order to estimate two crossing
                        % trajectories
                        if isempty(find(X_position(p,:)==0))
                             D(p,:) = polyfit(X_position(p,:),Y_position(p,:),4); %Quelle: https://link.springer.com/article/10.1007/s10015-018-0484-4
                             E(p,:) = polyfit(X_position(p,:),Y_position(p,:),1);
                        else
                             D(p,:) = polyfit(X_position(p,1:find(X_position(p,:)==0,1)-1),Y_position(p,1:find(X_position(p,:)==0,1)-1),4); %Quelle: https://link.springer.com/article/10.1007/s10015-018-0484-4
                             E(p,:) = polyfit(X_position(p,1:find(X_position(p,:)==0,1)-1),Y_position(p,1:find(X_position(p,:)==0,1)-1),1);
                        end
                        
                    end
                    
                    %% searching the required car pairs
                    p1 = 1;
                    p2 = 1;
                    d = uiprogressdlg(f,'Title','Progress',...
                        'Message','Calculating...','Cancelable','on','ShowPercentage','on');
                    
                    Title2      = {'Time [s]';'min. TTC [s]';'Avg. TTC [s]';'max. TTC [s]'};
                    Title3      = {'T1 [s]';'T2 [s]';'PET [s]'};
                    Output_TTC = {};
                    Output_PET = {};
                    
                    for i = 1:Number_of_Vehicles
                        
                        if d.CancelRequested
                            break % modul for cancelling
                        end
                        d.Value = i/Number_of_Vehicles; % modul for showing progress
                        
                        check1 = 0; % for TTC: the calculation will only do once (before the car i)
                        check2 = 0; % for TTC: the calculation will only do once (after the car i)
                        
                        if i == 1
                            i = 1; % �berspringt den Fall i = 1
                        else
                            for j = i-1:-1:1 % consider the car before the current car i
                                AAA = EntryTime(i):deltaT:ExitTime(i);
                                BBB = EntryTime(j):deltaT:ExitTime(j);
                                [AA,ia,ib] = intersect(single(AAA),single(BBB));
                                if isempty(AA) == 0 % Es gibt gleiche Zeitreihe
                                    X_pi        = X_position(i,ia);
                                    Y_pi        = Y_position(i,ia);
                                    Speed_pi    = Speed_Array(i,ia);
                                    X_pj        = X_position(j,ib);
                                    Y_pj        = Y_position(j,ib);
                                    Speed_pj    = Speed_Array(j,ib);
                                    % TTC Calculation will only do once (the nearest car is of interest)
                                    if (check1 == 0) && (strcmp(Maneuver{i},Maneuver{j}) == 1) && (max(abs(D(i,:)-D(j,:))) <= TTC_Sensitivity) % gleiche Man�ver
                                        TTC_j       = zeros(4,length(ia));
                                        TTC_j(1,:)  = AAA(ia);
                                        Abstand = sqrt((X_pi-X_pj).^2 + (Y_pi-Y_pj).^2);
                                        V_Unterschied = abs(Speed_pi-Speed_pj);
                                        TTC_j(2,:)  = (Abstand - L_max)./V_Unterschied;
                                        TTC_j(3,:)  = (Abstand - L_avg)./V_Unterschied;  
                                        TTC_j(4,:)  = (Abstand - L_min)./V_Unterschied;
                                        Title1      = strcat('Track',num2str(Track(i)),'__Track',num2str(Track(j)));
                                        Output_TTC{p1} = table(Title2,round(TTC_j,2),'VariableNames',{Title1,'No'});
                                        p1 = p1 + 1;
                                        check1 = 1; % mark, then the search ends for the next loop
                                    end
                                    % PET Calculation will do more than once
                                    
                                    % estimate the crossing point using linear regression function
                                    ki = E(i,1);
                                    kj = E(j,1);
                                    alpha_ij = atan((ki-kj)/(1-ki*kj))*180/pi;
                                    % ensure there is a crossing point in the observation zone, and the angel is greater than controll degree
                                    Mi = Maneuver{i};Mj = Maneuver{j}; % Mi und Mj sind die Maneuver, z.B. '3--2'
                                    Mii = find(Mi=='-');Mjj = find(Mj=='-'); % Mii und Mjj sind die Position des '-' Symbols
                                    Miii = Mi(1:Mii(1)-1);Mjjj = Mj(1:Mjj(1)-1); % Miii, Mjjj sind die Einfahrtzone (Gate), z.B. '3'
                                                                        
                                    if (strcmp(Miii,Mjjj) == 0) && (abs(alpha_ij)>Degree) % the cars with same maneuver or with very parallel direction will not be considered for PET calculation
                                        Abstand_PET = zeros(length(X_pi),1); % this vector saves the minimal distance between POINT i1 of car i and all points of car j.
                                        index_PET = Abstand_PET; % this vector saves the corresponding point index of car j
                                        for i1 = 1:length(X_pi)
                                            [Abstand_PET(i1),index_PET(i1)] = min((X_pj-X_pi(i1)).^2 + (Y_pj-Y_pi(i1)).^2);
                                        end
                                        if min(Abstand_PET) < 0.5
                                            i1 = find(Abstand_PET==min(Abstand_PET));
                                            j1 = index_PET(i1);
                                            Time1 = AA(i1);
                                            Time2 = AA(j1);
                                            PET_j = zeros(3,1);
                                            PET_j(1) = Time1;
                                            PET_j(2) = Time2;
                                            PET_j(3) = abs(Time1-Time2);
                                        
                                            Title1 = strcat('Track',num2str(Track(i)),'__Track',num2str(Track(j)));
                                            Output_PET{p2} = table(Title3,round(PET_j,2),'VariableNames',{Title1,'Value'});
                                            p2 = p2 + 1;
                                        end
                                    end
                                else
                                    break
                                end
                            end
                        end
                        
                        for j = i+1:Number_of_Vehicles % consider the car after the current car i
                            AAA = EntryTime(i):deltaT:ExitTime(i);
                            BBB = EntryTime(j):deltaT:ExitTime(j);
                            [AA,ia,ib] = intersect(single(AAA),single(BBB));
                            if isempty(AA) == 0 %Es gibt gleiche Zeitreihe
                                X_pi        = X_position(i,ia);
                                Y_pi        = Y_position(i,ia);
                                Speed_pi    = Speed_Array(i,ia);
                                X_pj        = X_position(j,ib);
                                Y_pj        = Y_position(j,ib);
                                Speed_pj    = Speed_Array(j,ib);
                                % TTC Calculation will only do once (the nearest car is of interest)
                                if (check2 == 0) && (strcmp(Maneuver{i},Maneuver{j}) == 1) && (max(abs(D(i,:)-D(j,:))) <= TTC_Sensitivity) % gleiche Man�ver
                                    TTC_j       = zeros(4,length(ia));
                                    TTC_j(1,:)  = AAA(ia);
                                    Abstand = sqrt((X_pi-X_pj).^2 + (Y_pi-Y_pj).^2);
                                    V_Unterschied = abs(Speed_pi-Speed_pj);
                                    TTC_j(2,:)  = (Abstand - L_max)./V_Unterschied;                                      
                                    TTC_j(3,:)  = (Abstand - L_avg)./V_Unterschied;  
                                    TTC_j(4,:)  = (Abstand - L_min)./V_Unterschied;
                                    Title1      = strcat('Track',num2str(Track(i)),'__Track',num2str(Track(j)));
                                    Output_TTC{p1} = table(Title2,round(TTC_j,2),'VariableNames',{Title1,'No'});
                                    p1 = p1 + 1;
                                    check2 = 1; % mark, then the search ends for the next loop
                                end
                                
                                    % PET Calculation will do more than once
                                    
                                    % estimate the crossing point using linear regression function
                                    ki = E(i,1);
                                    kj = E(j,1);
                                    alpha_ij = atan((ki-kj)/(1-ki*kj))*180/pi;
                                    
                                    % ensure there is a crossing point in the observation zone, and the angel is greater than controll degree
                                    Mi = Maneuver{i};Mj = Maneuver{j}; % Mi und Mj sind die Maneuver, z.B. '3--2'
                                    Mii = find(Mi=='-');Mjj = find(Mj=='-'); % Mii und Mjj sind die Position des '-' Symbols
                                    Miii = Mi(1:Mii(1)-1);Mjjj = Mj(1:Mjj(1)-1); % Miii, Mjjj sind die Einfahrtzone (Gate), z.B. '3'
                                                                        
                                    if (strcmp(Miii,Mjjj) == 0) && (abs(alpha_ij)>Degree) % the cars with same maneuver or with very parallel direction will not be considered for PET calculation
                                        Abstand_PET = zeros(length(X_pi),1); % this vector saves the minimal distance between POINT i1 of car i and all points of car j.
                                        index_PET = Abstand_PET; % this vector saves the corresponding point index of car j
                                        for i1 = 1:length(X_pi)
                                            [Abstand_PET(i1),index_PET(i1)] = min((X_pj-X_pi(i1)).^2 + (Y_pj-Y_pi(i1)).^2);
                                        end
                                        if min(Abstand_PET) < 0.5
                                            i1 = find(Abstand_PET==min(Abstand_PET));
                                            j1 = index_PET(i1);
                                            Time1 = AA(i1);
                                            Time2 = AA(j1);
                                            PET_j = zeros(3,1);
                                            PET_j(1) = Time1;
                                            PET_j(2) = Time2;
                                            PET_j(3) = abs(Time1-Time2);
                                        
                                            Title1 = strcat('Track',num2str(Track(i)),'__Track',num2str(Track(j)));
                                            Output_PET{p2} = table(Title3,round(PET_j,2),'VariableNames',{Title1,'Value'});
                                            p2 = p2 + 1;
                                        end
                                    end
                                else
                                    break
                            end
                        end
                    end
                    
                    d = uiprogressdlg(f,'Title','Progress',...
                        'Message','writing TTC to excel... (the data has been already saved in mat-format in original path.)','Cancelable','on','ShowPercentage','on');
                    
                    save(strcat(DateiName(1:end-5),'_TTC_PET.mat'),'Output_TTC','Output_PET');
                    
                    for i = 1:p1-1
                        if d.CancelRequested
                            break
                        end
                        d.Value = i/Number_of_Vehicles;
                        
                        xlRange     = strcat('A',num2str(6*i-5));
                        writetable(Output_TTC{1,i},DateiName,'Sheet',2,'Range',xlRange);
                    end
                    
                    d = uiprogressdlg(f,'Title','Progress',...
                        'Message','writing PET to excel...(the data has been already saved in mat-format in original path.)','Cancelable','on','ShowPercentage','on');
                    
                    for i = 1:p2-1
                        if d.CancelRequested
                            break
                        end
                        d.Value = i/Number_of_Vehicles;
                        
                        xlRange     = strcat('A',num2str(5*i-4));
                        writetable(Output_PET{1,i},DateiName,'Sheet',3,'Range',xlRange);
                    end
                    close(d);
                    close(f);
                    
                    msgbox('Finished.');
                    
                case 'No'
                    msgbox('You cancelled.');
                    
                case ''
                    msgbox('You cancelled.');
            end
        end
    end

    % App initialization and construction
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create VideoAnalysisToolkit
            app.VideoAnalysisToolkit = uifigure;
            app.VideoAnalysisToolkit.Color = [0.902 0.902 0.902];
            app.VideoAnalysisToolkit.Position = [300 100 702 662];
            app.VideoAnalysisToolkit.Name = 'Video Analysis Toolkit';

            % Create GetintrinsicsButton
            app.GetintrinsicsButton = uibutton(app.VideoAnalysisToolkit, 'push');
            app.GetintrinsicsButton.ButtonPushedFcn = createCallbackFcn(app, @GetintrinsicsButtonPushed, true);
            app.GetintrinsicsButton.BackgroundColor = [0.8 0.8 0.8];
            app.GetintrinsicsButton.Position = [281 323 80 20];
            app.GetintrinsicsButton.Text = 'Get intrinsics';

            % Create Function1GetcameraintrinsicsLabel
            app.Function1GetcameraintrinsicsLabel = uilabel(app.VideoAnalysisToolkit);
            app.Function1GetcameraintrinsicsLabel.FontSize = 13;
            app.Function1GetcameraintrinsicsLabel.Position = [61 321 200 22];
            app.Function1GetcameraintrinsicsLabel.Text = 'Function 1: Get camera intrinsics';

            % Create Function2ElimatevideodistortionLabel
            app.Function2ElimatevideodistortionLabel = uilabel(app.VideoAnalysisToolkit);
            app.Function2ElimatevideodistortionLabel.FontSize = 13;
            app.Function2ElimatevideodistortionLabel.Position = [61 291 208 22];
            app.Function2ElimatevideodistortionLabel.Text = 'Function 2: Elimate video distortion';

            % Create Function4GetcarspeedLabel
            app.Function4GetcarspeedLabel = uilabel(app.VideoAnalysisToolkit);
            app.Function4GetcarspeedLabel.FontSize = 13;
            app.Function4GetcarspeedLabel.Position = [61 231 167 22];
            app.Function4GetcarspeedLabel.Text = 'Function 4: Get car speed';

            % Create CalibratevideoButton
            app.CalibratevideoButton = uibutton(app.VideoAnalysisToolkit, 'push');
            app.CalibratevideoButton.ButtonPushedFcn = createCallbackFcn(app, @CalibratevideoButtonPushed, true);
            app.CalibratevideoButton.BackgroundColor = [0.8 0.8 0.8];
            app.CalibratevideoButton.Position = [521 293 90 20];
            app.CalibratevideoButton.Text = 'Calibrate video';

            % Create GetextrinsicsButton
            app.GetextrinsicsButton = uibutton(app.VideoAnalysisToolkit, 'push');
            app.GetextrinsicsButton.ButtonPushedFcn = createCallbackFcn(app, @GetextrinsicsButtonPushed, true);
            app.GetextrinsicsButton.BackgroundColor = [0.8 0.8 0.8];
            app.GetextrinsicsButton.Position = [521 263 90 20];
            app.GetextrinsicsButton.Text = 'Get extrinsics';

            % Create Function3GetcameraextrinsicsLabel
            app.Function3GetcameraextrinsicsLabel = uilabel(app.VideoAnalysisToolkit);
            app.Function3GetcameraextrinsicsLabel.FontSize = 13;
            app.Function3GetcameraextrinsicsLabel.Position = [61 261 200 22];
            app.Function3GetcameraextrinsicsLabel.Text = 'Function 3: Get camera extrinsics';

            % Create WorkflowLabel
            app.WorkflowLabel = uilabel(app.VideoAnalysisToolkit);
            app.WorkflowLabel.FontSize = 15;
            app.WorkflowLabel.FontWeight = 'bold';
            app.WorkflowLabel.Position = [25 606 90 30];
            app.WorkflowLabel.Text = 'Workflow:';

            % Create SpeedCalculationModus
            app.SpeedCalculationModus = uiswitch(app.VideoAnalysisToolkit, 'slider');
            app.SpeedCalculationModus.Items = {'Pure Matlab', 'Hybrid'};
            app.SpeedCalculationModus.Position = [352 233 45 20];
            app.SpeedCalculationModus.Value = 'Pure Matlab';

            % Create GetcarspeedButton
            app.GetcarspeedButton = uibutton(app.VideoAnalysisToolkit, 'push');
            app.GetcarspeedButton.ButtonPushedFcn = createCallbackFcn(app, @GetcarspeedButtonPushed, true);
            app.GetcarspeedButton.BackgroundColor = [0.8 0.8 0.8];
            app.GetcarspeedButton.Position = [521 233 90 20];
            app.GetcarspeedButton.Text = 'Get car speed';

            % Create VideoAmount1
            app.VideoAmount1 = uiswitch(app.VideoAnalysisToolkit, 'slider');
            app.VideoAmount1.Items = {'Multi videos', 'Single video'};
            app.VideoAmount1.Position = [351 293 45 20];
            app.VideoAmount1.Value = 'Multi videos';

            % Create ExportvideoframeLabel
            app.ExportvideoframeLabel = uilabel(app.VideoAnalysisToolkit);
            app.ExportvideoframeLabel.FontSize = 13;
            app.ExportvideoframeLabel.Position = [61 105 115 22];
            app.ExportvideoframeLabel.Text = 'Export video frame';

            % Create ExportButton
            app.ExportButton = uibutton(app.VideoAnalysisToolkit, 'push');
            app.ExportButton.ButtonPushedFcn = createCallbackFcn(app, @ExportButtonPushed, true);
            app.ExportButton.BackgroundColor = [0.8 0.8 0.8];
            app.ExportButton.Position = [523 107 90 20];
            app.ExportButton.Text = 'Export';

            % Create VideoAmount2
            app.VideoAmount2 = uiswitch(app.VideoAnalysisToolkit, 'slider');
            app.VideoAmount2.Items = {'Multi videos', 'Single video'};
            app.VideoAmount2.Position = [353 107 45 20];
            app.VideoAmount2.Value = 'Multi videos';

            % Create CompareButton
            app.CompareButton = uibutton(app.VideoAnalysisToolkit, 'push');
            app.CompareButton.ButtonPushedFcn = createCallbackFcn(app, @CompareButtonPushed, true);
            app.CompareButton.BackgroundColor = [0.8 0.8 0.8];
            app.CompareButton.Position = [283 77 80 20];
            app.CompareButton.Text = 'Compare';

            % Create ComparedifferentframeLabel
            app.ComparedifferentframeLabel = uilabel(app.VideoAnalysisToolkit);
            app.ComparedifferentframeLabel.FontSize = 13;
            app.ComparedifferentframeLabel.Position = [61 75 146 22];
            app.ComparedifferentframeLabel.Text = 'Compare different frame';

            % Create Schachbrettmuster
            app.Schachbrettmuster = uibutton(app.VideoAnalysisToolkit, 'push');
            app.Schachbrettmuster.ButtonPushedFcn = createCallbackFcn(app, @SchachbrettmusterButtonPushed, true);
            app.Schachbrettmuster.BackgroundColor = [0.8 0.8 0.8];
            app.Schachbrettmuster.Position = [391 321 92 22];
            app.Schachbrettmuster.Text = 'Checkerboard';

            % Create CalculateButton
            app.CalculateButton = uibutton(app.VideoAnalysisToolkit, 'push');
            app.CalculateButton.ButtonPushedFcn = createCallbackFcn(app, @CalculateButtonPushed, true);
            app.CalculateButton.BackgroundColor = [0.8 0.8 0.8];
            app.CalculateButton.Position = [283 137 80 20];
            app.CalculateButton.Text = 'Calculate';

            % Create CalculatefieldofviewLabel
            app.CalculatefieldofviewLabel = uilabel(app.VideoAnalysisToolkit);
            app.CalculatefieldofviewLabel.FontSize = 13;
            app.CalculatefieldofviewLabel.Position = [61 135 131 22];
            app.CalculatefieldofviewLabel.Text = 'Calculate field of view';

            % Create MustHaveLabel
            app.MustHaveLabel = uilabel(app.VideoAnalysisToolkit);
            app.MustHaveLabel.FontSize = 14;
            app.MustHaveLabel.Position = [41 346 141 22];
            app.MustHaveLabel.Text = '- Must-Have -';

            % Create AdditionalLabel
            app.AdditionalLabel = uilabel(app.VideoAnalysisToolkit);
            app.AdditionalLabel.FontSize = 14;
            app.AdditionalLabel.Position = [41 165 141 22];
            app.AdditionalLabel.Text = '- Additional -';

            % Create MethodDropDownLabel
            app.MethodDropDownLabel = uilabel(app.VideoAnalysisToolkit);
            app.MethodDropDownLabel.HorizontalAlignment = 'right';
            app.MethodDropDownLabel.Position = [276 261 49 22];
            app.MethodDropDownLabel.Text = 'Method:';

            % Create MethodDropDown
            app.MethodDropDown = uidropdown(app.VideoAnalysisToolkit);
            app.MethodDropDown.Items = {'T-Calibration', '4 points'};
            app.MethodDropDown.ValueChangedFcn = createCallbackFcn(app, @MethodDropDownValueChanged, true);
            app.MethodDropDown.Position = [345 261 161 22];
            app.MethodDropDown.Value = '4 points';

            % Create Version37Updatedate15Aug2020Label
            app.Version37Updatedate15Aug2020Label = uilabel(app.VideoAnalysisToolkit);
            app.Version37Updatedate15Aug2020Label.FontSize = 13;
            app.Version37Updatedate15Aug2020Label.FontWeight = 'bold';
            app.Version37Updatedate15Aug2020Label.Position = [494 606 171 30];
            app.Version37Updatedate15Aug2020Label.Text = {'Version:         3.7'; 'Update date: 15. Aug. 2020'};

            % Create CalculateheightButton
            app.CalculateheightButton = uibutton(app.VideoAnalysisToolkit, 'push');
            app.CalculateheightButton.ButtonPushedFcn = createCallbackFcn(app, @CalculateheightButtonPushed, true);
            app.CalculateheightButton.BackgroundColor = [0.8 0.8 0.8];
            app.CalculateheightButton.Position = [513 47 102 20];
            app.CalculateheightButton.Text = 'Calculate height';

            % Create CalculatecameraheightLabel
            app.CalculatecameraheightLabel = uilabel(app.VideoAnalysisToolkit);
            app.CalculatecameraheightLabel.FontSize = 13;
            app.CalculatecameraheightLabel.Position = [61 45 146 22];
            app.CalculatecameraheightLabel.Text = 'Calculate camera height';

            % Create ExtrinsicsCalculationModus
            app.ExtrinsicsCalculationModus = uiswitch(app.VideoAnalysisToolkit, 'slider');
            app.ExtrinsicsCalculationModus.Items = {'4 points', 'T-Calibration'};
            app.ExtrinsicsCalculationModus.Position = [332 47 45 20];
            app.ExtrinsicsCalculationModus.Value = '4 points';

            % Create checkerboardprintedCheckBox
            app.checkerboardprintedCheckBox = uicheckbox(app.VideoAnalysisToolkit);
            app.checkerboardprintedCheckBox.Text = 'checkerboard printed?';
            app.checkerboardprintedCheckBox.Position = [52 526 142 22];

            % Create checkerboardcapturedCheckBox
            app.checkerboardcapturedCheckBox = uicheckbox(app.VideoAnalysisToolkit);
            app.checkerboardcapturedCheckBox.Text = 'checkerboard captured?';
            app.checkerboardcapturedCheckBox.Position = [52 506 151 22];

            % Create cameraintrinsicscomputedCheckBox
            app.cameraintrinsicscomputedCheckBox = uicheckbox(app.VideoAnalysisToolkit);
            app.cameraintrinsicscomputedCheckBox.Text = 'camera intrinsics computed?';
            app.cameraintrinsicscomputedCheckBox.Position = [52 486 175 22];

            % Create cameraextrinsicscomputedCheckBox
            app.cameraextrinsicscomputedCheckBox = uicheckbox(app.VideoAnalysisToolkit);
            app.cameraextrinsicscomputedCheckBox.Text = 'camera extrinsics computed?';
            app.cameraextrinsicscomputedCheckBox.Position = [52 426 178 22];

            % Create videocorrectedCheckBox
            app.videocorrectedCheckBox = uicheckbox(app.VideoAnalysisToolkit);
            app.videocorrectedCheckBox.Text = 'video corrected?';
            app.videocorrectedCheckBox.Position = [52 466 111 22];

            % Create vehicletrajectoryexportedCheckBox
            app.vehicletrajectoryexportedCheckBox = uicheckbox(app.VideoAnalysisToolkit);
            app.vehicletrajectoryexportedCheckBox.Text = 'vehicle trajectory exported?';
            app.vehicletrajectoryexportedCheckBox.Position = [52 406 169 22];

            % Create videoinDataFromSkyuploadedCheckBox
            app.videoinDataFromSkyuploadedCheckBox = uicheckbox(app.VideoAnalysisToolkit);
            app.videoinDataFromSkyuploadedCheckBox.Text = 'video in DataFromSky uploaded?';
            app.videoinDataFromSkyuploadedCheckBox.Position = [52 446 200 22];

            % Create speedcomputedCheckBox
            app.speedcomputedCheckBox = uicheckbox(app.VideoAnalysisToolkit);
            app.speedcomputedCheckBox.Text = 'speed computed?';
            app.speedcomputedCheckBox.Position = [52 386 118 22];

            % Create Button
            app.Button = uibutton(app.VideoAnalysisToolkit, 'push');
            app.Button.ButtonPushedFcn = createCallbackFcn(app, @ButtonPushed, true);
            app.Button.Position = [276 559 135 22];
            app.Button.Text = 'Generate your steps';

            % Create UITable
            app.UITable = uitable(app.VideoAnalysisToolkit);
            app.UITable.ColumnName = {'Step'; 'Content'};
            app.UITable.ColumnWidth = {40, 'auto'};
            app.UITable.RowName = {};
            app.UITable.Position = [263 371 410 177];

            % Create PreCheckLabel
            app.PreCheckLabel = uilabel(app.VideoAnalysisToolkit);
            app.PreCheckLabel.FontSize = 14;
            app.PreCheckLabel.Position = [41 570 141 22];
            app.PreCheckLabel.Text = '- Pre-Check -';

            % Create Function5GetTTCandPETLabel
            app.Function5GetTTCandPETLabel = uilabel(app.VideoAnalysisToolkit);
            app.Function5GetTTCandPETLabel.FontSize = 13;
            app.Function5GetTTCandPETLabel.Position = [61 201 177 22];
            app.Function5GetTTCandPETLabel.Text = 'Function 5: Get TTC and PET';

            % Create GetTTCandPETButton
            app.GetTTCandPETButton = uibutton(app.VideoAnalysisToolkit, 'push');
            app.GetTTCandPETButton.ButtonPushedFcn = createCallbackFcn(app, @GetTTCandPETButtonPushed, true);
            app.GetTTCandPETButton.BackgroundColor = [0.8 0.8 0.8];
            app.GetTTCandPETButton.Position = [281 201 112 22];
            app.GetTTCandPETButton.Text = 'Get TTC and PET';

            % Create ComputerVisionToolboxinstalledCheckBox
            app.ComputerVisionToolboxinstalledCheckBox = uicheckbox(app.VideoAnalysisToolkit);
            app.ComputerVisionToolboxinstalledCheckBox.Text = 'Computer Vision Toolbox installed?';
            app.ComputerVisionToolboxinstalledCheckBox.Position = [52 546 210 22];
        end
    end

    methods (Access = public)

        % Construct app
        function app = VideoAnalysisToolkit_v3_7_exported

            % Create and configure components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.VideoAnalysisToolkit)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.VideoAnalysisToolkit)
        end
    end
end