unit uMainForm;

{$I D:\downloads\delphi.components\CEF4Delphi\source\cef.inc}

interface

uses
uCEFChromium, uCEFTypes, uCEFInterfaces,  uCEFBufferPanel,
  uCEFChromiumCore,
  OPENCVWrapper, Vcl.Samples.Spin,
    {$IFDEF DELPHI16_UP}
  System.Math,
  {$ELSE}
  Math,
  {$ENDIF}
{$IFDEF DELPHI16_UP}
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Forms,
  Vcl.Controls, Vcl.StdCtrls, Vcl.Dialogs, Vcl.Buttons, Winapi.Messages,
  Vcl.ExtCtrls, Vcl.ComCtrls;
{$ELSE}
Windows, SysUtils, Classes, Graphics, Forms,
  Controls, StdCtrls, Dialogs, Buttons, Messages,
  ExtCtrls, ComCtrls, Vcl.Samples.Spin;
{$ENDIF}

const
  TRANSPARENT_BROWSER      = False;
  CEFBROWSER_CREATED = WM_APP + $100;
  CEFBROWSER_CHILDDESTROYED = WM_APP + $101;
  CEFBROWSER_DESTROY = WM_APP + $102;
  CEFBROWSER_INITIALIZED = WM_APP + $103;

type
  TMainForm = class(TForm)
    ButtonPnl: TPanel;
    NewBtn: TSpeedButton;
    ExitBtn: TSpeedButton;
    mercImage: TImage;
    Memo1: TMemo;

    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);

    procedure NewBtnClick(Sender: TObject);
    procedure ExitBtnClick(Sender: TObject);
    procedure imgMap1Click(Sender: TObject);
    procedure imgMap2Click(Sender: TObject);
    procedure imgMap3Click(Sender: TObject);
    procedure imgMap4Click(Sender: TObject);

  private
    // Variables to control when can we destroy the form safely
    FCanClose: boolean; // Set to True when all the child forms are closed
    FClosing: boolean; // Set to True in the CloseQuery event.
    FBrowserCount: integer;
    initialized: boolean;
    templateGoToLocation, TemplateImg: pCvMat_t;

    procedure CreateMDIChild(const Name: string; id: cardinal);
    procedure CloseAllChildForms;
    function GetChildClosing: boolean;

  protected
    procedure ChildDestroyedMsg(var aMessage: TMessage);
      message CEFBROWSER_CHILDDESTROYED;
    procedure CEFInitializedMsg(var aMessage: TMessage);
      message CEFBROWSER_INITIALIZED;

  public
    function CloseQuery: boolean; override;

    property ChildClosing: boolean read GetChildClosing;
    property BrowserCount: integer read FBrowserCount;
    procedure bringChild2Front(id: cardinal);
    procedure copyImgRegion(id: cardinal; target: TImage);
  end;

var
  MainForm: TMainForm;

procedure CreateGlobalCEFApp;

implementation

{$R *.dfm}

uses
//  uChildForm,
  uSimpleOSRBrowser,
 uCEFRequestContext,
  uCEFMiscFunctions,
  uCEFApplication, uCEFConstants;

// Destruction steps
// =================
// 1. Destroy all child forms
// 2. Wait until all the child forms are closed before closing the main form.

procedure GlobalCEFApp_OnContextInitialized;
begin
  if (MainForm <> nil) and MainForm.HandleAllocated then
    PostMessage(MainForm.Handle, CEFBROWSER_INITIALIZED, 0, 0);
end;

procedure CreateGlobalCEFApp;
begin
  // GlobalCEFApp.RootCache must be the parent of all cache directories
  // used by the browsers in the application.
  GlobalCEFApp := TCefApplication.Create;
  GlobalCEFApp.OnContextInitialized := GlobalCEFApp_OnContextInitialized;
  GlobalCEFApp.RootCache := ExtractFileDir(ParamStr(0)) + '\RootCache';
//  GlobalCEFApp.cache := GlobalCEFApp.RootCache + '\cache';
  GlobalCEFApp.LogFile := 'debug.log';
  GlobalCEFApp.LogSeverity := LOGSEVERITY_INFO;

   GlobalCEFApp.WindowlessRenderingEnabled := True;
   GlobalCEFApp.TouchEvents                := STATE_ENABLED;
   GlobalCEFApp.EnableGPU                  := True;

