function PTB = InitialisePTB(varargin)

PTB = struct();
PTB.myScreen = [];
PTB.window = [];
PTB.dimensions = [];
PTB.width = [];
PTB.height = [];
PTB.centrex = [];
PTB.centrey = [];
PTB.FlipInterval = [];
PTB.slack = [];
PTB.MonitorFrequency = [];

if nargin == 0
    PTB.defaultFont = 'Helvetica';
    PTB.fontSize = 32;
elseif nargin == 1
    PTB.defaultFont = varargin{1}.defaultFont;
    PTB.fontSize = varargin{1}.fontSize;
else error('Too many input arguments for InitialisePTB');
end

% Initialise PTB
AssertOpenGL;
PsychJavaTrouble;

% Get the maximum screen number i.e. get an external screen if avaliable
PTB.myScreen = max(Screen('Screens'));

% Open a new PsychToolbox window on the screen specified by myScreenNumber
[PTB.window,PTB.dimensions] = Screen(PTB.myScreen,'OpenWindow');

% Calculate the dimensions of the screen
[PTB.width, PTB.height] = RectSize(PTB.dimensions);
PTB.centrex = PTB.width/2;
PTB.centrey = PTB.height/2;

% Calculate the flip interval of the screen
PTB.FlipInterval = Screen('GetFlipInterval',PTB.window); %Gets the Flip Interval of the window we're working on
PTB.slack = PTB.FlipInterval/2;
PTB.MonitorFrequency = round(1/PTB.FlipInterval);

% Hide the mouse cursor
HideCursor;

% Turn off keyboard input to MATLAB
ListenChar(2); %Turns off keyboard input to MATLAB

% Set default font

Screen('TextFont',PTB.window,PTB.defaultFont);
Screen('TextSize',PTB.window,PTB.fontSize);

% Set the blend function
Screen(PTB.window,'BlendFunction', GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

end