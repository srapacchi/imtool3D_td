classdef imtool3D < handle
    %This is a image slice viewer with built in scroll, contrast, zoom and
    %ROI tools. 
    %
    %   Use this class to place a self-contained image viewing panel within
    %   a GUI (or any figure). Similar to imtool but with slice scrolling.
    %   Only designed to view grayscale (intensity) images. Use the mouse
    %   to control how the image is displayed. A left click allows window
    %   and leveling, a right click is for panning, and a middle click is
    %   for zooming. Also the scroll wheel can be used to scroll through
    %   slices.
    %----------------------------------------------------------------------
    %Inputs:
    %
    %   I           An m x n x k image array of grayscale values. Default
    %               is a 100x100x3 random noise image.
    %   position    The position of the panel containing the image and all
    %               the tools. Format is [xmin ymin width height]. Default
    %               position is [0 0 1 1] (units = normalized). See the
    %               setPostion and setUnits methods to change the postion
    %               or units.
    %   h           Handle of the parent figure. If no handles is provided,
    %               a new figure will be created.
    %   range       The display range of the image. Format is [min max].
    %               The range can be adjusted with the contrast tool or
    %               with the setRange method. Default is [min(I) max(I)].
    %----------------------------------------------------------------------
    %Output:
    %
    %   tool        The imtool3D object. Use this object as input to the
    %               class methods described below.
    %----------------------------------------------------------------------
    %Constructor Syntax
    %
    %tool = imtool3d() creates an imtool3D panel in the current figure with
    %a random noise image. Returns the imtool3D object.
    %
    %tool = imtool3d(I) sets the image of the imtool3D panel.
    %
    %tool = imtool3D(I,position) sets the position of the imtool3D panel
    %within the current figure. The default units are normalized.
    %
    %tool = imtool3D(I,position,h) puts the imtool3D panel in the figure
    %specified by the handle h.
    %
    %tool = imtool3D(I,position,h,range) sets the display range of the
    %image according to range=[min max].
    %
    %tool = imtool3D(I,position,h,range,tools) lets the scroll wheel
    %properly sync if you are displaying multiple imtool3D objects in the
    %same figure.
    %
    %tool = imtool3D(I,position,h,range,tools,mask) allows you to overlay a
    %semitransparent binary mask on the image data.
    %
    %Note that you can pass an empty matrix for any input variable to have
    %the constructor use default values. ex. tool=imtool3D([],[],h,[]).
    %----------------------------------------------------------------------
    %Methods:
    %
    %   setImage(tool, I) displays a new image.
    %
    %   I = getImage(tool) returns the image being shown by the tool
    %
    %   setMask(tool,mask) replaces the overlay mask with a new one
    %
    %   setAlpha(tool,alpha) sets the transparency of the overlaid mask
    %
    %   alpha = getAlpha(tool) gets the current transparency of the
    %   overlaid mask
    %
    %   setPostion(tool,position) sets the position of tool.
    %
    %   position = getPosition(tool) returns the position of the tool
    %   relative to its parent figure.
    %
    %   setUnits(tool,Units) sets the units of the position of tool. See
    %   uipanel properties for possible unit strings.
    %
    %   units = getUnits(tool) returns the units of used for the position
    %   of the tool.
    %
    %   handles = getHandles(tool) returns a structured variable, handles,
    %   which contains all the handles to the various objects used by
    %   imtool3D.
    %
    %   setDisplayRange(tool,range) sets the display range of the image.
    %   see the 'Clim' property of an Axes object for details.
    %
    %   range=getDisplayRange(tool) returns the current display range of
    %   the image.
    %
    %   setWindowLevel(tool,W,L) sets the display range of the image in
    %   terms of its window (diff(range)) and level (mean(range)).
    %
    %   [W,L] = getWindowLevel(tool) returns the display range of the image
    %   in terms of its window (W) and level (L)
    %
    %   setCurrentSlice(tool,slice) sets the current displayed slice.
    %
    %   slice = getCurrentSlice(tool) returns the currently displayed
    %   slice number.
    %
    %----------------------------------------------------------------------
    %Notes:
    %
    %   Author: Justin Solomon, July, 26 2013 (Latest update April, 16,
    %   2016)
    %
    %   Contact: justin.solomon@duke.edu
    %
    %   Current Version 2.4
    %   Version Notes:
    %                   1.1-added method to get information about the
    %                   currently selected ROI.
    %
    %                   2.0- Completely redesigned the tool. Window and
    %                   leveleing, pan, and zoom are now done with the
    %                   mouse as is standard in most medical image viewers.
    %                   Also the overall astestic design of the tool is
    %                   improved with a new black theme. Added ability to
    %                   change the colormap of the image. Also when
    %                   resizing the figure, the tool behaves better and
    %                   maintains maximum viewing area for the image while
    %                   keeping the tool buttons correctly sized.
    %                   IMPORTANT: Any code that worked with the version
    %                   1.0 may not be compatible with version 2.0.
    %
    %                   2.1- Added crop tool, help button, and button that
    %                   resets the pan and zoom settings to show the entire
    %                   image (useful when you're zoomed in and you just
    %                   want to zoom out quickly. Also made the window and
    %                   level adjustable by draging the lines on the
    %                   histogram
    %
    %                   2.2- Added support for Matlab 2014b. Added ability
    %                   to overlay a semi-transparent binary mask on the
    %                   image data. Useful to visiulize segmented data.
    %
    %                   2.3- Simplified the ROI tools. imtool3D no longer
    %                   relies on MATLAB'S imroi classes, rather I've made
    %                   a set of ROI classes just for imtool3D. This
    %                   greatly simplifies the integration of the ROI
    %                   tools. You can export and delete the ROIs directly
    %                   from their context menus.
    %
    %                   2.3.1- Make sure the figure is centered when
    %                   creating an imtool3D object in a new figure
    % 
    %                   2.3.2- Squished a few bugs for older Matlab
    %                   versions. Added method to set and get the
    %                   transparency of the overlaid mask. Refined the
    %                   panning and zooming.
    %
    %                   2.3.3- Fixed a bug with the cropping function
    %
    %                   2.3.4- Added check box to toggle on and off the
    %                   mask overlay. Fixed a bug with the interactive
    %                   window and leveling using the histogram view. Added
    %                   a paint brush to allow user to quickly segment
    %                   something
    %
    %                   2.4- Added methods to get the min, max, and range
    %                   of pixel values. Updated the window and leveling to
    %                   be adaptive to the dynamic range of the image data.
    %                   Should work well if the range is small or large.
    %
    %                   2.4.1- fixed a small bug related to windowing with
    %                   the mouse.
    %
    %                   2.4.2- Added a "smart" paint brush which helps to
    %                   segment borders cleanly.
    %   
    %   Created in MATLAB_R2015b
    %
    %   Requires the image processing toolbox
    
    properties (SetAccess = private, GetAccess = private)
        I            %Image data (MxNxKxTxV) matrix of image data
        Nvol         % Current volume
        Ntime        % Current time
        range        % Range of images
        Climits      % Current color limits (Clim) to display images in I (cell)
        mask         %Indexed mask that can be overlaid on the image data
        maskHistory  %History of mask  for undo
        maskSelected %Index of the selected mask color
        lockMask     %Lock other mask colors
        maskColor    %Nx3 vector specifying the RGB color of the overlaid mask. Default is red (i.e., [1 0 0]);
        handles      %Structured variable with all the handles
        centers      %list of bin centers for histogram
        alpha        %transparency of the overlaid mask (default is .2)
        aspectRatio = [1 1 1];
        viewplane    = 3; % Direction of the 3rd dimension 
        
        
    end
    
    properties
        windowSpeed=2; %Ratio controls how fast the window and level change when you change them with the mouse
        upsample = false;
        upsampleMethod = 'lanczos3'; %Can be any of {'bilinear','bicubic','box','triangle','cubic','lanczos2','lanczos3'}
        Visible = true;              %lets the user hide the imtool3D panel
    end
    
    properties (Dependent = true)
        rescaleFactor %This is the screen pixels/image pixels. used to resample image data when being displayed
    end
    
    events
        newImage
        maskChanged
        maskUndone
        newMousePos
        newSlice
    end
     
    methods
        
        function tool = imtool3D(varargin)  %Constructor
            addpath(genpath(fullfile(fileparts(mfilename('fullpath')),'External')))
            addpath(genpath(fullfile(fileparts(mfilename('fullpath')),'src')))
            
            % Parse Inputs
            [I, position, h, range, tools, mask, enableHist] = parseinputs(varargin{:});
            
            % display figure
            if isempty(h)
                h=figure;
                set(h,'Toolbar','none','Menubar','none','NextPlot','new')
                set(h,'Units','Pixels');
                pos=get(h,'Position');
                Af=pos(3)/pos(4);   %input Ratio of the figure
                AI=size(I,2)/size(I,1); %input Ratio of the image
                if Af>AI    %Figure is too wide, make it taller to match
                   pos(4)=pos(3)/AI; 
                elseif Af<AI    %Figure is too long, make it wider to match
                    pos(3)=AI*pos(4);
                end
                
                %set minimal size
                pos(3)=max(600,pos(3));
                pos(4)=max(500,pos(4));
                
                %make sure the figure is centered
                screensize = get(0,'ScreenSize');
                pos(1) = ceil((screensize(3)-pos(3))/2);
                pos(2) = ceil((screensize(4)-pos(4))/2); 
                set(h,'Position',pos)
                set(h,'Units','normalized');
            end
                        
            %find the parent figure handle if the given parent is not a
            %figure
            if ~strcmp(get(h,'type'),'figure')
                fig = getParentFigure(h);
            else
                fig = h;
            end
            
            %--------------------------------------------------------------
            tool.lockMask = true;
            tool.handles.fig=fig;
            tool.handles.parent = h;
            tool.maskColor = [  0     0     0;
                                1     0     0;
                                1     1     0;
                                0     1     0;
                                0     1     1;
                                0     0     1;
                                1     0     1];
            tool.maskSelected = 1;
            tool.maskHistory  = cell(1,10);
            tool.alpha = .2;
            tool.Nvol = 1;
            tool.Ntime = 1;
            
            %Create the panels and slider
            w=30; %Pixel width of the side panels
            h=110; %Pixel height of the histogram panel
            wbutt=20; %Pixel size of the buttons
            tool.handles.Panels.Large   =   uipanel(tool.handles.parent,'Units','normalized','Position',position,'Title','','Tag','imtool3D'); 
            pos=getpixelposition(tool.handles.parent); pos(1) = pos(1)+position(1)*pos(3); pos(2) = pos(2)+position(2)*pos(4); pos(3) = pos(3)*position(3); pos(4) = pos(4)*position(4); 
            tool.handles.Panels.Hist   =   uipanel(tool.handles.Panels.Large,'Units','Pixels','Position',[w pos(4)-w-h pos(3)-2*w h],'Title','');
            tool.handles.Panels.Image   =   uipanel(tool.handles.Panels.Large,'Units','Pixels','Position',[w w pos(3)-2*w pos(4)-2*w],'Title','');
            tool.handles.Panels.Tools   =   uipanel(tool.handles.Panels.Large,'Units','Pixels','Position',[0 pos(4)-w pos(3) w],'Title','');
            tool.handles.Panels.ROItools    =   uipanel(tool.handles.Panels.Large,'Units','Pixels','Position',[pos(3)-w  w w pos(4)-2*w],'Title','');
            tool.handles.Panels.Slider  =   uipanel(tool.handles.Panels.Large,'Units','Pixels','Position',[0 w w pos(4)-2*w],'Title','');
            tool.handles.Panels.Info   =   uipanel(tool.handles.Panels.Large,'Units','Pixels','Position',[0 0 pos(3) w],'Title','');
            try
                set(cell2mat(struct2cell(tool.handles.Panels)),'BackgroundColor','k','ForegroundColor','w','HighlightColor','k')
            catch
                objarr=struct2cell(tool.handles.Panels);
                objarr=[objarr{:}];
                set(objarr,'BackgroundColor','k','ForegroundColor','w','HighlightColor','k');
            end
            
            
            %Create Slider for scrolling through image stack
            tool.handles.Slider         =   uicontrol(tool.handles.Panels.Slider,'Style','Slider','Units','Normalized','Position',[0 0 1 1],'TooltipString','Change Slice (can use scroll wheel also)');
            fun=@(scr,evnt)multipleScrollWheel(scr,evnt,[tool tools]);
            set(tool.handles.fig,'WindowScrollWheelFcn',fun);
           
            
            %Create image axis
            tool.handles.Axes           =   axes('Position',[0 0 1 1],'Parent',tool.handles.Panels.Image,'Color','none');
            tool.handles.I              =   imshow(zeros(3,3),[0 1],'Parent',tool.handles.Axes); hold on;
            set(tool.handles.I,'Clipping','off')
            view(tool.handles.Axes,-90,90);
            set(tool.handles.Axes,'XLimMode','manual','YLimMode','manual','Clipping','off');
            
            
            %Set up the binary mask viewer
            im = ind2rgb(zeros(3,3),tool.maskColor);
            tool.handles.mask           =   imshow(im);
            set(tool.handles.Axes,'Position',[0 0 1 1],'Color','none','XColor','r','YColor','r','GridLineStyle','--','LineWidth',1.5,'XTickLabel','','YTickLabel','');
            axis off
            grid off
            axis fill
            
            
            %Set up image info display
            tool.handles.Info=uicontrol(tool.handles.Panels.Info,'Style','text','String','(x,y) val','Units','Normalized','Position',[0 .1 .5 .8],'BackgroundColor','k','ForegroundColor','w','FontSize',12,'HorizontalAlignment','Left');
            fun=@(src,evnt)getImageInfo(src,evnt,tool);
            set(tool.handles.fig,'WindowButtonMotionFcn',fun);
            tool.handles.SliceText=uicontrol(tool.handles.Panels.Info,'Style','text','String',['Vol: 1/' num2str(size(I,5)) '    Time: 1/' num2str(size(I,4)) '    Slice: 1/' num2str(size(I,tool.viewplane))],'Units','Normalized','Position',[.5 .1 .48 .8],'BackgroundColor','k','ForegroundColor','w','FontSize',12,'HorizontalAlignment','Right');

            %Set up mouse button controls
            fun=@(hObject,eventdata) imageButtonDownFunction(hObject,eventdata,tool);
            set(tool.handles.mask,'ButtonDownFcn',fun)
            set(tool.handles.I,'ButtonDownFcn',fun)
            
            %create the tool buttons
            wp=w;
            w=wbutt;
            buff=(wp-w)/2;
            
            %Create the histogram plot
            %set(tool.handles.Panels.Image,'Visible','off')
            if enableHist
                tool.handles.HistAxes           =   axes('Position',[.025 .15 .95 .55],'Parent',tool.handles.Panels.Hist);
                tool.handles.HistLine=plot([0 1],[0 1],'-w','LineWidth',1);
                set(tool.handles.HistAxes,'Color','none','XColor','w','YColor','w','FontSize',9,'YTick',[])
                axis on
                hold on
                axis fill
                xlim(get(gca,'Xlim'))
                tool.handles.Histrange(1)=plot([0 0 0],[0 .5 1],'.-r');
                tool.handles.Histrange(2)=plot([1 1 1],[0 .5 1],'.-r');
                tool.handles.Histrange(3)=plot([0.5 0.5 0.5],[0 .5 1],'.--r');
                tool.handles.HistImageAxes           =   axes('Position',[.025 .75 .95 .2],'Parent',tool.handles.Panels.Hist);
                set(tool.handles.HistImageAxes,'Units','Pixels'); pos=get(tool.handles.HistImageAxes,'Position'); set(tool.handles.HistImageAxes,'Units','Normalized');
                tool.handles.HistImage=imshow(repmat(linspace(0,1,256),[round(pos(4)) 1]),[0 1]);
                set(tool.handles.HistImageAxes,'XColor','w','YColor','w','XTick',[],'YTick',[])
                axis on;
                box on;
                axis normal
                fun = @(hObject,evnt)histogramButtonDownFunction(hObject,evnt,tool,1);
                set(tool.handles.Histrange(1),'ButtonDownFcn',fun);
                fun = @(hObject,evnt)histogramButtonDownFunction(hObject,evnt,tool,2);
                set(tool.handles.Histrange(2),'ButtonDownFcn',fun);
                fun = @(hObject,evnt)histogramButtonDownFunction(hObject,evnt,tool,3);
                set(tool.handles.Histrange(3),'ButtonDownFcn',fun);
                
                %Create histogram checkbox
                tool.handles.Tools.Hist     =   uicontrol(tool.handles.Panels.Tools,'Style','Checkbox','String','Hist?','Position',[buff buff 2.5*w w],'TooltipString','Show Histogram','BackgroundColor','k','ForegroundColor','w');
                fun=@(hObject,evnt) ShowHistogram(hObject,evnt,tool,wp,h);
                set(tool.handles.Tools.Hist,'Callback',fun)
                lp=buff+2.5*w;
            else
                lp=buff;
            end
            
            %Set up the resize function
            fun=@(x,y) panelResizeFunction(x,y,tool,wp,h,wbutt);
            set(tool.handles.Panels.Large,'ResizeFcn',fun)

            
            %Create window and level boxes
            tool.handles.Tools.TL       =   uicontrol(tool.handles.Panels.Tools,'Style','text','String','L','Position',[lp+buff buff w w],'BackgroundColor','k','ForegroundColor','w','TooltipString','Window Width');
            tool.handles.Tools.L        =   uicontrol(tool.handles.Panels.Tools,'Style','Edit','String','0','Position',[lp+buff+w buff 2*w w],'TooltipString','Window Width','BackgroundColor',[.2 .2 .2],'ForegroundColor','w'); 
            tool.handles.Tools.TU       =   uicontrol(tool.handles.Panels.Tools,'Style','text','String','U','Position',[lp+2*buff+3*w buff w w],'BackgroundColor','k','ForegroundColor','w','TooltipString','Window Level');
            tool.handles.Tools.U        =   uicontrol(tool.handles.Panels.Tools,'Style','Edit','String','1','Position',[lp+2*buff+4*w buff 2*w w],'TooltipString','Window Level','BackgroundColor',[.2 .2 .2],'ForegroundColor','w');
            lp=lp+buff+7*w;
            
            %Creat window and level callbacks
            fun=@(hobject,evnt) WindowLevel_callback(hobject,evnt,tool);
            set(tool.handles.Tools.L,'Callback',fun);
            set(tool.handles.Tools.U,'Callback',fun);
            
            %Create view restore button
            tool.handles.Tools.ViewRestore           =   uicontrol(tool.handles.Panels.Tools,'Style','pushbutton','String','','Position',[lp buff w w],'TooltipString','Reset Pan and Zoom');
            [iptdir, MATLABdir] = ipticondir;
            icon_save = makeToolbarIconFromPNG([iptdir '/overview_zoom_in.png']);
            set(tool.handles.Tools.ViewRestore,'CData',icon_save);
            fun=@(hobject,evnt) resetViewCallback(hobject,evnt,tool);
            set(tool.handles.Tools.ViewRestore,'Callback',fun)
            lp=lp+w+2*buff;
            
            %Create grid checkbox and grid lines
            tool.handles.Tools.Grid           =   uicontrol(tool.handles.Panels.Tools,'Style','checkbox','String','Grid?','Position',[lp buff 2.5*w w],'BackgroundColor','k','ForegroundColor','w');
            nGrid=7;
            nMinor=4;
            x=linspace(1,size(I,2),nGrid);
            y=linspace(1,size(I,1),nGrid);
            hold(tool.handles.Axes, 'on');
            tool.handles.grid=[];
            gColor=[255 38 38]./256;
            mColor=[255 102 102]./256;
            for i=1:nGrid
                tool.handles.grid(end+1)=plot(tool.handles.Axes,[.5 size(I,2)-.5],[y(i) y(i)],'-','LineWidth',1.2,'HitTest','off','Color',gColor);
                tool.handles.grid(end+1)=plot(tool.handles.Axes,[x(i) x(i)],[.5 size(I,1)-.5],'-','LineWidth',1.2,'HitTest','off','Color',gColor);
                if i<nGrid
                    xm=linspace(x(i),x(i+1),nMinor+2); xm=xm(2:end-1);
                    ym=linspace(y(i),y(i+1),nMinor+2); ym=ym(2:end-1);
                    for j=1:nMinor
                        tool.handles.grid(end+1)=plot(tool.handles.Axes,[.5 size(I,2)-.5],[ym(j) ym(j)],'-r','LineWidth',.9,'HitTest','off','Color',mColor);
                        tool.handles.grid(end+1)=plot(tool.handles.Axes,[xm(j) xm(j)],[.5 size(I,1)-.5],'-r','LineWidth',.9,'HitTest','off','Color',mColor);
                    end
                end
            end
            tool.handles.grid(end+1)=scatter(tool.handles.Axes,.5+size(I,2)/2,.5+size(I,1)/2,'r','filled');
            set(tool.handles.grid,'Visible','off')
            fun=@(hObject,evnt) toggleGrid(hObject,evnt,tool);
            set(tool.handles.Tools.Grid,'Callback',fun)
            set(tool.handles.Tools.Grid,'TooltipString','Toggle Gridlines')
            lp=lp+2.5*w;
            
            %Create the mask view switch
            tool.handles.Tools.Mask           =   uicontrol(tool.handles.Panels.Tools,'Style','checkbox','String','Mask?','Position',[lp buff 3*w w],'BackgroundColor','k','ForegroundColor','w','TooltipString','Toggle Binary Mask','Value',1);
            fun=@(hObject,evnt) toggleMask(hObject,evnt,tool);
            set(tool.handles.Tools.Mask,'Callback',fun)
            lp=lp+3*w;
            
            %Create colormap pulldown menu
            mapNames={'Gray','Parula','Jet','HSV','Hot','Cool','Spring','Summer','Autumn','Winter','Bone','Copper','Pink','Lines','colorcube','flag','prism','white'};
            tool.handles.Tools.Color          =   uicontrol(tool.handles.Panels.Tools,'Style','popupmenu','String',mapNames,'Position',[lp buff 3.5*w w]);
            fun=@(hObject,evnt) changeColormap(hObject,evnt,tool);
            set(tool.handles.Tools.Color,'Callback',fun)
            set(tool.handles.Tools.Color,'TooltipString','Select a colormap')
            lp=lp+3.5*w+buff;
            
            %Create save button
            tool.handles.Tools.SaveOptions    =   uicontrol(tool.handles.Panels.Tools,'Style','popupmenu','String',{'Mask','Current slice','Whole stack'},'Position',[lp buff 3*w w]);
            lp=lp+3*w;
            tool.handles.Tools.Save           =   uicontrol(tool.handles.Panels.Tools,'Style','pushbutton','String','','Position',[lp buff w w]);
            lp=lp+w+buff;
            icon_save = makeToolbarIconFromPNG([MATLABdir '/file_save.png']);
            set(tool.handles.Tools.Save,'CData',icon_save);
            fun=@(hObject,evnt) saveImage(tool);
            set(tool.handles.Tools.Save,'Callback',fun)
            set(tool.handles.Tools.Save,'TooltipString','Save Mask or image as slice or tiff stack')
            
            %Create viewplane button
            tool.handles.Tools.ViewPlane    =   uicontrol(tool.handles.Panels.Tools,'Style','popupmenu','String',{'Axial','Sagittal','Coronal'},'Position',[lp buff 3.5*w w],'Value',4-tool.viewplane);
            lp=lp+3.5*w+buff;
            fun=@(hObject,evnt) setviewplane(tool,hObject);
            set(tool.handles.Tools.ViewPlane,'Callback',fun)
            
            %Create mask2poly button
            tool.handles.Tools.mask2poly             =   uicontrol(tool.handles.Panels.ROItools,'Style','pushbutton','String','','Position',[buff buff w w],'TooltipString','Mask2Poly');
            icon_profile = makeToolbarIconFromPNG([MATLABdir '/linkproduct.png']);
            set(tool.handles.Tools.mask2poly ,'Cdata',icon_profile)
            fun=@(hObject,evnt) mask2polyImageCallback(hObject,evnt,tool);
            set(tool.handles.Tools.mask2poly ,'Callback',fun)
            addlistener(tool,'newSlice',@tool.SliceEvents);

            %Create Circle ROI button
            tool.handles.Tools.CircleROI           =   uicontrol(tool.handles.Panels.ROItools,'Style','pushbutton','String','','Position',[buff buff+w w w],'TooltipString','Create Elliptical ROI');
            icon_ellipse = makeToolbarIconFromPNG([MATLABdir '/tool_shape_ellipse.png']);
            set(tool.handles.Tools.CircleROI,'Cdata',icon_ellipse)
            fun=@(hObject,evnt) measureImageCallback(hObject,evnt,tool,'ellipse');
            set(tool.handles.Tools.CircleROI,'Callback',fun)
            
            %Create Square ROI button
            tool.handles.Tools.SquareROI           =   uicontrol(tool.handles.Panels.ROItools,'Style','pushbutton','String','','Position',[buff buff+2*w w w],'TooltipString','Create Rectangular ROI');
            icon_rect = makeToolbarIconFromPNG([MATLABdir '/tool_shape_rectangle.png']);
            set(tool.handles.Tools.SquareROI,'Cdata',icon_rect)
            fun=@(hObject,evnt) measureImageCallback(hObject,evnt,tool,'rectangle');
            set(tool.handles.Tools.SquareROI,'Callback',fun)
            
            %Create Polygon ROI button
            tool.handles.Tools.PolyROI             =   uicontrol(tool.handles.Panels.ROItools,'Style','pushbutton','String','\_/','Position',[buff buff+3*w w w],'TooltipString','Create Polygon ROI');
            fun=@(hObject,evnt) measureImageCallback(hObject,evnt,tool,'polygon');
            set(tool.handles.Tools.PolyROI,'Callback',fun)
            
            %Create line profile button
            tool.handles.Tools.Ruler             =   uicontrol(tool.handles.Panels.ROItools,'Style','pushbutton','String','','Position',[buff buff+4*w w w],'TooltipString','Measure Distance');
            icon_distance = makeToolbarIconFromPNG([MATLABdir '/tool_line.png']);
            set(tool.handles.Tools.Ruler,'CData',icon_distance);
            fun=@(hObject,evnt) measureImageCallback(hObject,evnt,tool,'profile');
            set(tool.handles.Tools.Ruler,'Callback',fun)

            %Create smooth3 button
            tool.handles.Tools.smooth3             =   uicontrol(tool.handles.Panels.ROItools,'Style','pushbutton','String','','Position',[buff buff+5*w w w],'TooltipString','Smooth Mask in 3D');
            icon_profile = makeToolbarIconFromPNG(fullfile(fileparts(mfilename('fullpath')),'src','icon_smooth3.png'));
            set(tool.handles.Tools.smooth3 ,'Cdata',icon_profile)
            fun=@(hObject,evnt) smooth3Callback(hObject,evnt,tool);
            set(tool.handles.Tools.smooth3 ,'Callback',fun)

            %Create maskinterp button
            tool.handles.Tools.maskinterp             =   uicontrol(tool.handles.Panels.ROItools,'Style','pushbutton','String','','Position',[buff buff+6*w w w],'TooltipString','Interp Mask');
            icon_profile = makeToolbarIconFromPNG(fullfile(fileparts(mfilename('fullpath')),'src','icon_interpmask.png'));
            set(tool.handles.Tools.maskinterp ,'Cdata',icon_profile)
            fun=@(hObject,evnt) maskinterpImageCallback(hObject,evnt,tool);
            set(tool.handles.Tools.maskinterp ,'Callback',fun)

            %Create active countour button
            tool.handles.Tools.maskactivecontour             =   uicontrol(tool.handles.Panels.ROItools,'Style','pushbutton','String','','Position',[buff buff+7*w w w],'TooltipString','Active Contour 3D');
            icon_profile = makeToolbarIconFromPNG(fullfile(fileparts(mfilename('fullpath')),'src','icon_activecontour.png'));
            set(tool.handles.Tools.maskactivecontour ,'Cdata',icon_profile)
            fun=@(hObject,evnt) ActiveCountourCallback(hObject,evnt,tool);
            set(tool.handles.Tools.maskactivecontour ,'Callback',fun)
            addlistener(tool,'maskChanged',@tool.maskEvents);
            addlistener(tool,'maskUndone',@tool.maskEvents);

            %Paint brush tool button
            tool.handles.Tools.PaintBrush        = uicontrol(tool.handles.Panels.ROItools,'Style','togglebutton','String','','Position',[buff buff+8*w w w],'TooltipString','Paint Brush Tool');
            icon_profile = makeToolbarIconFromPNG([MATLABdir '/tool_data_brush.png']);
            set(tool.handles.Tools.PaintBrush ,'Cdata',icon_profile)
            fun=@(hObject,evnt) PaintBrushCallback(hObject,evnt,tool,'Normal');
            set(tool.handles.Tools.PaintBrush ,'Callback',fun)
            tool.handles.PaintBrushObject=[];
            
            %Smart Paint brush tool button
            tool.handles.Tools.SmartBrush        = uicontrol(tool.handles.Panels.ROItools,'Style','togglebutton','String','','Position',[buff buff+9*w w w],'TooltipString','Smart Brush Tool');
            icon_profile = makeToolbarIconFromPNG(fullfile(fileparts(mfilename('fullpath')),'src','tool_data_brush_smart.png'));
            set(tool.handles.Tools.SmartBrush ,'Cdata',icon_profile)
            fun=@(hObject,evnt) PaintBrushCallback(hObject,evnt,tool,'Smart');
            set(tool.handles.Tools.SmartBrush ,'Callback',fun)

            %undo mask button
            tool.handles.Tools.undoMask        = uicontrol(tool.handles.Panels.ROItools,'Style','pushbutton','String','','Position',[buff buff+10*w w w],'TooltipString','Undo');
            icon_profile = load([MATLABdir filesep 'undo.mat']);
            set(tool.handles.Tools.undoMask ,'Cdata',icon_profile.undoCData)
            fun=@(hObject,evnt) maskUndo(tool);
            set(tool.handles.Tools.undoMask ,'Callback',fun)

%             %Create poly tool button
%             tool.handles.Tools.mask2poly             =   uicontrol(tool.handles.Panels.ROItools,'Style','pushbutton','String','','Position',[buff buff+8*w w w],'TooltipString','mask2poly');
%             icon_profile = makeToolbarIconFromPNG([MATLABdir '/linkproduct.png']);
%             set(tool.handles.Tools.mask2poly ,'Cdata',icon_profile)
%             fun=@(hObject,evnt) CropImageCallback(hObject,evnt,tool);
%             set(tool.handles.Tools.mask2poly ,'Callback',fun)

            %Create Help Button
            pos=get(tool.handles.Panels.ROItools,'Position');
            tool.handles.Tools.Help             =   uicontrol(tool.handles.Panels.ROItools,'Style','pushbutton','String','?','Position',[buff pos(4)-w-buff w w],'TooltipString','Help with imtool3D');
            fun=@(hObject,evnt) displayHelp(hObject,evnt,tool);
            set(tool.handles.Tools.Help,'Callback',fun)
            
            % mask selection
            for islct=1:5
                tool.handles.Tools.maskSelected(islct)        = uicontrol(tool.handles.Panels.ROItools,'Style','togglebutton','String',num2str(islct),'Position',[buff pos(4)-w-buff-islct*w w w],'Tag','MaskSelected');
                set(tool.handles.Tools.maskSelected(islct) ,'Cdata',repmat(permute(tool.maskColor(islct+1,:)*tool.alpha+(1-tool.alpha)*[.4 .4 .4],[3 1 2]),w,w))
                set(tool.handles.Tools.maskSelected(islct) ,'Callback',@(hObject,evnt) setmaskSelected(tool,islct))
            end
            
            % lock mask
            tool.handles.Tools.maskLock        = uicontrol(tool.handles.Panels.ROItools,'Style','togglebutton','Position',[buff pos(4)-w-buff-(islct+1)*w w w], 'Value', 1, 'TooltipString', 'Lock all colors except selected one');
            icon_profile = makeToolbarIconFromPNG(fullfile(fileparts(mfilename('fullpath')),'src','icon_lock.png'));
            set(tool.handles.Tools.maskLock ,'Cdata',icon_profile)
            set(tool.handles.Tools.maskLock ,'Callback',@(hObject,evnt) setlockMask(tool))

            % mask statistics
            tool.handles.Tools.maskStats        = uicontrol(tool.handles.Panels.ROItools,'Style','togglebutton','Position',[buff pos(4)-w-buff-(islct+2)*w w w], 'Value', 1, 'TooltipString', 'Statistics');
            icon_hist = makeToolbarIconFromPNG([MATLABdir '/plottype-histogram.png']);
            icon_hist = min(1,max(0,imresize(icon_hist,[16 16])));
            set(tool.handles.Tools.maskStats ,'Cdata',icon_hist)
            set(tool.handles.Tools.maskStats ,'Callback',@(hObject,evnt) StatsCallback(hObject,evnt,tool))
            
            %Set font size of all the tool objects
            try
                set(cell2mat(struct2cell(tool.handles.Tools)),'FontSize',9,'Units','Pixels')
            catch
                objarr=struct2cell(tool.handles.Tools);
                objarr=[objarr{:}];
                set(objarr,'FontSize',9,'Units','Pixels')
            end
            
            set(tool.handles.fig,'NextPlot','new')
            
            % add shortcuts
            
            set(gcf,'Windowkeypressfcn', @(hobject, event) tool.shortcutCallback(event))
            
            %run the reset view callback
            resetViewCallback([],[],tool)
            
            % Enable/Disable buttons based on mask
            tool.maskEvents;
            
            % set Image
            setImage(tool, varargin{:})

        end
        
        function setPosition(tool,position)
            set(tool.handles.Panels.Large,'Position',position)
        end
        
        function position = getPosition(tool)
            position = get(tool.handles.Panels.Large,'Position');
        end
        
        function setUnits(tool,units)
            set(tool.handles.Panels.Large,'Units',units)
        end
        
        function units = getUnits(tool)
            units = get(tool.handles.Panels.Large,'Units');
        end
        
        function setMask(tool,mask)
            if islogical(mask)
                maskOld = tool.mask;
                maskOld(maskOld==tool.maskSelected)=0;
                if tool.lockMask
                    maskOld(mask & maskOld==0) = tool.maskSelected;
                else
                    maskOld(mask) = tool.maskSelected;
                end
                mask=maskOld;
            end
            tool.mask=mask;
            showSlice(tool)
            notify(tool,'maskChanged')
        end
        
        function mask = getMask(tool,all)
            if nargin<2, all=false; end
            if all
                mask = tool.mask;
            else
                mask = tool.mask==tool.maskSelected;
            end
        end
        
        function setmaskHistory(tool,mask)
            if ~isequal(mask,tool.maskHistory{end})
                tool.maskHistory{1} = mask;
                tool.maskHistory = circshift(tool.maskHistory,-1,2);
                if isempty(tool.maskHistory{end-1})
                    set(tool.handles.Tools.undoMask, 'Enable', 'off')
                else
                    set(tool.handles.Tools.undoMask, 'Enable', 'on')
                end
            end
        end
        
        function maskUndo(tool)
            if ~isempty(tool.maskHistory{end-1})
                tool.mask=tool.maskHistory{end-1};
                showSlice(tool)
                tool.maskHistory = circshift(tool.maskHistory,1,2);
                tool.maskHistory{1}=[];
            end
            if isempty(tool.maskHistory{end-1})
                set(tool.handles.Tools.undoMask, 'Enable', 'off')
            end
            notify(tool,'maskUndone')
        end
        
        function setmaskSelected(tool,islct)
            tool.maskSelected = islct;
            set(tool.handles.Tools.maskSelected(islct),'FontWeight','bold','FontSize',12,'ForegroundColor',[1 1 1]);
            set(tool.handles.Tools.maskSelected(setdiff(1:5,islct)),'FontWeight','normal','FontSize',9,'ForegroundColor',[0 0 0]);
            notify(tool,'maskChanged')
        end
        
        function setmaskstatistics(tool,current_object)
            persistent counter
                
            % if Mouse over Mask Selection button
            if ishandle(current_object) && strcmp(get(current_object,'Tag'),'MaskSelected')
                % Prevent too many calls: Limit to 1 call a second
                if isempty(counter)
                    counter = tic;
                else
                    t = toc(counter);
                    if t<1
                        return;
                    else
                        counter = tic;
                    end
                end

                % Get statistics
                I = tool.getImage;
                for ii=1:length(tool.handles.Tools.maskSelected)
                    mask_ii = tool.mask==ii;
                    I_ii = I(mask_ii);
                    mean_ii = mean(I_ii);
                    std_ii  = std(double(I_ii));
                    area_ii = sum(mask_ii(:));
                    str = [sprintf('%-12s%.2f\n','Mean:',mean_ii), ...
                        sprintf('%-12s%.2f\n','STD:',std_ii),...
                        sprintf('%-12s%i','Area:',area_ii) 'px'];
                    
                    set(tool.handles.Tools.maskSelected(ii),'TooltipString',str)
                end
            end
        end
        
        function setlockMask(tool)
            tool.lockMask = ~tool.lockMask;
            CData = get(tool.handles.Tools.maskLock,'CData');
            S = size(CData);
            CData = CData.*repmat(permute(([0.4 0.4 0.4]*(~tool.lockMask) + 1./[0.4 0.4 0.4]*tool.lockMask),[3 1 2]),S(1), S(2));
            set(tool.handles.Tools.maskLock,'CData',CData)
        end
        function setMaskColor(tool,maskColor)
            
            if ischar(maskColor)
                switch maskColor
                    case 'y'
                        maskColor = [1 1 0];
                    case 'm'
                        maskColor = [1 0 1];
                    case 'c'
                        maskColor = [0 1 1];
                    case 'r'
                        maskColor = [1 0 0];
                    case 'g'
                        maskColor = [0 1 0];
                    case 'b'
                        maskColor = [0 0 1];
                    case 'w'
                        maskColor = [1 1 1];
                    case 'k'
                        maskColor = [0 0 0];
                end
            end
            
            
            C = get(tool.handles.mask,'CData');
            C(:,:,1) = maskColor(1);
            C(:,:,2) = maskColor(2);
            C(:,:,3) = maskColor(3);
            set(tool.handles.mask,'CData',C);
            
        end
        
        function maskColor = getMaskColor(tool)
            maskColor = tool.maskColor;
        end
        
        function setImage(tool, varargin)
            [I, position, h, range, tools, mask, enablehist] = parseinputs(varargin{:});            
            
            if isempty(I)
                phantom3 = min(1,max(0,cat(5,phantom,1 - phantom, -phantom.^2+phantom)));
                I=rand([256 256 3 20 3])*.3+repmat(phantom3,[1 1 3 20 1]);
                tool.setAspectRatio([1/256 1/256 1/3]);
            end
            
            if iscell(I)
                if length(I)>1
                    I2 = nan(max(cell2mat(cellfun(@(x) size(x,1), I, 'uni', false))),...
                        max(cell2mat(cellfun(@(x) size(x,2), I, 'uni', false))),...
                        max(cell2mat(cellfun(@(x) size(x,3), I, 'uni', false))),...
                        max(cell2mat(cellfun(@(x) size(x,4), I, 'uni', false))),...
                        length(I));
                    for iii = 1:length(I)
                        I2(1:size(I{iii},1),1:size(I{iii},2),1:size(I{iii},3),1:size(I{iii},4),iii)=I{iii};
                    end
                    I = I2;
                    clear I2;
                else
                    I = I{1};
                end
            end
            
            if islogical(I)
                range = [0 1];
            end

            if iscell(range)
                tool.range = range;
                range = range{1};
            else
                for ivol = 1:size(I,5)
                    if size(I,5)>1
                        Ivol = I(:,:,:,:,ivol);
                    else % no need to copy variable
                        Ivol = I;
                    end
                    tool.range{ivol}=double(range_outlier(Ivol(:),5));
                end
            end
            tool.Climits = tool.range;
            
            if ~isempty(range)
                tool.Climits{1} = range;
            end
            range = tool.Climits{1};
            
            if isempty(mask)
                mask=false([size(I,1) size(I,2) size(I,3)]);
            end
                        
            tool.I=I;
            tool.mask=uint8(mask);
            
            tool.Nvol = 1;

            %Update the histogram
            if isfield(tool.handles,'HistAxes')
                if size(I,5)>1
                    Ivol=I(:,:,:,:,tool.Nvol);
                else
                    Ivol = I;
                end
                Ivol = Ivol(unique(round(linspace(1,numel(Ivol),min(5000,numel(Ivol)))))); 
                Ivol = Ivol(Ivol>min(Ivol) & Ivol<max(Ivol));
                if isempty(Ivol), Ivol=0; end
                tool.centers=linspace(range(1)-diff(range)*0.05,range(2)+diff(range)*0.05,256);
                nelements=hist(Ivol(Ivol~=min(Ivol(:)) & Ivol~=max(Ivol(:))),tool.centers); nelements=nelements./max(nelements);
                set(tool.handles.HistLine,'XData',tool.centers,'YData',nelements);
                pos=getpixelposition(tool.handles.HistImageAxes);
                set(tool.handles.HistImage,'CData',repmat(tool.centers,[round(pos(4)) 1]));
                try
                    xlim(tool.handles.HistAxes,[tool.centers(1) tool.centers(end)])
                catch
                    xlim(tool.handles.HistAxes,[tool.centers(1) tool.centers(end)+.1])
                end
                axis fill
            end
            %Update the window and level
            setWL(tool,diff(range),mean(range))

            %Update the image
            %set(tool.handles.I,'CData',im)
            switch tool.viewplane
                case 1
                    xlim(tool.handles.Axes,[0 size(I,3)])
                    ylim(tool.handles.Axes,[0 size(I,2)])
                    set(tool.handles.I,'XData',[1 max(2,size(I,3))]);
                    set(tool.handles.I,'YData',[1 max(2,size(I,2))]);
                case 2
                    xlim(tool.handles.Axes,[0 size(I,3)])
                    ylim(tool.handles.Axes,[0 size(I,1)])
                    set(tool.handles.I,'XData',[1 max(2,size(I,3))]);
                    set(tool.handles.I,'YData',[1 max(2,size(I,1))]);
                case 3
                    xlim(tool.handles.Axes,[0 size(I,2)])
                    ylim(tool.handles.Axes,[0 size(I,1)])
                    set(tool.handles.I,'XData',[1 max(2,size(I,2))]);
                    set(tool.handles.I,'YData',[1 max(2,size(I,1))]);
            end
            
            %update the mask cdata (in case it has changed size)
            C=zeros(size(I,1),size(I,2),3);
            C(:,:,1)=tool.maskColor(1); C(:,:,2)=tool.maskColor(2); C(:,:,3)=tool.maskColor(3);
            set(tool.handles.mask,'CData',C);
            
            %Update the slider
            setupSlider(tool)
            
            %Update the TIme
            tool.Ntime = min(tool.Ntime,size(I,4));
            
            %Update the gridlines
            setupGrid(tool)
            
            %Show the first slice
            showSlice(tool)
            
            %Broadcast that the image has been updated
            notify(tool,'newImage')
            notify(tool,'maskChanged')
            
            
        end
        
        function I = getImage(tool,all)
            if nargin<2, all=false; end
            if all
                I=tool.I;
            else
                I=tool.I(:,:,:,tool.Ntime,tool.Nvol);
            end
        end

        function Nvol = getNvol(tool)
            Nvol=tool.Nvol;
        end

        function setNvol(tool,Nvol)
            % save window and level
            tool.setClimits(get(tool.handles.Axes,'Clim'))
            % change Volume
            tool.Nvol = max(1,min(Nvol,size(tool.I,5)));
            % load new window and level
            NewRange = tool.Climits{tool.Nvol};
            W=NewRange(2)-NewRange(1); L=mean(NewRange);
            tool.setWL(W,L);
            % apply xlim to histogram
            range = tool.range{tool.Nvol};
            tool.centers = linspace(range(1)-diff(range)*0.05,range(2)+diff(range)*0.05,256);
            if isfield(tool.handles,'HistAxes')
                try
                    xlim(tool.handles.HistAxes,[tool.centers(1) tool.centers(end)])
                catch
                    xlim(tool.handles.HistAxes,[tool.centers(1) tool.centers(end)+.1])
                end
                set(tool.handles.HistImageAxes,'Units','Pixels'); pos=get(tool.handles.HistImageAxes,'Position'); set(tool.handles.HistImageAxes,'Units','Normalized');
                set(tool.handles.HistImage,'CData',repmat(tool.centers,[round(pos(4)) 1]));
            end
            showSlice(tool);
        end

        function r = getrange(tool)
            r=diff(tool.range{tool.Nvol});
        end

        function setClimits(tool,range)
            if iscell(range)
                tool.Climits = range;
            else
                tool.Climits{tool.getNvol} = range;
            end
        end

        function Climits = getClimits(tool)
            Climits = tool.Climits;
        end

        function Nt = getNtime(tool)
            Nt=tool.Ntime;
        end
                
        function m = max(tool)
            m = max(tool.I(:));
        end
        
        function m = min(tool)
            m = min(tool.I(:));
        end
                
        function handles=getHandles(tool)
            handles=tool.handles;
        end
        
        function setAspectRatio(tool,psize)
            %This sets the proper aspect ratio of the viewer for cases
            %where you have non-square pixels
            tool.aspectRatio = psize;
            switch tool.viewplane
                case 1
                    aspectRatio = tool.aspectRatio([2 3 1]);
                case 2
                    aspectRatio = tool.aspectRatio([1 3 2]);
                case 3
                    aspectRatio = tool.aspectRatio([1 2 3]);
            end
            set(tool.handles.Axes,'DataAspectRatio',aspectRatio)
        end
        
        function setviewplane(tool,dim)
            if isa(dim,'matlab.ui.control.UIControl') % called from the button
                hObject = dim;
                set(hObject, 'Enable', 'off');
                drawnow;
                set(hObject, 'Enable', 'on');
                dim = get(hObject,'String'); 
                dim=dim{get(hObject,'Value')}; 
            end
            
            if ischar(dim)
                switch lower(dim)
                    case 'sagittal'
                        dim=1;
                    case 'coronal'
                        dim=2;
                    otherwise
                        dim=3;
                end
            end
            tool.viewplane = min(3,max(1,round(dim)));
            showSlice(tool,round(size(tool.I,dim)/2))
            switch dim
                case 1
                    xlim(tool.handles.Axes,[0 size(tool.I,3)])
                    ylim(tool.handles.Axes,[0 size(tool.I,2)])
                    set(tool.handles.I,'XData',[1 max(2,size(tool.I,3))]);
                    set(tool.handles.I,'YData',[1 max(2,size(tool.I,2))]);
                case 2
                    xlim(tool.handles.Axes,[0 size(tool.I,3)])
                    ylim(tool.handles.Axes,[0 size(tool.I,1)])
                    set(tool.handles.I,'XData',[1 max(2,size(tool.I,3))]);
                    set(tool.handles.I,'YData',[1 max(2,size(tool.I,1))]);
                case 3
                    xlim(tool.handles.Axes,[0 size(tool.I,2)])
                    ylim(tool.handles.Axes,[0 size(tool.I,1)])
                    set(tool.handles.I,'XData',[1 max(2,size(tool.I,2))]);
                    set(tool.handles.I,'YData',[1 max(2,size(tool.I,1))]);
            end
            setupSlider(tool)
            setupGrid(tool)
            
            switch dim
                case 1
                    dim = 'Sagittal';
                case 2
                    dim = 'Coronal';
                case 3
                    dim = 'Axial';
            end
            S = get(tool.handles.Tools.ViewPlane,'String');
            set(tool.handles.Tools.ViewPlane,'Value',find(strcmpi(S,dim)));

            % permute aspect ratio
            setAspectRatio(tool,tool.aspectRatio)
        end
        
        function setDisplayRange(tool,range)
            W=diff(range);
            L=mean(range);
            setWL(tool,W,L);
        end
        
        function range=getDisplayRange(tool)
            range=get(tool.handles.Axes,'Clim');
        end
        
        function setWindowLevel(tool,W,L)
            setWL(tool,W,L);
        end
        
        function [W,L] = getWindowLevel(tool)
            range=get(tool.handles.Axes,'Clim');
            W=diff(range);
            L=mean(range);
        end
        
        function setCurrentSlice(tool,slice)
            showSlice(tool,slice)
        end
        
        function slice = getCurrentSlice(tool)
            slice=round(get(tool.handles.Slider,'value'));
        end
                
        function mask = getCurrentMaskSlice(tool,all)
            if ~exist('all','var'), all=0; end
            slice = getCurrentSlice(tool);
            switch tool.viewplane
                case 1
                    mask=tool.mask(slice,:,:);
                case 2
                    mask=tool.mask(:,slice,:);
                case 3
                    mask=tool.mask(:,:,slice);
            end
            
            if ~all
                mask = mask==tool.maskSelected;
            end
            mask = squeeze(mask);
        end
        
        function setCurrentMaskSlice(tool,mask,combine)
            if ~exist('combine','var'), combine=false; end
            slice = getCurrentSlice(tool);
            maskOld = getCurrentMaskSlice(tool,1);
            % combine mask
            if ~combine
                maskOld(maskOld==tool.maskSelected)=0;
            end
            if tool.lockMask
                maskOld(mask & maskOld==0) = tool.maskSelected;
            else
                maskOld(mask) = tool.maskSelected;
            end
            % update mask
            switch tool.viewplane
                case 1
                    tool.mask(slice,:,:) = maskOld;
                case 2
                    tool.mask(:,slice,:) = maskOld;
                case 3
                    tool.mask(:,:,slice) = maskOld;
            end
            notify(tool,'maskChanged')
            showSlice(tool,slice)
        end
        
        function im = getCurrentImageSlice(tool)
            slice = getCurrentSlice(tool);
            switch tool.viewplane
                case 1
                    im = tool.I(slice,:,:,tool.Ntime,tool.Nvol);
                case 2
                    im = tool.I(:,slice,:,tool.Ntime,tool.Nvol);
                case 3
                    im = tool.I(:,:,slice,tool.Ntime,tool.Nvol);
            end
            im = squeeze(im);
        end
        
        function setAlpha(tool,alpha)
            if alpha <=1 && alpha >=0
                tool.alpha = alpha;
                slice = getCurrentSlice(tool);
                showSlice(tool,slice)
            else
                warning('Alpha value should be between 0 and 1')
            end
        end
        
        function alpha = getAlpha(tool)
            alpha = tool.alpha;
        end
        
        function S = getImageSize(tool)
            S=size(tool.I);
            switch tool.viewplane
                case 1
                    S = S([2 3 1]);
                case 2
                    S = S([1 3 2]);
            end
        end
        
        function addImageValues(tool,im,lims)
            %this function adds im to the image at location specified by
            %lims . Lims defines the box in which the new data, im, will be
            %inserted. lims = [ymin ymax; xmin xmax; zmin zmax];
            
            tool.I(lims(1,1):lims(1,2),lims(2,1):lims(2,2),lims(3,1):lims(3,2),tool.Ntime,tool.Nvol)=...
                tool.I(lims(1,1):lims(1,2),lims(2,1):lims(2,2),lims(3,1):lims(3,2),tool.Ntime,tool.Nvol)+im;
            showSlice(tool);
        end
        
        function replaceImageValues(tool,im,lims)
            %this function replaces pixel values with im at location specified by
            %lims . Lims defines the box in which the new data, im, will be
            %inserted. lims = [ymin ymax; xmin xmax; zmin zmax];
            tool.I(lims(1,1):lims(1,2),lims(2,1):lims(2,2),lims(3,1):lims(3,2),tool.Ntime,tool.Nvol)=im;
            showSlice(tool);
        end
        
        function im = getImageValues(tool,lims)
            im = tool.I(lims(1,1):lims(1,2),lims(2,1):lims(2,2),lims(3,1):lims(3,2));
        end
        
        function im = getImageSlices(tool,zmin,zmax)
            S = getImageSize(tool);
            switch tool.viewplane
                case 1
                    lims = [zmin zmax; 1 S(2); 1 S(3)];
                case 2
                    lims = [1 S(1); zmin zmax; 1 S(3)];
                case 3
                    lims = [1 S(1); 1 S(2); zmin zmax];
            end
            im = getImageValues(tool,lims);
        end
        
        function createBrushObject(tool,style)
            switch style
                case 'Normal'
                    tool.handles.PaintBrushObject=maskPaintBrush(tool);
                case 'Smart'
                    tool.handles.PaintBrushObject=maskSmartBrush(tool);
            end
        end
        
        function removeBrushObject(tool)
            try
                delete(tool.handles.PaintBrushObject)
            end
            tool.handles.PaintBrushObject=[];
        end
        
        function delete(tool)
            try
                delete(tool.handles.Panels.Large)
            end
        end
        
        function [xi,yi,zi]=getCurrentMouseLocation(tool)
            pos=round(get(tool.handles.Axes,'CurrentPoint'));
            pos=pos(1,1:2); xi=max(1,pos(1)); yi=max(1,pos(2)); zi=getCurrentSlice(tool);
        end
        
        function rescaleFactor = get.rescaleFactor(tool)
            %Get aspect ratio of image as currently being displayed
            w = diff(get(tool.handles.Axes,'Xlim'))+1;
            h = diff(get(tool.handles.Axes,'Ylim'))+1;
            Ai  = w/h;
            
            %Get aspect ratio of parent axes
            pos = getPixelPosition(tool.handles.Axes);
            Aa = pos(3)/pos(4);
            
            %get the rescale factor
            if Aa>=Ai
                rescaleFactor = pos(4)/h;
            else
                rescaleFactor = pos(3)/w;
            end
            
            
        end
        
        function set.upsample(tool,upsample)
            tool.upsample = logical(upsample);
            showSlice(tool);
        end
        
        function set.upsampleMethod(tool,upsampleMethod)
            switch upsampleMethod
                case {'bilinear','bicubic','box','triangle','cubic','lanczos2','lanczos3'}
                    tool.upsampleMethod = upsampleMethod;
                otherwise
                    warning(['Upsample method ''' upsampleMethod ''' not valid, using bilinear']);
                    tool.upsampleMethod = 'bilinear';
            end
            showSlice(tool);
        end
        
        function set.Visible(tool,Visible)
            if Visible
                set(tool.handles.Panels.Large,'Visible','on');
            else
                set(tool.handles.Panels.Large,'Visible','off');
            end
        end

        function shortcutCallback(tool,evnt)
            switch evnt.Key
                case 'space'
                    togglebutton(tool.handles.Tools.Mask)
                case 'b'
                    togglebutton(tool.handles.Tools.PaintBrush)
                case 's'
                    togglebutton(tool.handles.Tools.SmartBrush)
                case 'z'
                    maskUndo(tool);
                case 'l'
                    setlockMask(tool)
                case 'leftarrow'
                    tool.Ntime = max(tool.Ntime-1,1);
                    showSlice(tool);
                case 'rightarrow'
                    tool.Ntime = min(tool.Ntime+1,size(tool.I,4));
                    showSlice(tool);
                case 'uparrow'
                    setNvol(tool,tool.Nvol+1)
                case 'downarrow'
                    setNvol(tool,tool.Nvol-1)
                 otherwise
                    switch evnt.Character
                        case '1'
                            togglebutton(tool.handles.Tools.maskSelected(1))
                        case '2'
                            togglebutton(tool.handles.Tools.maskSelected(2))
                        case '3'
                            togglebutton(tool.handles.Tools.maskSelected(3))
                        case '4'
                            togglebutton(tool.handles.Tools.maskSelected(4))
                        case '5'
                            togglebutton(tool.handles.Tools.maskSelected(5))
                    end
            end
            %      disp(evnt.Key)
        end
        
        function saveImage(tool)
            h = tool.getHandles;
            cmap = colormap(h.Tools.Color.String{h.Tools.Color.Value});
            S = get(h.Tools.SaveOptions,'String');
            switch S{get(h.Tools.SaveOptions,'value')}
                case 'Current slice' %Save just the current slice
                    I=get(h.I,'CData'); 
                    viewtype = get(tool.handles.Axes,'View');
                    if viewtype(1)==-90, I=rot90(I);  end
                    lims=get(h.Axes,'CLim');
                    I=gray2ind(mat2gray(I,lims),size(cmap,1));
                    [FileName,PathName] = uiputfile({'*.png';'*.tif';'*.jpg';'*.bmp';'*.gif';'*.hdf'; ...
                        '*.jp2';'*.pbm';'*.pcx';'*.pgm'; ...
                        '*.pnm';'*.ppm';'*.ras';'*.xwd'},'Save Image');
                    
                    if FileName == 0
                    else
                        imwrite(cat(2,I,repmat(round(linspace(size(cmap,1),0,size(I,1)))',[1 round(size(I,2)/50)])),cmap,[PathName FileName])
                    end
                case 'Whole stack'
                    lims=get(h.Axes,'CLim');
                    [FileName,PathName] = uiputfile({'*.tif'},'Save Image Stack');
                    if FileName == 0
                    else
                        I = tool.getImage;
                        viewtype = get(tool.handles.Axes,'View');
                        if viewtype(1)==-90, I=rot90(I);  end

                        for z=1:size(I,tool.viewplane)
                            switch tool.viewplane
                                case 1
                                    Iz = I(z,:,:);
                                case 2
                                    Iz = I(:,z,:);
                                case 3
                                    Iz = I(:,:,z);
                            end
                            imwrite(gray2ind(mat2gray(Iz,lims),size(cmap,1)),cmap, [PathName FileName], 'WriteMode', 'append',  'Compression','none');
                        end
                    end
                case 'Mask'
                    [FileName,PathName, ext] = uiputfile({'*.nii.gz';'*.mat'},'Save Mask','Mask');
                    if ext==1 % .nii.gz
                        err=1;
                        while(err)
                            answer = inputdlg2({'save as:','browse reference scan'},'save mask',[1 50],{fullfile(PathName,FileName), ''});
                            if isempty(answer), err=0; break; end
                            if ~isempty(answer{1})
                                answer{1} = strrep(answer{1},'.gz','.nii.gz');
                                answer{1} = strrep(answer{1},'.nii.nii','.nii');
                                if ~isempty(answer{2})
                                    try
                                        save_nii_v2(tool.getMask(1),answer{1},answer{2},8);
                                        err=0;
                                    catch bug
                                        uiwait(warndlg(bug.message,'wrong reference','modal'))
                                    end
                                else
                                    save_nii_v2(make_nii(uint8(tool.getMask(1))),answer{1},[],8);
                                    err=0;
                                end
                            end
                        end
                    elseif ext==2 % .mat
                        Mask = tool.getMask(1);
                        save(fullfile(PathName,FileName),'Mask');
                    end
            end
        end
    end
    
    methods (Access = private)
                
        function showSlice(varargin)
            switch nargin
                case 1
                    tool=varargin{1};
                    n=round(get(tool.handles.Slider,'value'));
                case 2
                    tool=varargin{1};
                    n=varargin{2};
                    set(tool.handles.Slider,'value',n);
                otherwise
                    tool=varargin{1};
                    n=round(get(tool.handles.Slider,'value'));    
            end
            
            if n < 1
                n=1;
            end
            
            if n > size(tool.I,tool.viewplane)
                n=size(tool.I,tool.viewplane);
            end
            
            set(tool.handles.I,'AlphaData',1)
            In = squeeze(tool.getCurrentImageSlice);
            maskn = squeeze(tool.getCurrentMaskSlice(1));
            
            if ~tool.upsample
                set(tool.handles.I,'CData',In)
            else
                set(tool.handles.I,'CData',imresize(In,tool.rescaleFactor,tool.upsampleMethod),'XData',get(tool.handles.I,'XData'),'YData',get(tool.handles.I,'YData'))
            end
            maskrgb = ind2rgb(maskn,tool.maskColor);
            set(tool.handles.mask,'CData',maskrgb);
            set(tool.handles.mask,'AlphaData',tool.alpha*logical(maskn))
            set(tool.handles.SliceText,'String',['Vol: ' num2str(tool.Nvol) '/' num2str(size(tool.I,5)) '    Time: ' num2str(tool.Ntime) '/' num2str(size(tool.I,4)) '    Slice: ' num2str(n) '/' num2str(size(tool.I,tool.viewplane))])

            if isfield(tool.handles.Tools,'Hist') && get(tool.handles.Tools.Hist,'value')
                maskrgb=In;
                range = tool.range{tool.Nvol};
                maskrgb(maskrgb<range(1) | maskrgb>range(2)) = [];
                err = (max(maskrgb(:)) - min(maskrgb(:)))*1e-10;
                nelements=hist(maskrgb(maskrgb>(min(maskrgb(:))+err) & maskrgb<max(maskrgb(:)-err)),tool.centers); nelements=nelements./max(nelements);
                set(tool.handles.HistLine,'YData',nelements);
                set(tool.handles.HistLine,'XData',tool.centers);
            end
           
            notify(tool,'newSlice')
            
        end
        
        function setupSlider(tool)
            n=size(tool.I,tool.viewplane);
            if n==1
                set(tool.handles.Slider,'visible','off');
            else
                set(tool.handles.Slider,'visible','on');
                set(tool.handles.Slider,'SliderStep',[1/(size(tool.I,tool.viewplane)-1) 1/(size(tool.I,tool.viewplane)-1)])
                fun=@(hobject,eventdata)showSlice(tool,[],hobject,eventdata);
                set(tool.handles.Slider,'Callback',fun);
            end
            set(tool.handles.Slider,'min',1,'max',size(tool.I,tool.viewplane));
            if get(tool.handles.Slider,'value')==0 || get(tool.handles.Slider,'value')>n
                currentslice = round(size(tool.I,tool.viewplane)/2);
            else
                currentslice = get(tool.handles.Slider,'value');
            end    
            set(tool.handles.Slider,'value',currentslice)
        end
        
        function setupGrid(tool)
            %Update the gridlines
            delete(tool.handles.grid)
            nGrid=7;
            nMinor=4;
            posdim = setdiff(1:3,tool.viewplane);
            x=linspace(1,size(tool.I,posdim(2)),nGrid);
            y=linspace(1,size(tool.I,posdim(1)),nGrid);
            hold on;
            tool.handles.grid=[];
            gColor=[255 38 38]./256;
            mColor=[255 102 102]./256;
            for i=1:nGrid
                tool.handles.grid(end+1)=plot([.5 size(tool.I,posdim(2))-.5],[y(i) y(i)],'-','LineWidth',1.2,'HitTest','off','Color',gColor,'Parent',tool.handles.Axes);
                tool.handles.grid(end+1)=plot([x(i) x(i)],[.5 size(tool.I,posdim(1))-.5],'-','LineWidth',1.2,'HitTest','off','Color',gColor,'Parent',tool.handles.Axes);
                if i<nGrid
                    xm=linspace(x(i),x(i+1),nMinor+2); xm=xm(2:end-1);
                    ym=linspace(y(i),y(i+1),nMinor+2); ym=ym(2:end-1);
                    for j=1:nMinor
                        tool.handles.grid(end+1)=plot([.5 size(tool.I,posdim(2))-.5],[ym(j) ym(j)],'-r','LineWidth',.9,'HitTest','off','Color',mColor,'Parent',tool.handles.Axes);
                        tool.handles.grid(end+1)=plot([xm(j) xm(j)],[.5 size(tool.I,posdim(1))-.5],'-r','LineWidth',.9,'HitTest','off','Color',mColor,'Parent',tool.handles.Axes);
                    end
                end
            end
            tool.handles.grid(end+1)=scatter(.5+size(tool.I,posdim(2))/2,.5+size(tool.I,posdim(1))/2,'r','filled','Parent',tool.handles.Axes);

            if get(tool.handles.Tools.Grid,'Value')
                set(tool.handles.grid,'Visible','on')
            else
                set(tool.handles.grid,'Visible','off')
            end
        end
        
        function setWL(tool,W,L)
            try
                set(tool.handles.Axes,'Clim',[L-W/2 L+W/2])
                set(tool.handles.Tools.L,'String',num2str(L-W/2));
                set(tool.handles.Tools.U,'String',num2str(L+W/2));
                set(tool.handles.HistImageAxes,'Clim',[L-W/2 L+W/2])
                set(tool.handles.Histrange(1),'XData',[L-W/2 L-W/2 L-W/2])
                set(tool.handles.Histrange(2),'XData',[L+W/2 L+W/2 L+W/2])
                set(tool.handles.Histrange(3),'XData',[L L L])
            end
        end
             
        function maskEvents(tool,src,evnt)            
            % Enable/Disable buttons
            [x,y,z] = find3d(tool.mask==tool.maskSelected);
            switch tool.viewplane
                case 1
                    z=x;
                case 2
                    z=y;
            end
            
            z = unique(z);
            if length(z)>1 && length(z)<(max(z)-min(z)+1)% if more than mask on more than 2 slices and holes
                set(tool.handles.Tools.maskinterp,'Enable','on')
            else
                set(tool.handles.Tools.maskinterp,'Enable','off')
            end
            
            if length(z)>1 && any(diff(z)==1)
                set(tool.handles.Tools.smooth3,'Enable','on')
            else
                set(tool.handles.Tools.smooth3,'Enable','off')
            end
            
            if ~isempty(z)
                set(tool.handles.Tools.maskactivecontour,'Enable','on')
            else
                set(tool.handles.Tools.maskactivecontour,'Enable','off')
            end
            if ~exist('evnt','var') || strcmp(evnt.EventName,'maskChanged')
                tool.setmaskHistory(tool.getMask(true));
            end
        end
        
        function SliceEvents(tool,src,evnt)
            mask = tool.getCurrentMaskSlice(1);
            
            if any(mask(:))
                set(tool.handles.Tools.mask2poly,'Enable','on')
            else
                set(tool.handles.Tools.mask2poly,'Enable','off')
            end
        end
        
    end

    
end

function StatsCallback(hObject,evnt,tool)
% unselect button to prevent activation with spacebar
set(hObject, 'Enable', 'off');
drawnow;
set(hObject, 'Enable', 'on');
 
f1 = StatsGUI(tool.getImage(1),tool.getMask(1),[],tool.getMaskColor);
f2 = HistogramGUI(tool.getImage,tool.getMask(1),tool.getMaskColor);
pos = get(f1,'Position');
pos(1) = pos(1)+pos(3);
set(f2,'Position',pos)
end

function PaintBrushCallback(hObject,evnt,tool,style)
%Remove any old brush
removeBrushObject(tool);

if get(hObject,'Value')
    switch style
        case 'Normal'
            set(tool.handles.Tools.SmartBrush,'Value',0);
        case 'Smart'
            set(tool.handles.Tools.PaintBrush,'Value',0);
    end
    createBrushObject(tool,style);    
end

end

function mask2polyImageCallback(hObject,evnt,tool)
h = getHandles(tool);
mask = tool.getCurrentMaskSlice(0);
mask = imfill(mask,'holes');
if any(mask(:))
    [labels,num] = bwlabel(mask);
    for ilab=1:num
        labelilab = labels==ilab;
        if sum(labelilab(:))>15
            P = bwboundaries(labelilab); P = P{1}; P = P(:,[2 1]);
            if size(P,1)>16, P = reduce_poly(P(2:end,:)',max(6,round(size(P,1)/15))); P(:,end+1)=P(:,1); end
            if ~isempty(P)
                imtool3DROI_poly(h.I,P',tool);
            end
        end
    end
end

end

function smooth3Callback(hObject,evnt,tool)
% unselect button to prevent activation with spacebar
set(hObject, 'Enable', 'off');
drawnow;
set(hObject, 'Enable', 'on');
 
mask = getMask(tool); 
mask = smooth3(mask)>0.45;
tool.setMask(mask);
end

function maskinterpImageCallback(hObject,evnt,tool)
mask = getMask(tool); 
[x,y,z] = find3d(mask); 
mask2=false(size(mask));

switch tool.viewplane
    case 1
        z = unique(x);
        mask2(min(z):max(z),:,:) = interpmask(z, mask(unique(z),:,:),min(z):max(z),'interpDim',1,'pchip');
    case 2
        z = unique(y);
        mask2(:,min(z):max(z),:) = interpmask(z, mask(:,unique(z),:),min(z):max(z),'interpDim',2,'pchip');
    case 3
        z = unique(z);
        mask2(:,:, min(z):max(z)) = interpmask(z, mask(:,:,unique(z)),min(z):max(z),'interpDim',3,'pchip');
end
tool.setMask(mask2);
end


function ActiveCountourCallback(hObject,evnt,tool)
% unselect button to prevent activation with spacebar
set(hObject, 'Enable', 'off');
drawnow;
set(hObject, 'Enable', 'on');

mask = getMask(tool);
if any(mask(:))
    I = tool.getImage;
    [W,L] = getWindowLevel(tool);
    I = mat2gray(I,[L-W/2 L+W/2]);
    
%     mask = smooth3(mask);
%     mask = mask>0.8;
    [x,y,z] = find3d(mask);
    switch tool.viewplane
        case 1
            z=x;
        case 2
            z=y;
    end
    z = unique(z);
    for iz = z'
        switch tool.viewplane
            case 1
                Iiz = I(iz,:,:);
                maskiz = mask(iz,:,:);
            case 2
                Iiz = I(:,iz,:);
                maskiz = mask(:,iz,:);
            case 3
                Iiz = I(:,:,iz);
                maskiz = mask(:,:,iz);
        end

        J = activecontour(squeeze(Iiz), squeeze(maskiz), 3,'Chan-Vese','SmoothFactor',0.1,'ContractionBias' ,0);
        switch tool.viewplane
            case 1
                mask(iz,:,:) = J;
            case 2
                mask(:,iz,:) = J;
            case 3
                mask(:,:,iz) = J;
        end
    end
    tool.setMask(mask);
end
end

% function CropImageCallback(hObject,evnt,tool)
% [I2 rect] = imcrop(tool.handles.Axes);
% rect=round(rect);
% mask = getMask(tool);
% range=getDisplayRange(tool);
% setImage(tool, tool.I(rect(2):rect(2)+rect(4)-1,rect(1):rect(1)+rect(3)-1,:),range,mask(rect(2):rect(2)+rect(4)-1,rect(1):rect(1)+rect(3)-1,:))
% end

function [I, position, h, range, tools, mask, enableHist] = parseinputs(varargin)
            switch length(varargin)
                case 0  %tool = imtool3d()
                    I=[];
                    position=[0 0 1 1]; h=[];
                    range=[]; tools=[]; mask=[]; enableHist=true;
                case 1  %tool = imtool3d(I)
                    I=varargin{1}; position=[0 0 1 1]; h=[];
                    range=[]; tools=[]; mask=[]; enableHist=true;
                case 2  %tool = imtool3d(I,position)
                    I=varargin{1}; position=varargin{2}; h=[];
                    range=[]; tools=[]; mask=[]; enableHist=true;
                case 3  %tool = imtool3d(I,position,h)
                    I=varargin{1}; position=varargin{2}; h=varargin{3};
                    range=[]; tools=[]; mask=[]; enableHist=true;
                case 4  %tool = imtool3d(I,position,h,range)
                    I=varargin{1}; position=varargin{2}; h=varargin{3};
                    range=varargin{4}; tools=[]; mask=[]; enableHist=true;
                case 5  %tool = imtool3d(I,position,h,range,tools)
                    I=varargin{1}; position=varargin{2}; h=varargin{3};
                    range=varargin{4}; tools=varargin{5}; mask=[];
                    enableHist=true;
                case 6  %tool = imtool3d(I,position,h,range,tools,mask)
                    I=varargin{1}; position=varargin{2}; h=varargin{3};
                    range=varargin{4}; tools=varargin{5}; mask=varargin{6};
                    enableHist=true;
                case 7  %tool = imtool3d(I,position,h,range,tools,mask)
                    I=varargin{1}; position=varargin{2}; h=varargin{3};
                    range=varargin{4}; tools=varargin{5}; mask=varargin{6};
                    enableHist = varargin{7};
            end
            
            if isempty(position)
                position=[0 0 1 1];
            end
end

function measureImageCallback(hObject,evnt,tool,type)

switch type
    case 'ellipse'
        h = getHandles(tool);
        ROI = imtool3DROI_ellipse(h.I,[],tool);
    case 'rectangle'
        h = getHandles(tool);
        ROI = imtool3DROI_rect(h.I,[],tool);
    case 'polygon'
        h = getHandles(tool);
        ROI = imtool3DROI_poly(h.I,[],tool);
    case 'profile'
        h = getHandles(tool);
        ROI = imtool3DROI_line(h.I);
    otherwise
end


end

function varargout = imageButtonDownFunction(hObject,eventdata,tool)
switch nargout
    case 0
        bp = get(0,'PointerLocation');
        WBMF_old = get(tool.handles.fig,'WindowButtonMotionFcn');
        WBUF_old = get(tool.handles.fig,'WindowButtonUpFcn');
        switch get(tool.handles.fig,'SelectionType')
            case 'normal'   %Adjust window and level
                CLIM=get(tool.handles.Axes,'Clim');
                W=CLIM(2)-CLIM(1);
                L=mean(CLIM);
                %make the contrast icon for the pointer
                icon = zeros(16);
                x = 1:16; [X,Y]= meshgrid(x,x); R = sqrt((X-8).^2 + (Y-8).^2);
                icon(Y>8) = 1;
                icon(Y<=8) = 2;
                icon(R>8) = nan;
                set(tool.handles.fig,'PointerShapeCData',icon);
                set(tool.handles.fig,'Pointer','custom')
                fun=@(src,evnt) adjustContrastMouse(src,evnt,bp,tool.handles.Axes,tool,W,L);
                fun2=@(src,evnt) buttonUpFunction(src,evnt,tool,WBMF_old,WBUF_old);
                set(tool.handles.fig,'WindowButtonMotionFcn',fun,'WindowButtonUpFcn',fun2)
            case 'extend'  %Zoom
                xlims=get(tool.handles.Axes,'Xlim');
                ylims=get(tool.handles.Axes,'Ylim');
                bpA=get(tool.handles.Axes,'CurrentPoint');
                bpA=[bpA(1,1) bpA(1,2)];
                setptr(tool.handles.fig,'glass');
                fun=@(src,evnt) adjustZoomMouse(src,evnt,bp,tool.handles.Axes,tool,xlims,ylims,bpA);
                fun2=@(src,evnt) buttonUpFunction(src,evnt,tool,WBMF_old,WBUF_old);
                set(tool.handles.fig,'WindowButtonMotionFcn',fun,'WindowButtonUpFcn',fun2)
            case 'alt' %pan
                xlims=get(tool.handles.Axes,'Xlim');
                ylims=get(tool.handles.Axes,'Ylim');
                oldUnits =  get(tool.handles.Axes,'Units'); set(tool.handles.Axes,'Units','Pixels');
                pos = get(tool.handles.Axes,'Position'); 
                set(tool.handles.Axes,'Units',oldUnits);
                axesPixels = pos(3:end);
                imagePixels = [diff(xlims) diff(ylims)];
                scale = imagePixels./axesPixels;
                scale = scale(1);
                setptr(tool.handles.fig,'closedhand');
                fun=@(src,evnt) adjustPanMouse(src,evnt,bp,tool.handles.Axes,xlims,ylims,scale);
                fun2=@(src,evnt) buttonUpFunction(src,evnt,tool,WBMF_old,WBUF_old);
                set(tool.handles.fig,'WindowButtonMotionFcn',fun,'WindowButtonUpFcn',fun2)
        end
    case 2
        bp=get(tool.handles.Axes,'CurrentPoint');
        x=bp(1,1); y=bp(1,2);
        varargout{1}=x; varargout{2}=y;
end
end

function resetViewCallback(hObject,evnt,tool)
set(tool.handles.Axes,'Xlim',get(tool.handles.I,'XData'))
set(tool.handles.Axes,'Ylim',get(tool.handles.I,'YData'))
end

function toggleGrid(hObject,eventdata,tool)
% unselect button to prevent activation with spacebar
try
    warning off
    set(hObject, 'Enable', 'off');
    drawnow;
    set(hObject, 'Enable', 'on');
    warning on
end

if get(hObject,'Value')
    set(tool.handles.grid,'Visible','on')
else
    set(tool.handles.grid,'Visible','off')
end
end

function toggleMask(hObject,eventdata,tool)
% unselect button to prevent activation with spacebar
set(hObject, 'Enable', 'off');
drawnow;
set(hObject, 'Enable', 'on');

if get(hObject,'Value')
    set(tool.handles.mask,'Visible','on')
else
    set(tool.handles.mask,'Visible','off')
end

end

function changeColormap(hObject,eventdata,tool)
% unselect button to prevent activation with spacebar
set(hObject, 'Enable', 'off');
drawnow;
set(hObject, 'Enable', 'on');

n=get(hObject,'Value');
maps=get(hObject,'String');
h = tool.getHandles;
colormap(h.Axes,maps{n})
if isfield(h,'HistImageAxes')
    colormap(h.HistImageAxes,maps{n})
end
end

function WindowLevel_callback(hobject,evnt,tool)
range=get(tool.handles.Axes,'Clim');

L=str2num(get(tool.handles.Tools.L,'String'));
if isempty(L) 
    L=range(1);
    set(tool.handles.Tools.L,'String',num2str(L))
end
U=str2num(get(tool.handles.Tools.U,'String'));
if isempty(U)
    U=range(2);
    set(tool.handles.Tools.U,'String',num2str(U))
end
if U<L
    U=L+max(eps,abs(0.1*L)); 
    set(tool.handles.Tools.U,'String',num2str(U))
end
setWL(tool,U-L,mean([U,L]))
end
        
function histogramButtonDownFunction(hObject,evnt,tool,line)

WBMF_old = get(tool.handles.fig,'WindowButtonMotionFcn');
WBUF_old = get(tool.handles.fig,'WindowButtonUpFcn');

switch line
    case 1 %Lower limit of range
        fun=@(src,evnt) newLowerRangePosition(src,evnt,tool.handles.HistAxes,tool);
        fun2=@(src,evnt) buttonUpFunction(src,evnt,tool,WBMF_old,WBUF_old);
        set(tool.handles.fig,'WindowButtonMotionFcn',fun,'WindowButtonUpFcn',fun2)
    case 2 %Upper limt of range
        fun=@(src,evnt) newUpperRangePosition(src,evnt,tool.handles.HistAxes,tool);
        fun2=@(src,evnt) buttonUpFunction(src,evnt,tool,WBMF_old,WBUF_old);
        set(tool.handles.fig,'WindowButtonMotionFcn',fun,'WindowButtonUpFcn',fun2)
    case 3 %Middle line
        fun=@(src,evnt) newLevelRangePosition(src,evnt,tool.handles.HistAxes,tool);
        fun2=@(src,evnt) buttonUpFunction(src,evnt,tool,WBMF_old,WBUF_old);
        set(tool.handles.fig,'WindowButtonMotionFcn',fun,'WindowButtonUpFcn',fun2)
end
end

function scrollWheel(scr,evnt,tool)
%Check to see if the mouse is over the axis
% units=get(tool.handles.fig,'Units');
% set(tool.handles.fig,'Units','Pixels')
% point=get(tool.handles.fig, 'CurrentPoint');
% set(tool.handles.fig,'Units',units)
% 
% units=get(tool.handles.Panels.Large,'Units');
% set(tool.handles.Panels.Large,'Units','Pixels')
% pos_p=get(tool.handles.Panels.Large,'Position');
% set(tool.handles.Panels.Large,'Units',units)
% 
% units=get(tool.handles.Panels.Image,'Units');
% set(tool.handles.Panels.Image,'Units','Pixels')
% pos_a=get(tool.handles.Panels.Image,'Position');
% set(tool.handles.Panels.Image,'Units',units)
% 
% xmin=pos_p(1)+pos_a(1); xmax=xmin+pos_a(3);
% ymin=pos_p(2)+pos_a(2); ymax=ymin+pos_a(4);



%if point(1)>=xmin && point(1)<=xmax && point(2)>=ymin && point(2)<=ymax
%if isMouseOverAxes(tool.handles.Axes)
    newSlice=get(tool.handles.Slider,'value')-evnt.VerticalScrollCount;
    if newSlice>=1 && newSlice <=size(tool.I,tool.viewplane)
        set(tool.handles.Slider,'value',newSlice);
        showSlice(tool)
    end
%end

end

function multipleScrollWheel(scr,evnt,tools)
for i=1:length(tools)
    scrollWheel(scr,evnt,tools(i))
end
end

function newLowerRangePosition(src,evnt,hObject,tool)
cp = get(hObject,'CurrentPoint'); cp=[cp(1,1) cp(1,2)];
range=get(tool.handles.Axes,'Clim');
Xlims=get(hObject,'Xlim');
r=double(tool.getrange);
ord = round(log10(r));
if ord>1
    cp(1)=round(cp(1));
end
range(1)=cp(1);
W=diff(range);
L=mean(range);
if W>0 && range(1)>=Xlims(1)
    setWL(tool,W,L)
end
end

function newUpperRangePosition(src,evnt,hObject,tool)
cp = get(hObject,'CurrentPoint'); cp=[cp(1,1) cp(1,2)];
range=get(tool.handles.Axes,'Clim');
Xlims=get(hObject,'Xlim');
r=double(tool.getrange);
ord = round(log10(r));
if ord>1
    cp(1)=round(cp(1));
end
range(2)=cp(1);
W=diff(range);
L=mean(range);
if W>0 && range(2)<=Xlims(2)
    setWL(tool,W,L)
end
end

function newLevelRangePosition(src,evnt,hObject,tool)
cp = get(hObject,'CurrentPoint'); cp=[cp(1,1) cp(1,2)];
range=get(tool.handles.Axes,'Clim');
Xlims=get(hObject,'Xlim');
r=double(tool.getrange);
ord = round(log10(r));
if ord>1
    cp(1)=round(cp(1));
end
L=cp(1);
W=diff(range);
if L>=Xlims(1) && L<=Xlims(2)
    setWL(tool,W,L)
end
end

function adjustContrastMouse(src,evnt,bp,hObject,tool,W,L)
cp = get(0,'PointerLocation');
SS=get( 0, 'Screensize' ); SS=SS(end-1:end); %Get the screen size
d=round(cp-bp)./SS;
r=tool.getrange;
WS=tool.windowSpeed;
W2=W+r*d(1)*WS; L=L-r*d(2)*WS;
if W2>0
    W=W2;
else
    W=.001*W;
end

ord = round(log10(r));
if ord>1
    W=ceil(W);
    L=round(L);
end

setWL(tool,W,L)
end

function adjustZoomMouse(src,~,bp,hObject,tool,xlims,ylims,bpA)

%get the zoom factor
cp = get(0,'PointerLocation');
d=cp(2)-bp(2);  %
zfactor = 1; %zoom percentage per change in screen pixels
resize = 100 + d*zfactor;   %zoom percentage

%get the old center point
cold = [xlims(1)+diff(xlims)/2 ylims(1)+diff(ylims)/2];

%get the direction vector from old center to the clicked point
dir = cold-bpA;
pfactor = 100; %zoom percentage at which clicked point becomes the new center

%rescale the dir vector according to ratio between resize and pfactor
dir = (dir*((resize-100)/pfactor));

%get the new center
cx = cold(1) + dir(1);
cy = cold(2) + dir(2);

%get the new width
newXwidth = diff(xlims)* (resize/100);
newYwidth = diff(ylims)* (resize/100);

%set the new axis limits
xlims = [cx-newXwidth/2 cx+newXwidth/2];
ylims = [cy-newYwidth/2 cy+newYwidth/2];
if resize > 0
    set(hObject,'Xlim',xlims,'Ylim',ylims)
end

end

function adjustPanMouse(src,evnt,bp,hObject,xlims,ylims,scale)
cp = get(0,'PointerLocation');
V = get(hObject,'View');
d = scale*(bp-cp);
if V(1)==-90
    d(1) = -d(1);
    d = d([2 1]);
elseif V(1)==90
    d(2) = -d(2);
    d = d([2 1]);
end
set(hObject,'Xlim',xlims+d(1),'Ylim',ylims-d(2))
end

function buttonUpFunction(src,evnt,tool,WBMF_old,WBUF_old)

setptr(tool.handles.fig,'arrow');
set(src,'WindowButtonMotionFcn',WBMF_old,'WindowButtonUpFcn',WBUF_old);

end

function getImageInfo(src,evnt,tool)
% if Mouse over Mask Selection button
current_object = hittest;
setmaskstatistics(tool,current_object)

h = tool.getHandles;
if ~isequal(h.Axes,current_object) && ~isequal(h.I,current_object) && ~isequal(h.mask,current_object)
    set(h.Info,'String','(x,y) val')
    return
end

pos=round(get(h.Axes,'CurrentPoint'));
pos=pos(1,1:2);
n=round(get(h.Slider,'value'));
if n==0
    n=1;
end

posdim = setdiff(1:3, tool.viewplane);
if pos(1)>0 && pos(1)<=size(tool.I,posdim(2)) && pos(2)>0 && pos(2)<=size(tool.I,posdim(1))
    switch tool.viewplane
        case 1
            set(h.Info,'String',['(' num2str(pos(1)) ',' num2str(pos(2)) ') ' num2str(tool.I(n,pos(2),pos(1),tool.Ntime,tool.Nvol))])
        case 2
            set(h.Info,'String',['(' num2str(pos(1)) ',' num2str(pos(2)) ') ' num2str(tool.I(pos(2),n,pos(1),tool.Ntime,tool.Nvol))])
        case 3
            set(h.Info,'String',['(' num2str(pos(1)) ',' num2str(pos(2)) ') ' num2str(tool.I(pos(2),pos(1),n,tool.Ntime,tool.Nvol))])
    end
    notify(tool,'newMousePos')
else
    set(h.Info,'String','(x,y) val')
end



end

function panelResizeFunction(hObject,events,tool,w,h,wbutt)
    hh = tool.getHandles;
    try
    units=get(hh.Panels.Large,'Units');
    set(hh.Panels.Large,'Units','Pixels')
    pos=get(hh.Panels.Large,'Position');
    set(hh.Panels.Large,'Units',units)
    if isfield(hh.Tools,'Hist') && get(hh.Tools.Hist,'value')
        set(hh.Panels.Image,'Position',[w w pos(3)-2*w pos(4)-2*w-h])
    else
        set(hh.Panels.Image,'Position',[w w max(0,pos(3)-2*w) max(0,pos(4)-2*w)])
    end
    %set(h.Panels.Image,'Position',[w w pos(3)-2*w pos(4)-2*w])
    set(hh.Panels.Hist,'Position',[w max(0,pos(4)-w-h) max(0,pos(3)-2*w) h])
    set(hh.Panels.Tools,'Position',[0 max(0,pos(4)-w) pos(3) w])
    set(hh.Panels.ROItools,'Position',[max(0,pos(3)-w)  w w max(0,pos(4)-2*w)])
    set(hh.Panels.Slider,'Position',[0 w w max(0,pos(4)-2*w)])
    set(hh.Panels.Info,'Position',[0 0 pos(3) w])
    axis(hh.Axes,'fill');
    buff=(w-wbutt)/2;
    pos=get(hh.Panels.ROItools,'Position');
    set(hh.Tools.Help,'Position',[buff pos(4)-wbutt-buff wbutt wbutt]);
    
    for islct=1:5
        set(hh.Tools.maskSelected(islct),'Position',[buff pos(4)-wbutt-buff-islct*wbutt wbutt wbutt]);
    end
    
    set(hh.Tools.maskLock,'Position',[buff pos(4)-wbutt-buff-(islct+1)*wbutt wbutt wbutt]);
    set(hh.Tools.maskStats,'Position',[buff pos(4)-wbutt-buff-(islct+2)*wbutt wbutt wbutt]);

    set(hh.Axes,'XLimMode','manual','YLimMode','manual');

    end
end

function icon = makeToolbarIconFromPNG(filename)
% makeToolbarIconFromPNG  Creates an icon with transparent
%   background from a PNG image.

%   Copyright 2004 The MathWorks, Inc.  
%   $Revision: 1.1.8.1 $  $Date: 2004/08/10 01:50:31 $

  % Read image and alpha channel if there is one.
  [icon,map,alpha] = imread(filename);

  % If there's an alpha channel, the transparent values are 0.  For an RGB
  % image the transparent pixels are [0, 0, 0].  Otherwise the background is
  % cyan for indexed images.
  if (ndims(icon) == 3) % RGB

    idx = 0;
    if ~isempty(alpha)
      mask = alpha == idx;
    else
      mask = icon==idx; 
    end
    
  else % indexed
    
    % Look through the colormap for the background color.
    if isempty(map), idx=1; icon = im2double(repmat(icon, [1 1 3])); return; end
    for i=1:size(map,1)
      if all(map(i,:) == [0 1 1])
        idx = i;
        break;
      end
    end
    
    mask = icon==(idx-1); % Zero based.
    icon = ind2rgb(icon,map);
    
  end
  
  % Apply the mask.
  icon = im2double(icon);
  
  for p = 1:3
    
    tmp = icon(:,:,p);
    if ndims(mask)==3
        tmp(mask(:,:,p))=NaN;
    else
        tmp(mask) = NaN;
    end
    icon(:,:,p) = tmp;
    
  end

end

function ShowHistogram(hObject,evnt,tool,w,h)
% unselect button to prevent activation with spacebar
set(hObject, 'Enable', 'off');
drawnow;
set(hObject, 'Enable', 'on');

    hh = tool.getHandles;
set(hh.Panels.Large,'Units','Pixels')
pos=get(hh.Panels.Large,'Position');
set(hh.Panels.Large,'Units','normalized')

if get(hh.Tools.Hist,'value')
    set(hh.Panels.Image,'Position',[w w pos(3)-2*w pos(4)-2*w-h])
else
    set(hh.Panels.Image,'Position',[w w pos(3)-2*w pos(4)-2*w])
end
axis(hh.Axes,'fill');
showSlice(tool)

end

function fig = getParentFigure(fig)
% if the object is a figure or figure descendent, return the
% figure. Otherwise return [].
while ~isempty(fig) & ~strcmp('figure', get(fig,'type'))
    fig = get(fig,'parent');
end
end

function overAxes = isMouseOverAxes(ha)
%This function checks if the mouse is currently hovering over the axis in
%question. hf is the handle to the figure, ha is the handle to the axes.
%This code allows the axes to be embedded in any size heirarchy of
%uipanels.

point = get(ha,'CurrentPoint');
x = point(1,1); y = point(1,2);
xlims = get(ha,'Xlim');
ylims = get(ha,'Ylim');

overAxes = x>=xlims(1) & x<=xlims(2) & y>=ylims(1) & y<=ylims(2);



end

function displayHelp(hObject,evnt,tool)

msg = {'imtool3D, written by Justin Solomon',...
       'justin.solomon@duke.edu',...
       'adapted by Tanguy Duval',...
       'https://github.com/tanguyduval/imtool3D_td',...
       '------------------------------------------',...
       '',...
       'KEYBOARD SHORTCUTS:',...
       'Left/right arrows:      navigate through time (4th dimension)',...
       'Top/bottom arrows:      navigate through volumes (5th dimension)',...
       'Middle Click and drag:  Zoom in/out',...
       'Left Click and drag:    Contrast/Brightness',...
       'Right Click and drag:   Pan',...
       '',...
       'Spacebar:               Show/hide mask',...
       'B:                      Toolbrush ',...
       '                            Middle click and drag to change diameter',...
       '                            Right click to erase',...
       'S:                      Smart Toolbrush',...
       'Z:                      Undo mask',...
       '1:                      Select mask label 1',...
       '2:                      Select mask label 2',...
       '...'};msgbox(msg)

end

function pos = getPixelPosition(h)
oldUnits = get(h,'Units');
set(h,'Units','Pixels');
pos = get(h,'Position');
set(h,'Units',oldUnits);
end

function togglebutton(h)
set(h,'Value',~get(h,'Value'))
fun = get(h,'Callback');
fun(h,1)
end