// GlobalCEFApp.ChromeRuntime              := True;

  // If you need transparency leave the GlobalCEFApp.BackgroundColor property
  // with the default value or set the alpha channel to 0
  if TRANSPARENT_BROWSER then
    GlobalCEFApp.BackgroundColor := CefColorSetARGB($00, $00, $00, $00)
   else
    GlobalCEFApp.BackgroundColor := CefColorSetARGB($FF, $FF, $FF, $FF);
end;

procedure TMainForm.CreateMDIChild(const Name: string; id: cardinal);
var
   TempChild: TForm1; // TChildForm;

begin
   TempChild := TForm1.Create(Self);

  TempChild.Caption := Name;
  TempChild.id := id;

  TempChild.templateGoToLocation:=templateGoToLocation;
  TempChild.TemplateImg:=TemplateImg;
end;

procedure TMainForm.CloseAllChildForms;
var
  i: integer;
begin
  i := pred(MDIChildCount);

  while (i >= 0) do
  begin
    if not(TForm1(MDIChildren[i]).Closing) then
      PostMessage(MDIChildren[i].Handle, WM_CLOSE, 0, 0);

    dec(i);
  end;
end;

function TMainForm.GetChildClosing: boolean;
var
  i: integer;
begin
  Result := false;
  i := pred(MDIChildCount);

  while (i >= 0) do
    if TForm1(MDIChildren[i]).Closing then
    begin
      Result := True;
      exit;
    end
    else
      dec(i);
end;

procedure TMainForm.bringChild2Front(id: cardinal);
var
  i: integer;
  AChildForm: TForm1;
begin
  for i := 0 to MDIChildCount - 1 do
  begin
    AChildForm := TForm1(MDIChildren[i]);
    // Check if the form is of the desired type AND has a specific identifier
    if (AChildForm.id = id) then
    begin
      AChildForm.BringToFront;
      exit; // Stop iterating once the form is found and activated
    end;
  end;
end;

procedure TMainForm.imgMap1Click(Sender: TObject);
begin
  bringChild2Front(1);
end;

procedure TMainForm.imgMap2Click(Sender: TObject);
begin
  bringChild2Front(2);
end;

procedure TMainForm.imgMap3Click(Sender: TObject);
begin
  bringChild2Front(3);
end;

procedure TMainForm.imgMap4Click(Sender: TObject);
begin
  bringChild2Front(4);

end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FCanClose := false;
  FClosing := false;
  FBrowserCount := 0;

  initialized := false;
end;

procedure TMainForm.NewBtnClick(Sender: TObject);
begin
  inc(FBrowserCount);
  CreateMDIChild('ChildForm' + IntToStr(FBrowserCount), FBrowserCount);
end;

procedure TMainForm.copyImgRegion(id: cardinal; target: TImage);
var
  DestBitmap: TBitmap;
  SourceRect: TRect;
  AChildForm: TForm1;
  i: integer;

const
  targetHeight=280;
begin
  // if form =nil then exit;

  for i := 0 to MDIChildCount - 1 do
  begin
    AChildForm := TForm1(MDIChildren[i]);
    // Check if the form is of the desired type AND has a specific identifier
    if (AChildForm.id = id) then
    begin
//       outputdebugstring(pchar('trying to capture screenshot '+inttostr(id)));

      if not AChildForm.initialized then begin
          outputdebugstring(pchar('browser not initialized'));
        exit;
      end;

        AChildForm.captureScreenshot;

//        if AChildForm.screenshot = nil then begin
//         outputdebugstring(pchar('no screenshot'));
//          exit;
//        end;
//      if AChildForm.Panel1.Buffer = nil then
//        exit;

      DestBitmap := TBitmap.Create;
      try
        // Set size to match the rectangle dimensions
        DestBitmap.Width := target.Width;
        DestBitmap.height := targetHeight; // target.Height;

//        outputdebugstring(pchar('img height : ' + IntToStr(target.height)));

        SourceRect := Rect(0, AChildForm.height - targetHeight { target.Height } ,
          target.Width, AChildForm.height);

//        // Copy the rectangle from source to destination
//        DestBitmap.Canvas.CopyRect(Rect(0, 0, DestBitmap.Width,
//          DestBitmap.height), // Destination rectangle (full bitmap)
//          // form.screenshot.Canvas,  // Source canvas
//          AChildForm.Panel1.Buffer.Canvas, SourceRect // Source rectangle
//          );

