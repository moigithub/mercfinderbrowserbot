unit uChildForm;

{$I D:\downloads\delphi.components\CEF4Delphi\source\cef.inc}

interface

uses
{$IFDEF DELPHI16_UP}
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Menus,
  System.Math,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  System.Types, Vcl.ComCtrls, Vcl.ClipBrd,
  System.UITypes, System.SyncObjs,
{$ELSE}
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Menus, Math,
  Controls, Forms, Dialogs, StdCtrls, ExtCtrls, Types, SyncObjs, ComCtrls,
  ClipBrd,
{$ENDIF}
  uMainForm,  tesseractocr, System.Threading,
  // Unit1,
  // uCEFBufferPanel,
  OPENCVWrapper,  Vcl.Imaging.PngImage,
  uCEFMiscFunctions, {$IFDEF DELPHI21_UP}System.NetEncoding, {$ENDIF} unit3,

  uCEFChromium,
  uCEFInterfaces, uCEFConstants, uCEFTypes,
  uCEFWinControl, uCEFChromiumCore, uCEFWindowParent, Vcl.Imaging.jpeg;

const
  CEFBROWSER_CREATED = WM_APP + $100;
  CEFBROWSER_CHILDDESTROYED = WM_APP + $101;
  CEFBROWSER_DESTROY = WM_APP + $102;
  CEFBROWSER_INITIALIZED = WM_APP + $103;
  DEVTOOLS_SCREENSHOT_MSGID = 1001;
  MINIBROWSER_DTDATA_AVLBL = WM_APP + $10E;
    DEVTOOLS_BROWSERINFO_MSGID      = 1003;