//           DestBitmap.Canvas.CopyRect(Rect(0, 0, DestBitmap.Width,
//          DestBitmap.height), // Destination rectangle (full bitmap)
//          // form.screenshot.Canvas,  // Source canvas
//          AChildForm.screenshot.Canvas, SourceRect // Source rectangle
//          );
//
//        // Assign the new bitmap to the TImage
        target.Picture.Assign(DestBitmap);
      finally
        DestBitmap.Free; // Free the temporary bitmap to avoid memory leaks
      end;

      exit; // Stop iterating once the form is found and activated
    end;
  end;

end;

procedure TMainForm.ExitBtnClick(Sender: TObject);
begin
  ButtonPnl.Enabled := false;

  if (MDIChildCount = 0) then
    Close
  else
    CloseAllChildForms;
end;

procedure TMainForm.ChildDestroyedMsg(var aMessage: TMessage);
begin
  // If there are no more child forms we can destroy the main form
  if FClosing and (MDIChildCount = 0) then
  begin
    ButtonPnl.Enabled := false;
    FCanClose := True;
    PostMessage(Handle, WM_CLOSE, 0, 0);
  end;
end;

procedure TMainForm.CEFInitializedMsg(var aMessage: TMessage);
begin
  Caption := 'Browser';
  ButtonPnl.Enabled := True;
  cursor := crDefault;
end;

procedure TMainForm.FormShow(Sender: TObject);
var
  bitmap: TBitmap;
  Width, height: integer;
   sfile, tmp: CvString_t;
   appDir:string;
begin
  // AppDirectory will contain the path to the executable, e.g., 'C:\MyProject\Bin\'
appdir :=ExtractFilePath(Application.ExeName);

  if (GlobalCEFApp <> nil) and GlobalCEFApp.GlobalContextInitialized then
  begin
     Caption := 'Browser';
    ButtonPnl.Enabled := True;
    cursor := crDefault;

    if not initialized then
    begin
      Caption := 'Browser - tb';
      initialized := True;

      if templateGoToLocation=nil then begin
        var gotolocationFile:=appdir+'gotocoord.jpg';
        outputdebugstring(pchar(gotolocationfile));
        sfile.pstr := PAnsiChar(AnsiString(gotoLocationFile));

        templateGoToLocation := pCvimread(@sfile, ord(IMREAD_COLOR));

        if (pCvMatGetWidth(templateGoToLocation) = 0) then
        begin
          ShowMessage('Error: templateGoToLocation not exists');
          Exit;
        end;
      end;

      // convert merc image to pc_mat format
      if TemplateImg = nil then
      begin

        // Get dimensions from the source image (mercImage should be loaded)
        Width := mercImage.Picture.Width;
        height := mercImage.Picture.height;

        // Create the OpenCV Mat with correct size and type (3-channel, 8-bit)
        // CV_8UC3 = 8-bit unsigned, 3 channels (BGR/RGB)

        TemplateImg := pCvMatImageCreate(Width, height, CV_8UC3);
        // Allocate the Mat

        bitmap := TBitmap.Create;
        try

          // Bitmap.Assign(mercImage.Picture.Graphic);
          bitmap.Width := Width;
          bitmap.height := height;
          bitmap.pixelFormat := pf24bit;

          BitBlt(bitmap.Canvas.Handle, 0, 0, Width, height,
            mercImage.Canvas.Handle, 0, 0, SRCCOPY);

          Bitmap2MatImage(TemplateImg, bitmap);

        finally
          bitmap.Free
        end;
      end;

      // initial forms
      FBrowserCount := 1; //4;
      CreateMDIChild('ChildForm 1', 1);
//      CreateMDIChild('ChildForm 2', 2);
//      CreateMDIChild('ChildForm 3', 3);
//      CreateMDIChild('ChildForm 4', 4);

    end;
  end;
end;

function TMainForm.CloseQuery: boolean;
begin
  if FClosing or ChildClosing then
    Result := FCanClose
  else
  begin
    FClosing := True;

    if (MDIChildCount = 0) then
      Result := True
    else
    begin
      Result := false;
      CloseAllChildForms;
    end;
  end;
end;

end.