type
  TChildForm = class(TForm)
    Panel1: TPanel;
    Edit1: TEdit;
    Button1: TButton;
    Chromium1: TChromium;
    StatusBar1: TStatusBar;
    Button2: TButton;
    Timer1: TTimer;
    Button3: TButton;
    Image1: TImage;
    ScrollBox1: TScrollBox;
    CEFWindowParent1: TCEFWindowParent;

    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);

    procedure Button1Click(Sender: TObject);

    procedure Chromium1AfterCreated(Sender: TObject;
      const browser: ICefBrowser);
    procedure Chromium1BeforeClose(Sender: TObject; const browser: ICefBrowser);
    procedure Chromium1LoadingStateChange(Sender: TObject;
      const browser: ICefBrowser; isLoading, canGoBack, canGoForward: Boolean);
    procedure Chromium1StatusMessage(Sender: TObject;
      const browser: ICefBrowser; const value: ustring);
    procedure Chromium1BeforePopup(Sender: TObject; const browser: ICefBrowser;
      const frame: ICefFrame; popup_id: Integer;
      const targetUrl, targetFrameName: ustring;
      targetDisposition: TCefWindowOpenDisposition; userGesture: Boolean;
      const popupFeatures: TCefPopupFeatures; var windowInfo: TCefWindowInfo;
      var client: ICefClient; var settings: TCefBrowserSettings;
      var extra_info: ICefDictionaryValue; var noJavascriptAccess: Boolean;
      var Result: Boolean);
    procedure Chromium1RenderCompMsg(Sender: TObject; var aMessage: TMessage;
      var aHandled: Boolean);

    procedure MouseMove(Shift: TShiftState; X, Y: Integer);
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer);
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure MouseLeave(Sender: TObject);

    procedure InitializeLastClick;
    function CancelPreviousClick(X, Y: Integer;
      var aCurrentTime: Integer): Boolean;
    function getModifiers(Shift: TShiftState): TCefEventFlags;
    function GetButton(Button: TMouseButton): TCefMouseButtonType;
    procedure Chromium1DevToolsMethodResult(Sender: TObject;
      const browser: ICefBrowser; message_id: Integer; success: Boolean;
      const Result: ICefValue);
    procedure Chromium1GetScreenPoint(Sender: TObject;
      const browser: ICefBrowser; viewX, viewY: Integer;
      var screenX, screenY: Integer; out Result: Boolean);
    procedure Chromium1GetScreenInfo(Sender: TObject;
      const browser: ICefBrowser; var screenInfo: TCefScreenInfo;
      out Result: Boolean);
    procedure Chromium1GetViewRect(Sender: TObject; const browser: ICefBrowser;
      var rect: TCefRect);
    procedure Chromium1BrowserCompMsg(Sender: TObject; var aMessage: TMessage;
      var aHandled: Boolean);
    procedure Button2Click(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    // Variables to control when can we destroy the form safely
    FCanClose: Boolean; // Set to True in TChromium.OnBeforeClose
    FClosing: Boolean; // Set to True in the CloseQuery event.

  protected
    FLastClickCount: Integer;
    FLastClickTime: Integer;
    FLastClickPoint: TPoint;
    FLastClickButton: TMouseButton;

    FPendingMsgID: Integer;
    FDevToolsMsgValue: ustring;
    FBrowserInfoCS: TCriticalSection;
    FInitialized: Boolean;

     FSyncEvent: TEvent; // Event to signal when the result is ready


    procedure BrowserCreatedMsg(var aMessage: TMessage);
      message CEFBROWSER_CREATED;
    procedure WMMove(var aMessage: TWMMove); message WM_MOVE;
    procedure WMMoving(var aMessage: TMessage); message WM_MOVING;
    procedure WMEnterMenuLoop(var aMessage: TMessage); message WM_ENTERMENULOOP;
    procedure WMExitMenuLoop(var aMessage: TMessage); message WM_EXITMENULOOP;

    function GetInitialized: Boolean;
    procedure DevToolsDataAvailableMsg(var aMessage: TMessage);
      message MINIBROWSER_DTDATA_AVLBL;
  public
    id: cardinal;
    screenshot: TBitmap;
        templateGoToLocation, TemplateImg: pCvMat_t;

    task :string;
    step: integer;

    function captureScreenshot:TBitmap;
        function captureScreenshot2:TBitmap;
    function searchImage(TemplateImg: pCvMat_t; threshold: Double):boolean;
//    procedure sendESCKey;

    property Closing: Boolean read FClosing;
    property Initialized: Boolean read GetInitialized;
  end;

implementation

{$R *.dfm}
// Destruction steps
// =================
// 1. FormCloseQuery sets CanClose to FALSE, destroys CEFWindowParent1 and calls TChromium.CloseBrowser which triggers the TChromium.OnBeforeClose event.
// 2. TChromium.OnBeforeClose sets FCanClose := True and sends WM_CLOSE to the form.

uses
    tesseractocr.pagelayout,
  tesseractocr.utils,
  tesseractocr.capi,
  uCEFRequestContext, uCEFApplication;

procedure TChildForm.Button1Click(Sender: TObject);
begin
  Chromium1.LoadURL(Edit1.Text);
end;

procedure TChildForm.Button2Click(Sender: TObject);
begin
   ShowWindow(Handle, SW_RESTORE);
end;

procedure TChildForm.Button3Click(Sender: TObject);
   var
      Bitmap: TBitmap;
      WindowFound: Boolean;
      MaxAttempts, CurrentAttempt: Integer;
begin
  // Perform initial mouse actions on main thread
//  mouseMove([], 100, 100);
//  Sleep(100);
//  MouseDown(mbLeft, [], 100, 100);
//  Sleep(100);
//  MouseUp(mbLeft, [], 100, 100);


      // --- Step 2: Asynchronous Polling for Window Appearance ---
//      WindowFound := False;
//      MaxAttempts := 1; // Try for ~10 seconds (20 * 500ms sleep + processing time)
//      CurrentAttempt := 0;
//
//      while (not WindowFound) and (CurrentAttempt < MaxAttempts) do
//      begin
//        Inc(CurrentAttempt);


//            Bitmap := captureScreenshot();
            Bitmap := captureScreenshot2;

        // Use OpenCV to check the bitmap
        if Bitmap <> nil then
        begin
//          try
            // WindowFound := searchImage(templateGoToLocation, 0.6);
            image1.picture.Bitmap.Assign(bitmap);
//          finally
//            Bitmap.Free; // Clean up the bitmap resource
//          end;
//        end;

//        if not WindowFound then
//          Sleep(500); // Wait before the next attempt
      end;

      // --- Step 3: Act if found, or exit if timeout ---
      if WindowFound then
      begin

//            ShowMessage('go to location found');

        // Enter values and click second button (Synchronous actions)
        // Simulate typing into the game window region
        // SimulateTypeValues('Some Text');
        // SimulateMouseClick(300, 400); // Click the OK button
      end;

end;

procedure TChildForm.Chromium1AfterCreated(Sender: TObject;
  const browser: ICefBrowser);
begin
  if assigned(FBrowserInfoCS) then
    try
      FBrowserInfoCS.Acquire;
      FInitialized := True;
    finally
      FBrowserInfoCS.Release;
    end;

  PostMessage(Handle, CEFBROWSER_CREATED, 0, 0);
end;

procedure TChildForm.Chromium1BeforeClose(Sender: TObject;
  const browser: ICefBrowser);
begin
  FCanClose := True;
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure TChildForm.Chromium1BeforePopup(Sender: TObject;
  const browser: ICefBrowser; const frame: ICefFrame; popup_id: Integer;
  const targetUrl, targetFrameName: ustring;
  targetDisposition: TCefWindowOpenDisposition; userGesture: Boolean;
  const popupFeatures: TCefPopupFeatures; var windowInfo: TCefWindowInfo;
  var client: ICefClient; var settings: TCefBrowserSettings;
  var extra_info: ICefDictionaryValue; var noJavascriptAccess: Boolean;
  var Result: Boolean);
begin
  // For simplicity, this demo blocks all popup windows and new tabs
  Result := (targetDisposition in [CEF_WOD_NEW_FOREGROUND_TAB,
    CEF_WOD_NEW_BACKGROUND_TAB, CEF_WOD_NEW_POPUP, CEF_WOD_NEW_WINDOW]);
end;

procedure TChildForm.Chromium1DevToolsMethodResult(      Sender     : TObject;
                                                        const browser    : ICefBrowser;
                                                              message_id : Integer;
                                                              success    : Boolean;
                                                        const result     : ICefValue);
var
  TempDict    : ICefDictionaryValue;
  TempValue   : ICefValue;
  TempResult  : WPARAM;
  TempCode    : integer;
  TempMessage : string;
begin
  FDevToolsMsgValue := '';
  TempResult        := 0;
  outputdebugstring('devtools result');

  if success then
    begin
    outputdebugstring('devtools result success');
      if (FPendingMsgID = DEVTOOLS_BROWSERINFO_MSGID) then
        begin
//          HandleBrowserInfo(result);
          FPendingMsgID := 0;
          exit;
        end
      else if (FPendingMsgID = DEVTOOLS_SCREENSHOT_MSGID) then
        begin
          TempResult := 1;
          FDevToolsMsgValue := '';

          if (result <> nil) then
          begin
            TempDict := result.GetDictionary;

            if (TempDict <> nil) and (TempDict.GetSize > 0) then
            begin
              TempValue := TempDict.GetValue('data');

              if (TempValue <> nil) and (TempValue.GetType = VTYPE_STRING) then
                FDevToolsMsgValue := TempValue.GetString;
            end;
          end;
        end
       else
        begin
          TempResult        := 1;
          FDevToolsMsgValue := '';

          if (result <> nil) then
            begin
              TempDict := result.GetDictionary;

              if (TempDict <> nil) and (TempDict.GetSize > 0) then
                begin
                  TempValue := TempDict.GetValue('data');

                  if (TempValue <> nil) and (TempValue.GetType = VTYPE_STRING) then
                    FDevToolsMsgValue := TempValue.GetString;
                end;
            end;
        end;
    end
   else
    if (result <> nil) then
      begin
         TempDict := result.GetDictionary;

        if (TempDict <> nil) then
          begin
            TempCode    := 0;
            TempMessage := '';
            TempValue   := TempDict.GetValue('code');

            if (TempValue <> nil) and (TempValue.GetType = VTYPE_INT) then
              TempCode := TempValue.GetInt;

            TempValue := TempDict.GetValue('message');

            if (TempValue <> nil) and (TempValue.GetType = VTYPE_STRING) then
              TempMessage := TempValue.GetString;

            if (length(TempMessage) > 0) then
              FDevToolsMsgValue := 'DevTools Error (' + inttostr(TempCode) + ') : ' + quotedstr(TempMessage);
          end;
      end;

  PostMessage(Handle, MINIBROWSER_DTDATA_AVLBL, TempResult, 0);
end;

//procedure TChildForm.Chromium1DevToolsMethodResult(Sender: TObject;
//  const browser: ICefBrowser; message_id: Integer; success: Boolean;
//  const Result: ICefValue);
//var
//  TempDict: ICefDictionaryValue;
//  TempValue: ICefValue;
//  TempResult: WPARAM;
//  TempCode: Integer;
//  TempMessage: string;
//begin
//  FDevToolsMsgValue := '';
//  TempResult := 0;
//
//  if success then
//  begin
//    if (FPendingMsgID = DEVTOOLS_SCREENSHOT_MSGID) then
//    begin
//      TempResult := 1;
//      FDevToolsMsgValue := '';
//
//      if (Result <> nil) then
//      begin
//        TempDict := Result.GetDictionary;
//
//        if (TempDict <> nil) and (TempDict.GetSize > 0) then
//        begin
//          TempValue := TempDict.GetValue('data');
//
//          if (TempValue <> nil) and (TempValue.GetType = VTYPE_STRING) then
//            FDevToolsMsgValue := TempValue.GetString;
//        end;
//      end;
//    end;
//  end
//  else if (Result <> nil) then
//  begin
//    TempDict := Result.GetDictionary;
//
//    if (TempDict <> nil) then
//    begin
//      TempCode := 0;
//      TempMessage := '';
//      TempValue := TempDict.GetValue('code');
//
//      if (TempValue <> nil) and (TempValue.GetType = VTYPE_INT) then
//        TempCode := TempValue.GetInt;
//
//      TempValue := TempDict.GetValue('message');
//
//      if (TempValue <> nil) and (TempValue.GetType = VTYPE_STRING) then
//        TempMessage := TempValue.GetString;
//
//      if (length(TempMessage) > 0) then
//        FDevToolsMsgValue := 'DevTools Error (' + inttostr(TempCode) + ') : ' +
//          quotedstr(TempMessage);
//    end;
//  end;
//
//  PostMessage(Handle, MINIBROWSER_DTDATA_AVLBL, TempResult, 0);
//end;

procedure TChildForm.Chromium1GetScreenInfo(Sender: TObject;
  const browser: ICefBrowser; var screenInfo: TCefScreenInfo;
  out Result: Boolean);
var
  TempRect: TCefRect;
  TempScale: single;
begin
//  TempScale := CEFWindowParent1.ScaleFactor;
//  TempRect.X := 0;
//  TempRect.Y := 0;
//  TempRect.width := DeviceToLogical(Panel1.width, TempScale);
//  TempRect.height := DeviceToLogical(Panel1.height, TempScale);
//
//  screenInfo.device_scale_factor := TempScale;
//  screenInfo.depth := 0;
//  screenInfo.depth_per_component := 0;
//  screenInfo.is_monochrome := Ord(False);
//  screenInfo.rect := TempRect;
//  screenInfo.available_rect := TempRect;
//
//  Result := True;
end;

procedure TChildForm.Chromium1GetScreenPoint(Sender: TObject;
  const browser: ICefBrowser; viewX, viewY: Integer;
  var screenX, screenY: Integer; out Result: Boolean);
var
  TempScreenPt, TempViewPt: TPoint;
  TempScale: single;
begin
//  TempScale := CEFWindowParent1.ScaleFactor;
//  TempViewPt.X := LogicalToDevice(viewX, TempScale);
//  TempViewPt.Y := LogicalToDevice(viewY, TempScale);
//  TempScreenPt := Panel1.ClientToScreen(TempViewPt);
//  screenX := TempScreenPt.X;
//  screenY := TempScreenPt.Y;
//  Result := True;
end;

procedure TChildForm.Chromium1GetViewRect(Sender: TObject;
  const browser: ICefBrowser; var rect: TCefRect);
var
  TempScale: single;
begin
//  TempScale := CEFWindowParent1.ScaleFactor;
//  rect.X := 0;
//  rect.Y := 0;
//  rect.width := DeviceToLogical(Panel1.width, TempScale);
//  rect.height := DeviceToLogical(Panel1.height, TempScale);
end;

procedure TChildForm.DevToolsDataAvailableMsg(var aMessage: TMessage);
var
  TempData: TBytes;
  TempFile: TFileStream;
  TempLen: Integer;
  Stream: TMemoryStream;
  png:  TPngImage;
begin
outputdebugstring('DevToolsDataAvailableMsg');
  if (aMessage.WPARAM <> 0) then
  begin

    if (length(FDevToolsMsgValue) > 0) then
    begin

      TempData := nil;

      case FPendingMsgID of
        DEVTOOLS_SCREENSHOT_MSGID:
          begin

            // SaveDialog1.DefaultExt := 'png';
            // SaveDialog1.Filter     := 'PNG files (*.png)|*.PNG';
{$IFDEF DELPHI21_UP}
            // TO-DO: TNetEncoding was a new feature in Delphi XE7. Replace
            // TNetEncoding.Base64.DecodeStringToBytes with Soap.EncdDecd.DecodeBase64 for older Delphi versions
            TempData := TNetEncoding.Base64.DecodeStringToBytes
              (FDevToolsMsgValue);
//            outputdebugstring(pchar(tempdata));
            Stream := TMemoryStream.Create;
            try
              Stream.WriteBuffer(TempData[0], length(TempData));
              Stream.Position := 0; // Reset stream position to start

              Png := TPngImage.Create;
              try
                Png.LoadFromStream(Stream);
                screenshot := TBitmap.Create;
                screenshot.Assign(Png);
                outputdebugstring('sending signal');
                 FSyncEvent.SetEvent; // Signal the waiting thread that data is ready
              finally
                Png.Free;
              end;


            finally
              Stream.Free;
            end;

{$ENDIF}
          end;

      end;

      FPendingMsgID := 0;
      TempLen := length(TempData);

      // if (TempLen > 0) then
      // begin
      // TempFile := nil;
      //
      // if SaveDialog1.Execute then
      // try
      // try
      // TempFile := TFileStream.Create(SaveDialog1.FileName, fmCreate);
      // TempFile.WriteBuffer(TempData[0], TempLen);
      // showmessage('File saved successfully');
      // except
      // showmessage('There was an error saving the file');
      // end;
      // finally
      // if (TempFile <> nil) then TempFile.Free;
      // end;
      // end
      // else
      // showmessage('There was an error decoding the data');
    end
//    else
//      showmessage('DevTools method executed successfully!');
  end
  else if (length(FDevToolsMsgValue) > 0) then
    showmessage(FDevToolsMsgValue)
//  else
//    showmessage('There was an error in the DevTools method');
end;

procedure TChildForm.Chromium1LoadingStateChange(Sender: TObject;
  const browser: ICefBrowser; isLoading, canGoBack, canGoForward: Boolean);
begin
  if isLoading then
  begin
    StatusBar1.Panels[0].Text := 'Loading...';
    cursor := crAppStart;
  end
  else
  begin
    StatusBar1.Panels[0].Text := '';
    cursor := crDefault;
  end;
end;

function TChildForm.CancelPreviousClick(X, Y: Integer;
  var aCurrentTime: Integer): Boolean;
begin
  aCurrentTime := GetMessageTime;

  Result := (abs(FLastClickPoint.X - X) > (GetSystemMetrics(SM_CXDOUBLECLK)
    div 2)) or (abs(FLastClickPoint.Y - Y) > (GetSystemMetrics(SM_CYDOUBLECLK)
    div 2)) or (cardinal(aCurrentTime - FLastClickTime) > GetDoubleClickTime);
end;

procedure TChildForm.InitializeLastClick;
begin
  FLastClickCount := 1;
  FLastClickTime := 0;
  FLastClickPoint.X := 0;
  FLastClickPoint.Y := 0;
  FLastClickButton := mbLeft;
end;

function TChildForm.getModifiers(Shift: TShiftState): TCefEventFlags;
begin
  Result := EVENTFLAG_NONE;

  if (ssShift in Shift) then
    Result := Result or EVENTFLAG_SHIFT_DOWN;
  if (ssAlt in Shift) then
    Result := Result or EVENTFLAG_ALT_DOWN;
  if (ssCtrl in Shift) then
    Result := Result or EVENTFLAG_CONTROL_DOWN;
  if (ssLeft in Shift) then
    Result := Result or EVENTFLAG_LEFT_MOUSE_BUTTON;
  if (ssRight in Shift) then
    Result := Result or EVENTFLAG_RIGHT_MOUSE_BUTTON;
  if (ssMiddle in Shift) then
    Result := Result or EVENTFLAG_MIDDLE_MOUSE_BUTTON;
end;

function TChildForm.GetButton(Button: TMouseButton): TCefMouseButtonType;
begin
  case Button of
    mbRight:
      Result := MBT_RIGHT;
    mbMiddle:
      Result := MBT_MIDDLE;
  else
    Result := MBT_LEFT;
  end;
end;

procedure TChildForm.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  TempEvent: TCefMouseEvent;
  TempTime: Integer;
begin
{$IFDEF DELPHI14_UP}
  if (ssTouch in Shift) then
    exit;
{$ENDIF}
  // Panel1.SetFocus;

  if not(CancelPreviousClick(X, Y, TempTime)) and (Button = FLastClickButton)
  then
    inc(FLastClickCount)
  else
  begin
    FLastClickPoint.X := X;
    FLastClickPoint.Y := Y;
    FLastClickCount := 1;
  end;

  FLastClickTime := TempTime;
  FLastClickButton := Button;

  TempEvent.X := X;
  TempEvent.Y := Y;
  TempEvent.modifiers := getModifiers(Shift);
  // DeviceToLogical(TempEvent, Panel1.ScreenScale);
  // Optional: If you are using High-DPI scaling, you may need to convert logical to device coordinates.
  DeviceToLogical(TempEvent, GlobalCEFApp.DeviceScaleFactor);
  // Use if necessary

//  outputdebugstring(pchar('sending mouse down ' + inttostr(X) + ' , ' +
//    inttostr(Y)));
  Chromium1.SendMouseClickEvent(@TempEvent, GetButton(Button), False,
    FLastClickCount);
end;

procedure TChildForm.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  TempEvent: TCefMouseEvent;
begin
{$IFDEF DELPHI14_UP}
  if (ssTouch in Shift) then
    exit;
{$ENDIF}
  TempEvent.X := X;
  TempEvent.Y := Y;
  TempEvent.modifiers := getModifiers(Shift);
  // DeviceToLogical(TempEvent, Panel1.ScreenScale);
  DeviceToLogical(TempEvent, GlobalCEFApp.DeviceScaleFactor);
  // Use if necessary
//  outputdebugstring(pchar('sending mouse up ' + inttostr(X) + ' , ' +
//    inttostr(Y)));
//  outputdebugstring(pchar('sending mouse up ' + inttostr(TempEvent.X) + ' , ' +
//    inttostr(TempEvent.Y)));
  Chromium1.SendMouseClickEvent(@TempEvent, GetButton(Button), True,
    FLastClickCount);
end;

procedure TChildForm.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  TempEvent: TCefMouseEvent;
  TempTime: Integer;
begin
{$IFDEF DELPHI14_UP}
  if (ssTouch in Shift) then
    exit;
{$ENDIF}
  if CancelPreviousClick(X, Y, TempTime) then
    InitializeLastClick;

  TempEvent.X := X;
  TempEvent.Y := Y;
  TempEvent.modifiers := getModifiers(Shift);
  // DeviceToLogical(TempEvent, Panel1.ScreenScale);
  DeviceToLogical(TempEvent, GlobalCEFApp.DeviceScaleFactor);
  // Use if necessary


  // TempPoint                := cefwindowparent1.ScreenToclient(TempPoint);
  // DeviceToLogical(TempMouseEvent, cefwindowparent1.ScaleFactor);

  Chromium1.SendMouseMoveEvent(@TempEvent, False);

  StatusBar1.Panels[0].Text := 'pos : ' + inttostr(X) + ' , ' + inttostr(Y);
end;

procedure TChildForm.MouseLeave(Sender: TObject);
var
  TempEvent: TCefMouseEvent;
  TempPoint: TPoint;
  TempTime: Integer;
begin
  GetCursorPos(TempPoint);
  TempPoint := CEFWindowParent1.ScreenToclient(TempPoint);

  if CancelPreviousClick(TempPoint.X, TempPoint.Y, TempTime) then
    InitializeLastClick;

  TempEvent.X := TempPoint.X;
  TempEvent.Y := TempPoint.Y;
  TempEvent.modifiers := GetCefMouseModifiers;
  DeviceToLogical(TempEvent, CEFWindowParent1.ScaleFactor);
  Chromium1.SendMouseMoveEvent(@TempEvent, True);
end;


procedure TChildForm.Chromium1BrowserCompMsg(Sender: TObject; var aMessage: TMessage;
  var aHandled: Boolean);
var
  X, Y: Integer;
  child: TChildForm;
  i: Integer;
  LocalP, TempPoint: TPoint;
begin

//
// if FClosing then
//    exit;
//  if not IsScrollLockOn then
//    exit;
//
//  X := aMessage.lParam and $FFFF;
//  Y := (aMessage.lParam and $FFFF0000) shr 16;
//
//  for i := 0 to Application.MainForm.MDIChildCount - 1 do
//  begin
//    child := TChildForm(Application.MainForm.MDIChildren[i]);
//    if child <> Self then
//    begin
//      case aMessage.Msg of
//        WM_SETFOCUS,      //   = $0007;
//        WM_KILLFOCUS ,     //  = $0008;
//         WM_PAINT ,       //    = $000F;
//         WM_ERASEBKGND, //       = $0014;
//        WM_TABLET_MAXOFFSET, // 32  o $20
//         WM_CHILDACTIVATE  , //  = $0022;
//        WM_WINDOWPOSCHANGING, // = $0046;
//          WM_NCPAINT      , //    = $0085;
//            WM_PARENTNOTIFY , //    = $0210;
//          WM_CAPTURECHANGED, //   = 533;
//           WM_IME_SETCONTEXT,            //  = $0281;
//  WM_IME_NOTIFY ,                // = $0282;
//        132:
//          begin
//          end;
//        WM_MOUSEMOVE:
//          begin
//            child.MouseMove([], X, Y);
//            StatusBar1.Panels[0].Text := 'pos : ' + inttostr(X) + ' , ' + inttostr(Y);
//          end;
//        WM_LBUTTONDOWN:
//          begin
//            outputdebugstring(pchar('Chromium1BrowserCompMsg: mouse event WM_LBUTTONDOWN ' +
//              inttostr(aMessage.Msg)));
//             child.MouseDown(mbLeft, [], X, Y);
//          end;
//        WM_RBUTTONDOWN:
//          begin
//            outputdebugstring(pchar('Chromium1BrowserCompMsg: mouse event WM_RBUTTONDOWN ' +
//              inttostr(aMessage.Msg)));
//            child.MouseDown(mbRight, [], X, Y);
//          end;
//        WM_LBUTTONUP:
//          begin
//            outputdebugstring(pchar('Chromium1BrowserCompMsg: mouse event WM_LBUTTONUP ' +
//              inttostr(aMessage.Msg)));
//            child.MouseUp(mbLeft, [], X, Y);
//          end;
//        WM_RBUTTONUP:
//          begin
//            outputdebugstring(pchar('Chromium1BrowserCompMsg: mouse event WM_RBUTTONUP ' +
//              inttostr(aMessage.Msg)));
//            child.MouseUp(mbRight, [], X, Y);
//          end;
//        WM_MOUSELEAVE:
//          begin
//            outputdebugstring(pchar('Chromium1BrowserCompMsg: mouse event WM_MOUSELEAVE ' +
//              inttostr(aMessage.Msg)));
//          end;
//
//      else
//        begin
//
////          outputdebugstring(pchar('browsercompmsg '+inttostr(amessage.msg)));
//        end;
//      end;
//    end;
//  end;
end;

procedure TChildForm.Chromium1RenderCompMsg(Sender: TObject;
  var aMessage: TMessage; var aHandled: Boolean);
var
  X, Y: Integer;
//  child: TChildForm;
//  i: Integer;
//  LocalP, TempPoint: TPoint;
begin
//
  if FClosing then
    exit;
//  if not IsScrollLockOn then
//    exit;
//
  X := aMessage.lParam and $FFFF;
  Y := (aMessage.lParam and $FFFF0000) shr 16;
//
//  for i := 0 to Application.MainForm.MDIChildCount - 1 do
//  begin
//    child := TChildForm(Application.MainForm.MDIChildren[i]);
//    if child <> Self then
//    begin
      case aMessage.Msg of
//        WM_TABLET_MAXOFFSET:
//          begin
//            // 32  o $20
//          end;
//        132:
//          begin
//          end;
//        WM_MOUSEMOVE:
//          begin
//            child.MouseMove([], X, Y);
//            StatusBar1.Panels[0].Text := 'pos : ' + inttostr(X) + ' , ' + inttostr(Y);
//          end;
        WM_LBUTTONDOWN:
          begin
            outputdebugstring(pchar('Chromium1RenderCompMsg: mouse event WM_LBUTTONDOWN ' +
              inttostr(aMessage.Msg)+' coords '+  inttostr(x)+','+  inttostr(y)));
//            child.MouseDown(mbLeft, [], X, Y);
          end;
//        WM_RBUTTONDOWN:
//          begin
//            outputdebugstring(pchar('Chromium1RenderCompMsg: mouse event WM_RBUTTONDOWN ' +
//              inttostr(aMessage.Msg)));
//            child.MouseDown(mbRight, [], X, Y);
//          end;
//        WM_LBUTTONUP:
//          begin
//            outputdebugstring(pchar('Chromium1RenderCompMsg: mouse event WM_LBUTTONUP ' +
//              inttostr(aMessage.Msg)));
//            child.MouseUp(mbLeft, [], X, Y);
//          end;
//        WM_RBUTTONUP:
//          begin
//            outputdebugstring(pchar('Chromium1RenderCompMsg: mouse event WM_RBUTTONUP ' +
//              inttostr(aMessage.Msg)));
//            child.MouseUp(mbRight, [], X, Y);
//          end;
//        WM_MOUSELEAVE:
//          begin
//            outputdebugstring(pchar('Chromium1RenderCompMsg: mouse event WM_MOUSELEAVE ' +
//              inttostr(aMessage.Msg)));
//          end;
//
//      else
//        begin
////          outputdebugstring(pchar('event ' + inttostr(aMessage.Msg)));
//        end;
      end;
//
//    end;
//  end;
end;

procedure TChildForm.Chromium1StatusMessage(Sender: TObject;
  const browser: ICefBrowser; const value: ustring);
begin
  StatusBar1.Panels[1].Text := value;
end;

procedure TChildForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TChildForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := (Chromium1.BrowserId = 0) or FCanClose;

  if not(FClosing) and Panel1.Enabled then
  begin
    FClosing := True;
    Panel1.Enabled := False;
    Chromium1.CloseBrowser(True);
    CEFWindowParent1.Free;
  end;
end;

procedure TChildForm.FormCreate(Sender: TObject);
begin
  FCanClose := False;
  FClosing := False;

  screenshot := TBitmap.Create;
   FSyncEvent := TEvent.Create(nil, True, False, 'ScreenshotEvent');

  FBrowserInfoCS := TCriticalSection.Create;
  outputdebugstring(pchar(ExtractFilePath(Application.ExeName)+'DLL\'));
    Tesseract                     := TTesseractOCR5.Create(ExtractFilePath(Application.ExeName)+'DLL\');
//  Tesseract.OnRecognizeBegin    := OnRecognizeBegin;
//  Tesseract.OnRecognizeProgress := OnRecognizeProgress;
//  Tesseract.OnRecognizeEnd      := OnRecognizeEnd;
  if not Tesseract.Initialize( 'tessdata\', 'eng') then
  begin
    MessageDlg('Error loading Tesseract data', mtError, [mbOk], 0);
    Close;
  end;

  InitializeLastClick;
end;

procedure TChildForm.FormDestroy(Sender: TObject);
begin
  if (FBrowserInfoCS <> nil) then
    FreeAndNil(FBrowserInfoCS);

FreeAndNil(Tesseract);
 FreeAndNil(FSyncEvent);
  screenshot.Free;
  // Tell the main form that a child has been destroyed.
  // The main form will check if this was the last child to close itself
  PostMessage(MainForm.Handle, CEFBROWSER_CHILDDESTROYED, 0, 0);
end;

procedure TChildForm.FormResize(Sender: TObject);
var
  child : TChildForm;
begin
  for var i := 0 to Application.MainForm.MDIChildCount - 1 do
  begin
    child := TChildForm(Application.MainForm.MDIChildren[i]);
    if child <> Self then
    begin
      child.Width:=width;
      child.Height:=height;
    end;
    end;
end;

procedure TChildForm.FormShow(Sender: TObject);
var
  TempContext: ICefRequestContext;
  TempCache: string;
begin
  try
    // The new request context overrides several GlobalCEFApp properties like :
    // cache, AcceptLanguageList, PersistSessionCookies, PersistUserPreferences and
    // IgnoreCertificateErrors

    // If you use an empty cache path, CEF will use in-memory cache.

    // The cache directories of all the browsers *MUST* be a subdirectory of
    // GlobalCEFApp.RootCache unless you use a blank cache (in-memory).

    // if MainForm.NewContextChk.Checked then
    // begin
    // if MainForm.IncognitoChk.Checked then
    // TempCache := ''
    // else
    TempCache := GlobalCEFApp.RootCache + '\cache' +
      inttostr(id);

    TempContext := TCefRequestContextRef.New(TempCache, '', '', False, False,
      Chromium1.ReqContextHandler);
    // end
    // else
    // TempContext := nil;

    {
      // This would be a good place to set the proxy server settings for all your child
      // browsers if you use a proxy
      Chromium1.ProxyType     := CEF_PROXYTYPE_FIXED_SERVERS;
      Chromium1.ProxyScheme   := psHTTP;
      Chromium1.ProxyServer   := '1.2.3.4';
      Chromium1.ProxyPort     := 1234;
      Chromium1.ProxyUsername := '';
      Chromium1.ProxyPassword := '';
    }

    Chromium1.DefaultURL := Edit1.Text;

      // GlobalCEFApp.GlobalContextInitialized has to be TRUE before creating any browser
  // If it's not initialized yet, we use a simple timer to create the browser later.
  if not(Chromium1.CreateBrowser(CEFWindowParent1, '', TempContext)) then Timer1.Enabled := True;

//    Chromium1.CreateBrowser(CEFWindowParent1, '', TempContext);
  finally
    TempContext := nil;
  end;
end;

procedure TChildForm.Timer1Timer(Sender: TObject);
var
  TempContext: ICefRequestContext;
  TempCache: string;
begin
  TempCache := GlobalCEFApp.RootCache + '\cache' +
      inttostr(id);

    TempContext := TCefRequestContextRef.New(TempCache, '', '', False, False,
      Chromium1.ReqContextHandler);

  Timer1.Enabled := False;
  if not(Chromium1.CreateBrowser(CEFWindowParent1, '',TempContext)) and not(Chromium1.Initialized) then
    Timer1.Enabled := True;
end;

procedure TChildForm.WMMove(var aMessage: TWMMove);
begin
  inherited;

  if (Chromium1 <> nil) then
    Chromium1.NotifyMoveOrResizeStarted;
end;

procedure TChildForm.WMMoving(var aMessage: TMessage);
begin
  inherited;

  if (Chromium1 <> nil) then
    Chromium1.NotifyMoveOrResizeStarted;
end;

procedure TChildForm.WMEnterMenuLoop(var aMessage: TMessage);
begin
  inherited;

  if (aMessage.WPARAM = 0) and (GlobalCEFApp <> nil) then
    GlobalCEFApp.OsmodalLoop := True;
end;

procedure TChildForm.WMExitMenuLoop(var aMessage: TMessage);
begin
  inherited;

  if (aMessage.WPARAM = 0) and (GlobalCEFApp <> nil) then
    GlobalCEFApp.OsmodalLoop := False;
end;

procedure TChildForm.BrowserCreatedMsg(var aMessage: TMessage);
begin
  CEFWindowParent1.UpdateSize;
  Panel1.Enabled := True;
end;

function TChildForm.captureScreenshot2: TBitmap;
var
Bitmap: TBitmap;
//  R: TRect;
  DC: HDC;
   FullWidth, FullHeight: Integer;
begin
  FullWidth := CEFWindowParent1.Width;
  FullHeight := CEFWindowParent1.Height;
  outputdebugstring(pchar('cef size: '+inttostr(fullwidth)+',,'+inttostr(fullheight)));
  result:=nil;

  Bitmap := TBitmap.Create;
  try
    Bitmap.Width := FullWidth;
    Bitmap.Height := FullHeight;
    // Get the Device Context (DC) of the control you want to capture (e.g., ScrollBox1.Handle)
//    DC := GetDC(ScrollBox1.Handle);
    try
//      R := Rect(0, 0, FullWidth, FullHeight);

      // Use BitBlt to copy the *entire* canvas content to the bitmap's canvas
//      BitBlt(
//        Bitmap.Canvas.Handle, // Destination DC
//        0, 0,                 // Destination X, Y
//        FullWidth,            // Width
//        FullHeight,           // Height
//        DC,                   // Source DC
//        0, 0,                 // Source X, Y (start from top-left of logical area)
//        SRCCOPY               // Raster operation code
//      );
//      cefwindowparent1.PaintTo(Bitmap.Canvas.Handle, 0, 0);
//         chromium1.TakeSnapshot(bitmap);

      // Now the Bitmap contains the full screenshot
      // You can assign it to an Image component, save it to a file, or copy to the clipboard
      // Image1.Picture.Bitmap.Assign(Bitmap);
        Bitmap.SaveToFile('FullScreenshot.bmp');
//      ShowMessage('Full screenshot captured to bitmap.');
    result:=Bitmap;

    finally
//      ReleaseDC(ScrollBox1.Handle, DC); // Release the DC
    end;
  finally
    Bitmap.Free;
  end;
end;

function TChildForm.captureScreenshot: TBitmap;
begin
  Result := nil;

  if not Initialized then
  begin
    OutputDebugString('chromium not initialized');
    Exit;
  end;

  try
    // Reset the event and data string before initiating a new capture
    outputdebugstring('reset event');
    FSyncEvent.ResetEvent;

    // Clear any previous screenshot
    if Assigned(screenshot) then
    begin
      screenshot.Free;
      screenshot := nil;
    end;

    FPendingMsgID := DEVTOOLS_SCREENSHOT_MSGID;

    // Execute DevTools method
    outputdebugstring('starting capturescreenshot');
    if Chromium1.ExecuteDevToolsMethod(0, 'Page.captureScreenshot', nil)<>0 then
      outputdebugstring('ExecuteDevToolsMethod returned true')
    else
      outputdebugstring('ExecuteDevToolsMethod returned false');



    // Wait for the DevTools event handler to signal completion
    // Wait up to 5 seconds
    if FSyncEvent.WaitFor(10000) = wrSignaled then
    begin
      outputdebugstring('signal event completed');
      if Assigned(screenshot) then
      begin
        // Create a copy of the screenshot to return
        Result := TBitmap.Create;
        Result.Assign(screenshot);

      end
      else
        OutputDebugString('Screenshot capture completed but no bitmap created');
    end
    else begin
      OutputDebugString('Screenshot capture timed out');
    end;

  except
    on E: Exception do
    begin
      OutputDebugString(PChar('Error in captureScreenshot: ' + E.Message));
      if Assigned(Result) then
      begin
        Result.Free;
        Result := nil;
      end;
    end;
  end;
end;

function TChildForm.searchImage(TemplateImg: pCvMat_t; threshold: Double):boolean;
var
  matchCount: Double;
begin
  if TemplateImg = nil then
    exit;
  // if panel1.Buffer = nil then exit;
  if screenshot = nil then
    exit;

   result:=false;
  try

    matchCount := PerformTemplateMatching(screenshot, TemplateImg, threshold);

    if not isInfinite(matchCount) then
    begin
      Self.Caption := floatTostr(matchCount);

      if matchCount > threshold then
      begin
        playBeep();
         result:=true;
      end;
    end;
  finally
    screenshot.Free;
  end;
end;

//procedure TChildForm.sendESCKey;
//var
//  TempKeyEvent: TCefKeyEvent;
//begin
//  // Debug Output: key 27 :: 65537 Process syncBrowser.exe (21888)
//  TempKeyEvent.kind := KEYEVENT_CHAR;
//  TempKeyEvent.modifiers := EVENTFLAG_NONE;
//  // GetCefKeyboardModifiers(27, 65537);
//  TempKeyEvent.windows_key_code := 27;
//  TempKeyEvent.native_key_code := 65537;
//  TempKeyEvent.is_system_key := Ord(False);
//  TempKeyEvent.character := #0;
//  TempKeyEvent.unmodified_character := #0;
//  TempKeyEvent.focus_on_editable_field := Ord(False);
//
//  // CefCheckAltGrPressed(27, TempKeyEvent);
//{$IFDEF DEBUG}
//  CefKeyEventLog(TempKeyEvent);
//{$ENDIF}
//  Chromium1.SendKeyEvent(@TempKeyEvent);
//
//end;



function TChildForm.GetInitialized: Boolean;
begin
  Result := False;

  if assigned(FBrowserInfoCS) then
    try
      FBrowserInfoCS.Acquire;
      Result := FInitialized and Chromium1.Initialized;
    finally
      FBrowserInfoCS.Release;
    end;
end;

end.
