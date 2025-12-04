unit uSimpleOSRBrowser;

{$I D:\downloads\delphi.components\CEF4Delphi\source\cef.inc}

interface

uses
{$IFDEF DELPHI16_UP}
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes,
  System.SyncObjs, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.AppEvnts, Winapi.imm, Vcl.ComCtrls, System.UITypes,
{$ELSE}
  Windows, Messages, SysUtils, Variants, Classes, SyncObjs,
  Graphics, Controls, Forms, Dialogs, StdCtrls, ExtCtrls, AppEvnts, ComCtrls,
  UITypes,
{$ENDIF}
  System.StrUtils,
  System.Generics.Collections,
{$IFDEF DELPHI21_UP}System.NetEncoding, {$ENDIF} unit3, OPENCVWrapper,
  System.Threading, tesseractocr, System.RegularExpressions,
  uCEFChromium, uCEFTypes, uCEFInterfaces, uCEFConstants, uCEFBufferPanel,
  uCEFChromiumCore, Vcl.Samples.Spin;

const
  // Set this constant to True and load "file://transparency.html" to test a
  // transparent browser.
  TRANSPARENT_BROWSER = False;
  CEFBROWSER_SHOWJSDIALOG = WM_APP + $A10;
  CEFBROWSER_CREATED = WM_APP + $100;
  CEFBROWSER_CHILDDESTROYED = WM_APP + $101;
  CEFBROWSER_DESTROY = WM_APP + $102;
  CEFBROWSER_INITIALIZED = WM_APP + $103;
  DEVTOOLS_SCREENSHOT_MSGID = 1001;
  MINIBROWSER_DTDATA_AVLBL = WM_APP + $10E;

type
  TDirection = (dirRight, dirLeft);

  TGameState = record
    LastKnownX: Integer;
    CurrentDirection: TDirection; // Enum: dirRight, dirLeft
    OcrFailsInARow: Integer;
    LastOcrSuccessTime: TDateTime;
    // Add other relevant game boundaries here
  end;

  TForm1 = class(TForm)
    NavControlPnl: TPanel;
    chrmosr: TChromium;
    AppEvents: TApplicationEvents;
    AddressCb: TComboBox;
    Panel2: TPanel;
    GoBtn: TButton;
    SnapshotBtn: TButton;
    SaveDialog1: TSaveDialog;
    Timer1: TTimer;
    Button1: TButton;
    Button2: TButton;
    Image1: TImage;
    Panel1: TBufferPanel;
    Memo1: TMemo;
    memoKingdoms: TMemo;
    Button3: TButton;
    Image2: TImage;
    Image3: TImage;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    panelOverlay: TPanel;
    chkBrowserLock: TCheckBox;
    seDelay: TSpinEdit;
    Label1: TLabel;
    Timer2: TTimer;
    chkToRight: TCheckBox;
    Button4: TButton;
    chkReloading: TCheckBox;
    btnRotate: TButton;

    procedure AppEventsMessage(var Msg: tagMSG; var Handled: Boolean);

    procedure GoBtnClick(Sender: TObject);
    procedure GoBtnEnter(Sender: TObject);

    procedure Panel1Enter(Sender: TObject);
    procedure Panel1Exit(Sender: TObject);
    procedure Panel1Resize(Sender: TObject);

    procedure pClick;
    procedure Panel1Click(Sender: TObject);

    procedure Panel1PaintParentBkg(Sender: TObject);

    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer);
    procedure Panel1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);

    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Panel1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);

    procedure MouseMove(Shift: TShiftState; X, Y: Integer);
    procedure Panel1MouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);

    procedure Panel1MouseLeave(Sender: TObject);
    procedure Panel1IMECancelComposition(Sender: TObject);
    procedure Panel1IMECommitText(Sender: TObject; const aText: ustring;
      const replacement_range: PCefRange; relative_cursor_pos: Integer);
    procedure Panel1IMESetComposition(Sender: TObject; const aText: ustring;
      const underlines: TCefCompositionUnderlineDynArray;
      const replacement_range, selection_range: TCefRange);
    procedure Panel1CustomTouch(Sender: TObject; var aMessage: TMessage;
      var aHandled: Boolean);
    procedure Panel1PointerDown(Sender: TObject; var aMessage: TMessage;
      var aHandled: Boolean);
    procedure Panel1PointerUp(Sender: TObject; var aMessage: TMessage;
      var aHandled: Boolean);
    procedure Panel1PointerUpdate(Sender: TObject; var aMessage: TMessage;
      var aHandled: Boolean);

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure FormAfterMonitorDpiChanged(Sender: TObject;
      OldDPI, NewDPI: Integer);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);

    procedure chrmosrPaint(Sender: TObject; const browser: ICefBrowser;
      kind: TCefPaintElementType; dirtyRectsCount: NativeUInt;
      const dirtyRects: PCefRectArray; const buffer: Pointer;
      width, height: Integer);
    procedure chrmosrCursorChange(Sender: TObject; const browser: ICefBrowser;
      cursor_: TCefCursorHandle; cursorType: TCefCursorType;
      const customCursorInfo: PCefCursorInfo; var aResult: Boolean);
    procedure chrmosrGetViewRect(Sender: TObject; const browser: ICefBrowser;
      var rect: TCefRect);
    procedure chrmosrGetScreenPoint(Sender: TObject; const browser: ICefBrowser;
      viewX, viewY: Integer; var screenX, screenY: Integer;
      out Result: Boolean);
    procedure chrmosrGetScreenInfo(Sender: TObject; const browser: ICefBrowser;
      var screenInfo: TCefScreenInfo; out Result: Boolean);
    procedure chrmosrPopupShow(Sender: TObject; const browser: ICefBrowser;
      show: Boolean);
    procedure chrmosrPopupSize(Sender: TObject; const browser: ICefBrowser;
      const rect: PCefRect);
    procedure chrmosrAfterCreated(Sender: TObject; const browser: ICefBrowser);
    procedure chrmosrTooltip(Sender: TObject; const browser: ICefBrowser;
      var text: ustring; out Result: Boolean);
    procedure chrmosrBeforePopup(Sender: TObject; const browser: ICefBrowser;
      const frame: ICefFrame; popup_id: Integer;
      const targetUrl, targetFrameName: ustring;
      targetDisposition: TCefWindowOpenDisposition; userGesture: Boolean;
      const popupFeatures: TCefPopupFeatures; var windowInfo: TCefWindowInfo;
      var client: ICefClient; var settings: TCefBrowserSettings;
      var extra_info: ICefDictionaryValue; var noJavascriptAccess: Boolean;
      var Result: Boolean);
    procedure chrmosrBeforeClose(Sender: TObject; const browser: ICefBrowser);
    procedure chrmosrIMECompositionRangeChanged(Sender: TObject;
      const browser: ICefBrowser; const selected_range: PCefRange;
      character_boundsCount: NativeUInt; const character_bounds: PCefRect);
    procedure chrmosrCanFocus(Sender: TObject);

    procedure SnapshotBtnClick(Sender: TObject);
    procedure SnapshotBtnEnter(Sender: TObject);

    procedure Timer1Timer(Sender: TObject);
    procedure AddressCbEnter(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure chrmosrDevToolsMethodResult(Sender: TObject;
      const browser: ICefBrowser; message_id: Integer; success: Boolean;
      const Result: ICefValue);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure chrmosrConsoleMessage(Sender: TObject; const browser: ICefBrowser;
      level: TCefLogSeverity; const message, source: ustring; line: Integer;
      out Result: Boolean);
    procedure chkBrowserLockClick(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure chrmosrRenderProcessUnresponsive(Sender: TObject; const browser: ICefBrowser;
      const callback: ICefUnresponsiveProcessCallback; var aResult: Boolean);
    procedure chrmosrRenderProcessTerminated(Sender: TObject; const browser: ICefBrowser;
      status: TCefTerminationStatus; error_code: Integer; const error_string: ustring);
    procedure btnRotateClick(Sender: TObject);

  protected
    FPopUpBitmap: TBitmap;
    FPopUpRect: TRect;
    FShowPopUp: Boolean;
    FResizing: Boolean;
    FPendingResize: Boolean;
    FCanClose: Boolean;
    FClosing: Boolean;
    FResizeCS: TCriticalSection;
    FBrowserInfoCS: TCriticalSection;
    FIMECS: TCriticalSection;
    FDeviceBounds: TCefRectDynArray;
    FSelectedRange: TCefRange;
    FAtLeastWin8: Boolean;
    FInitialized: Boolean;

    FLastClickCount: Integer;
    FLastClickTime: Integer;
    FLastClickPoint: TPoint;
    FLastClickButton: TMouseButton;

    FPendingMsgID: Integer;
    FDevToolsMsgValue: ustring;

    prevYCoords:integer;


    FTask: ITask;
    haveClientError: Boolean;

    function getModifiers(Shift: TShiftState): TCefEventFlags;
    function GetButton(Button: TMouseButton): TCefMouseButtonType;
    procedure DoResize;
    procedure InitializeLastClick;
    function CancelPreviousClick(X, Y: Integer;
      var aCurrentTime: Integer): Boolean;
    function ArePointerEventsSupported: Boolean;
{$IFDEF DELPHI14_UP}
    function HandlePenEvent(const aID: uint32; aMsg: cardinal): Boolean;
    function HandleTouchEvent(const aID: uint32; aMsg: cardinal): Boolean;
    function HandlePointerEvent(var aMessage: TMessage): Boolean;
{$ENDIF}
    procedure WMMove(var aMessage: TWMMove); message WM_MOVE;
    procedure WMMoving(var aMessage: TMessage); message WM_MOVING;
    procedure WMCaptureChanged(var aMessage: TMessage);
      message WM_CAPTURECHANGED;
    procedure WMCancelMode(var aMessage: TMessage); message WM_CANCELMODE;
    procedure WMEnterMenuLoop(var aMessage: TMessage); message WM_ENTERMENULOOP;
    procedure WMExitMenuLoop(var aMessage: TMessage); message WM_EXITMENULOOP;
    procedure BrowserCreatedMsg(var aMessage: TMessage);
      message CEF_AFTERCREATED;
    procedure PendingResizeMsg(var aMessage: TMessage);
      message CEF_PENDINGRESIZE;
    procedure RangeChangedMsg(var aMessage: TMessage);
      message CEF_IMERANGECHANGED;
    procedure FocusEnabledMsg(var aMessage: TMessage); message CEF_FOCUSENABLED;
    procedure DevToolsDataAvailableMsg(var aMessage: TMessage);
      message MINIBROWSER_DTDATA_AVLBL;

    procedure SynchronizeMouseEvent(EventType: string;
      Button: TMouseButton = mbLeft; Shift: TShiftState = []; X: Integer = 0;
      Y: Integer = 0);

    function GetInitialized: Boolean;
  public
    id: cardinal;
    // screenshot: TBitmap;

    templateGoToLocation, TemplateImg: pCvMat_t;

    procedure captureScreenshot;
    function searchImage(TemplateImg: pCvMat_t; threshold: Double): Boolean;
    procedure sendESCKey;
    procedure sendBackspaceKey(keycode: byte);
    procedure ConvertToGrayscale(Bitmap: TBitmap);
    procedure inputdata(chars: string);
    function getXCoords(const prevCoordX: Integer; out coordX: Integer): Boolean;
    function getYCoords(const prevCoord: Integer; out coord: Integer): Boolean;

    property Closing: Boolean read FClosing;
    property Initialized: Boolean read GetInitialized;
  end;

var
  Form1: TForm1;

  // procedure CreateGlobalCEFApp;

implementation

{$R *.dfm}

uses
{$IFDEF DELPHI16_UP}
  System.Math,
{$ELSE}
  Math,
{$ENDIF}
  tesseractocr.pagelayout,
  tesseractocr.utils,
  tesseractocr.capi,

  uCEFRequestContext,
  uCEFMiscFunctions, uCEFApplication, uMainForm;

// Chromium renders the web contents asynchronously. It uses multiple processes
// and threads which makes it complicated to keep the correct browser size.

// In one hand you have the main application thread where the form is resized by
// the user. On the other hand, Chromium renders the contents asynchronously
// with the last browser size available, which may have changed by the time
// Chromium renders the page.

// For this reason we need to keep checking the real size and call
// TChromium.WasResized when we detect that Chromium has an incorrect size.

// TChromium.WasResized triggers the TChromium.OnGetViewRect event to let CEF
// read the current browser size and then it triggers TChromium.OnPaint when the
// contents are finally rendered.

// TChromium.WasResized --> (time passes) --> TChromium.OnGetViewRect --> (time passes) --> TChromium.OnPaint

// You have to assume that the real browser size can change between those calls
// and events.

// This demo uses a couple of fields called "FResizing" and "FPendingResize" to
// reduce the number of TChromium.WasResized calls.

// FResizing is set to True before the TChromium.WasResized call and it's set to
// False at the end of the TChromium.OnPaint event.

// FPendingResize is set to True when the browser changed its size while
// FResizing was True. The FPendingResize value is checked at the end of
// TChromium.OnPaint to check the browser size again because it changed while
// Chromium was rendering the page.

// The TChromium.OnPaint event in the demo also calls
// TBufferPanel.UpdateBufferDimensions and TBufferPanel.BufferIsResized to check
// the width and height of the buffer parameter, and the internal buffer size in
// the TBufferPanel component.

// **********************************************************************************************
// ************************************** ATTENTION! ********************************************
// **********************************************************************************************
// *                                                                                            *
// * If your Delphi/Lazarus version doesn't have full touch and pen support you will have       *
// * issues building this demo.                                                                 *
// *                                                                                            *
// * Some constants and types like POINTER_INPUT_TYPE, POINTER_PEN_INFO, etc. need to be        *
// * defined in order to test touch screens and pens on Windows.                                *
// *                                                                                            *
// * Try adding this unit made by Andreas Hausladen to the "uses" section if you get            *
// * "Undeclared identifier" errors :                                                           *
// * https://github.com/ahausladen/ObjectPascal-WinAPIs/blob/master/WinApi/WinApi.WMPointer.pas *
// *                                                                                            *
// **********************************************************************************************

// This is the destruction sequence in OSR mode :
// 1- FormCloseQuery sets CanClose to the initial FCanClose value (False) and
// calls chrmosr.CloseBrowser(True).
// 2- chrmosr.CloseBrowser(True) will trigger chrmosr.OnClose and we have to
// set "aAction" to cbaClose and CEF will destroy the internal browser immediately.
// cbaClose is the default aAction value so this demo doesn't implement the OnClose event.
// 3- chrmosr.OnBeforeClose is triggered because the internal browser was destroyed.
// Sets FCanClose := True and sends WM_CLOSE to the form to close the demo.

// procedure CreateGlobalCEFApp;
// begin
// GlobalCEFApp                            := TCefApplication.Create;
// GlobalCEFApp.WindowlessRenderingEnabled := True;
// GlobalCEFApp.TouchEvents                := STATE_ENABLED;
// GlobalCEFApp.EnableGPU                  := True;
// GlobalCEFApp.LogFile                    := 'debug.log';
// GlobalCEFApp.LogSeverity                := LOGSEVERITY_VERBOSE;
// //GlobalCEFApp.ChromeRuntime              := True;
//
// // If you need transparency leave the GlobalCEFApp.BackgroundColor property
// // with the default value or set the alpha channel to 0
// if TRANSPARENT_BROWSER then
// GlobalCEFApp.BackgroundColor := CefColorSetARGB($00, $00, $00, $00)
// else
// GlobalCEFApp.BackgroundColor := CefColorSetARGB($FF, $FF, $FF, $FF);
// end;

procedure TForm1.AppEventsMessage(var Msg: tagMSG; var Handled: Boolean);
var
  TempKeyEvent: TCefKeyEvent;
  TempMouseEvent: TCefMouseEvent;
  TempPoint: TPoint;
begin
  case Msg.message of
    WM_SYSCHAR:
      if Panel1.Focused then
      begin
        TempKeyEvent.kind := KEYEVENT_CHAR;
        TempKeyEvent.modifiers := GetCefKeyboardModifiers(Msg.wParam,
          Msg.lParam);
        TempKeyEvent.windows_key_code := Msg.wParam;
        TempKeyEvent.native_key_code := Msg.lParam;
        TempKeyEvent.is_system_key := ord(True);
        TempKeyEvent.character := #0;
        TempKeyEvent.unmodified_character := #0;
        TempKeyEvent.focus_on_editable_field := ord(False);

        CefCheckAltGrPressed(Msg.wParam, TempKeyEvent);
        chrmosr.SendKeyEvent(@TempKeyEvent);

        outputdebugstring(pchar('key sychar ' + inttostr(Msg.wParam) + ' :: ' +
          inttostr(Msg.lParam)));
      end;

    WM_SYSKEYDOWN:
      if Panel1.Focused then
      begin
        TempKeyEvent.kind := KEYEVENT_RAWKEYDOWN;
        TempKeyEvent.modifiers := GetCefKeyboardModifiers(Msg.wParam,
          Msg.lParam);
        TempKeyEvent.windows_key_code := Msg.wParam;
        TempKeyEvent.native_key_code := Msg.lParam;
        TempKeyEvent.is_system_key := ord(True);
        TempKeyEvent.character := #0;
        TempKeyEvent.unmodified_character := #0;
        TempKeyEvent.focus_on_editable_field := ord(False);

        chrmosr.SendKeyEvent(@TempKeyEvent);
        outputdebugstring(pchar('syskeydown ' + inttostr(Msg.wParam) + ' :: ' +
          inttostr(Msg.lParam)));
      end;

    WM_SYSKEYUP:
      if Panel1.Focused then
      begin
        TempKeyEvent.kind := KEYEVENT_KEYUP;
        TempKeyEvent.modifiers := GetCefKeyboardModifiers(Msg.wParam,
          Msg.lParam);
        TempKeyEvent.windows_key_code := Msg.wParam;
        TempKeyEvent.native_key_code := Msg.lParam;
        TempKeyEvent.is_system_key := ord(True);
        TempKeyEvent.character := #0;
        TempKeyEvent.unmodified_character := #0;
        TempKeyEvent.focus_on_editable_field := ord(False);

        chrmosr.SendKeyEvent(@TempKeyEvent);
        outputdebugstring(pchar('syskeyup ' + inttostr(Msg.wParam) + ' :: ' +
          inttostr(Msg.lParam)));
      end;

    WM_KEYDOWN:
      if Panel1.Focused then
      begin
        TempKeyEvent.kind := KEYEVENT_RAWKEYDOWN;
        TempKeyEvent.modifiers := GetCefKeyboardModifiers(Msg.wParam,
          Msg.lParam);
        TempKeyEvent.windows_key_code := Msg.wParam;
        TempKeyEvent.native_key_code := Msg.lParam;
        TempKeyEvent.is_system_key := ord(False);
        TempKeyEvent.character := #0;
        TempKeyEvent.unmodified_character := #0;
        TempKeyEvent.focus_on_editable_field := ord(False);
{$IFDEF DEBUG}
        CefKeyEventLog(TempKeyEvent);
{$ENDIF}
        chrmosr.SendKeyEvent(@TempKeyEvent);
        Handled := (Msg.wParam in [VK_LEFT, VK_RIGHT, VK_UP, VK_DOWN, VK_TAB]);

        outputdebugstring(pchar('keydown ' + inttostr(Msg.wParam) + ' :: ' +
          inttostr(Msg.lParam)));
      end;

    WM_KEYUP:
      if Panel1.Focused then
      begin
        TempKeyEvent.kind := KEYEVENT_KEYUP;
        TempKeyEvent.modifiers := GetCefKeyboardModifiers(Msg.wParam,
          Msg.lParam);
        TempKeyEvent.windows_key_code := Msg.wParam;
        TempKeyEvent.native_key_code := Msg.lParam;
        TempKeyEvent.is_system_key := ord(False);
        TempKeyEvent.character := #0;
        TempKeyEvent.unmodified_character := #0;
        TempKeyEvent.focus_on_editable_field := ord(False);
{$IFDEF DEBUG}
        CefKeyEventLog(TempKeyEvent);
{$ENDIF}
        chrmosr.SendKeyEvent(@TempKeyEvent);
        outputdebugstring(pchar('keyup ' + inttostr(Msg.wParam) + ' :: ' +
          inttostr(Msg.lParam)));
      end;

    WM_CHAR:
      if Panel1.Focused then
      begin
        TempKeyEvent.kind := KEYEVENT_CHAR;
        TempKeyEvent.modifiers := GetCefKeyboardModifiers(Msg.wParam,
          Msg.lParam);
        TempKeyEvent.windows_key_code := Msg.wParam; // 8
        TempKeyEvent.native_key_code := Msg.lParam; // 917505
        TempKeyEvent.is_system_key := ord(False);
        TempKeyEvent.character := #0;
        TempKeyEvent.unmodified_character := #0;
        TempKeyEvent.focus_on_editable_field := ord(False);

        CefCheckAltGrPressed(Msg.wParam, TempKeyEvent);
{$IFDEF DEBUG}
        CefKeyEventLog(TempKeyEvent);
{$ENDIF}
        chrmosr.SendKeyEvent(@TempKeyEvent);

        outputdebugstring(pchar('WM_CHAR ' + inttostr(Msg.wParam) + ' :: ' +
          inttostr(Msg.lParam)));
      end;

    WM_MOUSEWHEEL:
      if Panel1.Focused then
      begin
        GetCursorPos(TempPoint);
        TempPoint := Panel1.ScreenToclient(TempPoint);
        TempMouseEvent.X := TempPoint.X;
        TempMouseEvent.Y := TempPoint.Y;
        TempMouseEvent.modifiers := GetCefMouseModifiers(Msg.wParam);

        DeviceToLogical(TempMouseEvent, Panel1.ScreenScale);

        if CefIsKeyDown(VK_SHIFT) then
          chrmosr.SendMouseWheelEvent(@TempMouseEvent,
            smallint(Msg.wParam shr 16), 0)
        else
          chrmosr.SendMouseWheelEvent(@TempMouseEvent, 0,
            smallint(Msg.wParam shr 16));
      end;
  end;
end;

procedure TForm1.sendESCKey;
var
  TempKeyEvent: TCefKeyEvent;
begin
  // Debug Output: key 27 :: 65537 Process syncBrowser.exe (21888)
  TempKeyEvent.kind := KEYEVENT_CHAR;
  TempKeyEvent.modifiers := EVENTFLAG_NONE;
  // GetCefKeyboardModifiers(27, 65537);
  TempKeyEvent.windows_key_code := 27;
  TempKeyEvent.native_key_code := 65537;
  TempKeyEvent.is_system_key := ord(False);
  TempKeyEvent.character := #0;
  TempKeyEvent.unmodified_character := #0;
  TempKeyEvent.focus_on_editable_field := ord(False);

  // CefCheckAltGrPressed(27, TempKeyEvent);
{$IFDEF DEBUG}
  CefKeyEventLog(TempKeyEvent);
{$ENDIF}
  chrmosr.SendKeyEvent(@TempKeyEvent);

end;

function TForm1.GetInitialized: Boolean;
begin
  Result := False;

  if assigned(FBrowserInfoCS) then
    try
      FBrowserInfoCS.Acquire;
      Result := FInitialized and chrmosr.Initialized;
    finally
      FBrowserInfoCS.Release;
    end;
end;

procedure TForm1.GoBtnClick(Sender: TObject);
begin
  FResizeCS.Acquire;
  FResizing := False;
  FPendingResize := False;
  FResizeCS.Release;

  chrmosr.LoadURL(AddressCb.text);
end;

procedure TForm1.GoBtnEnter(Sender: TObject);
begin
  chrmosr.SetFocus(False);
end;

procedure TForm1.chkBrowserLockClick(Sender: TObject);
begin
  panelOverlay.Visible := chkBrowserLock.Checked;
end;

procedure TForm1.chrmosrAfterCreated(Sender: TObject;
  const browser: ICefBrowser);
begin
  if assigned(FBrowserInfoCS) then
    try
      FBrowserInfoCS.Acquire;
      FInitialized := True;
    finally
      FBrowserInfoCS.Release;
    end;

  PostMessage(Handle, CEF_AFTERCREATED, 0, 0);

end;

procedure TForm1.chrmosrBeforeClose(Sender: TObject;
  const browser: ICefBrowser);
begin
  FCanClose := True;
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure TForm1.chrmosrBeforePopup(Sender: TObject; const browser: ICefBrowser;
  const frame: ICefFrame; popup_id: Integer; const targetUrl: ustring;
  const targetFrameName: ustring; targetDisposition: TCefWindowOpenDisposition;
  userGesture: Boolean; const popupFeatures: TCefPopupFeatures;
  var windowInfo: TCefWindowInfo; var client: ICefClient;
  var settings: TCefBrowserSettings; var extra_info: ICefDictionaryValue;
  var noJavascriptAccess: Boolean; var Result: Boolean);
begin
  // For simplicity, this demo blocks all popup windows and new tabs
  Result := (targetDisposition in [CEF_WOD_NEW_FOREGROUND_TAB,
    CEF_WOD_NEW_BACKGROUND_TAB, CEF_WOD_NEW_POPUP, CEF_WOD_NEW_WINDOW]);
end;

procedure TForm1.chrmosrCanFocus(Sender: TObject);
begin
  // The browser required some time to create associated internal objects
  // before being able to accept the focus. Now we can set the focus on the
  // TBufferPanel control
  PostMessage(Handle, CEF_FOCUSENABLED, 0, 0);
end;

procedure TForm1.chrmosrConsoleMessage(Sender: TObject;
  const browser: ICefBrowser; level: TCefLogSeverity;
  const message, source: ustring; line: Integer; out Result: Boolean);
var
  listOfBadWords: TArray<string>;
  foundBadWord: Boolean;
  badWord: string;
begin
  listOfBadWords := ['null function', 'function signature mismatch',
    'System out of memory', 'Could not allocate memory',
    'memory access out of bounds', 'Uncaught exception from main loop',
    'table index is out of bounds', 'Halting program', 'RuntimeError:',
    'at wasm://'];

  // check for error
  if (level = LOGSEVERITY_ERROR) or (level = LOGSEVERITY_FATAL) then
  begin
    outputdebugstring(pchar(inttostr(line) + ' error from consolemessage ' +
      message));

    foundBadWord := False;
    for badWord in listOfBadWords do
    begin
      // Check if the current badWord is in myVar (case-insensitive)
      if ContainsText(message, badWord) then
      begin
        foundBadWord := True;
        // Exit the loop as soon as the first bad word is found
        Break;
      end;
    end;

    haveClientError := foundBadWord;

    if foundBadWord then
    begin
//       chrmosr.JavascriptEnabled := False;     // no hace nada en una pag q ya esta ejecutando js
       memo1.Lines.Add('Error: game crashed, reload');
        playbeep();
        playbeep();
        playbeep();
        chkReloading.checked:=true;
       chrmosr.Reload;

      if (FTask <> nil) and (FTask.Status = TTaskStatus.Running) then
      begin
        FTask.Cancel;
      end;



//      if MessageDlg('Error ' + message, mtConfirmation, [mbYes, mbNo], 0, mbYes)
//        = mrYes then
//      begin
//        MessageDlg('Exiting the system.', mtInformation, [mbOk], 0, mbOk);
//
//        outputdebugstring('deberia salir el dialogo  2');
//        Result := True;
//      end;
    end;
  end;
end;

procedure TForm1.chrmosrCursorChange(Sender: TObject;
  const browser: ICefBrowser; cursor_: TCefCursorHandle;
  cursorType: TCefCursorType; const customCursorInfo: PCefCursorInfo;
  var aResult: Boolean);
begin
  Panel1.Cursor := CefCursorToWindowsCursor(cursorType);
  aResult := True;
end;

procedure TForm1.chrmosrDevToolsMethodResult(Sender: TObject;
  const browser: ICefBrowser; message_id: Integer; success: Boolean;
  const Result: ICefValue);
var
  TempDict: ICefDictionaryValue;
  TempValue: ICefValue;
  TempResult: wParam;
  TempCode: Integer;
  TempMessage: string;
begin
  FDevToolsMsgValue := '';
  TempResult := 0;

  if success then
  begin
    if (FPendingMsgID = DEVTOOLS_SCREENSHOT_MSGID) then
    begin
      TempResult := 1;
      FDevToolsMsgValue := '';

      if (Result <> nil) then
      begin
        TempDict := Result.GetDictionary;

        if (TempDict <> nil) and (TempDict.GetSize > 0) then
        begin
          TempValue := TempDict.GetValue('data');

          if (TempValue <> nil) and (TempValue.GetType = VTYPE_STRING) then
            FDevToolsMsgValue := TempValue.GetString;
        end;
      end;
    end;
  end
  else if (Result <> nil) then
  begin
    TempDict := Result.GetDictionary;

    if (TempDict <> nil) then
    begin
      TempCode := 0;
      TempMessage := '';
      TempValue := TempDict.GetValue('code');

      if (TempValue <> nil) and (TempValue.GetType = VTYPE_INT) then
        TempCode := TempValue.GetInt;

      TempValue := TempDict.GetValue('message');

      if (TempValue <> nil) and (TempValue.GetType = VTYPE_STRING) then
        TempMessage := TempValue.GetString;

      if (length(TempMessage) > 0) then
        FDevToolsMsgValue := 'DevTools Error (' + inttostr(TempCode) + ') : ' +
          quotedstr(TempMessage);
    end;
  end;

  PostMessage(Handle, MINIBROWSER_DTDATA_AVLBL, TempResult, 0);
end;

procedure TForm1.chrmosrGetScreenInfo(Sender: TObject;
  const browser: ICefBrowser; var screenInfo: TCefScreenInfo;
  out Result: Boolean);
var
  TempRect: TCefRect;
  TempScale: single;
begin
  TempScale := Panel1.ScreenScale;
  TempRect.X := 0;
  TempRect.Y := 0;
  TempRect.width := DeviceToLogical(Panel1.width, TempScale);
  TempRect.height := DeviceToLogical(Panel1.height, TempScale);

  screenInfo.device_scale_factor := TempScale;
  screenInfo.depth := 0;
  screenInfo.depth_per_component := 0;
  screenInfo.is_monochrome := ord(False);
  screenInfo.rect := TempRect;
  screenInfo.available_rect := TempRect;

  Result := True;
end;

procedure TForm1.chrmosrGetScreenPoint(Sender: TObject;
  const browser: ICefBrowser; viewX: Integer; viewY: Integer;
  var screenX: Integer; var screenY: Integer; out Result: Boolean);
var
  TempScreenPt, TempViewPt: TPoint;
  TempScale: single;
begin
  TempScale := Panel1.ScreenScale;
  TempViewPt.X := LogicalToDevice(viewX, TempScale);
  TempViewPt.Y := LogicalToDevice(viewY, TempScale);
  TempScreenPt := Panel1.ClientToScreen(TempViewPt);
  screenX := TempScreenPt.X;
  screenY := TempScreenPt.Y;
  Result := True;
end;

procedure TForm1.chrmosrGetViewRect(Sender: TObject; const browser: ICefBrowser;
  var rect: TCefRect);
var
  TempScale: single;
begin
  TempScale := Panel1.ScreenScale;
  rect.X := 0;
  rect.Y := 0;
  rect.width := DeviceToLogical(Panel1.width, TempScale);
  rect.height := DeviceToLogical(Panel1.height, TempScale);
end;

procedure TForm1.chrmosrPaint(Sender: TObject; const browser: ICefBrowser;
  kind: TCefPaintElementType; dirtyRectsCount: NativeUInt;
  const dirtyRects: PCefRectArray; const buffer: Pointer; width: Integer;
  height: Integer);
var
  src, dst: PByte;
  i, j, TempLineSize, TempSrcOffset, TempDstOffset, SrcStride,
    DstStride: Integer;
  n: NativeUInt;
  TempWidth, TempHeight, TempScanlineSize: Integer;
  TempBufferBits: Pointer;
  TempForcedResize: Boolean;
  TempSrcRect: TRect;
begin
  try
    FResizeCS.Acquire;
    TempForcedResize := False;

    if Panel1.BeginBufferDraw then
    begin
      if (kind = PET_POPUP) then
      begin
        if (FPopUpBitmap = nil) or (width <> FPopUpBitmap.width) or
          (height <> FPopUpBitmap.height) then
        begin
          if (FPopUpBitmap <> nil) then
            FPopUpBitmap.Free;

          FPopUpBitmap := TBitmap.Create;
          FPopUpBitmap.PixelFormat := pf32bit;
          FPopUpBitmap.HandleType := bmDIB;
          FPopUpBitmap.width := width;
          FPopUpBitmap.height := height;
        end;

        TempWidth := FPopUpBitmap.width;
        TempHeight := FPopUpBitmap.height;
        TempScanlineSize := FPopUpBitmap.width * SizeOf(TRGBQuad);
        TempBufferBits := FPopUpBitmap.Scanline[pred(FPopUpBitmap.height)];
      end
      else
      begin
        TempForcedResize := Panel1.UpdateBufferDimensions(width, height) or
          not(Panel1.BufferIsResized(False));
        TempWidth := Panel1.BufferWidth;
        TempHeight := Panel1.BufferHeight;
        TempScanlineSize := Panel1.ScanlineSize;
        TempBufferBits := Panel1.BufferBits;
      end;

      if (TempBufferBits <> nil) then
      begin
        SrcStride := width * SizeOf(TRGBQuad);
        DstStride := -TempScanlineSize;

        n := 0;

        while (n < dirtyRectsCount) do
        begin
          if (dirtyRects[n].X >= 0) and (dirtyRects[n].Y >= 0) then
          begin
            TempLineSize := min(dirtyRects[n].width,
              TempWidth - dirtyRects[n].X) * SizeOf(TRGBQuad);

            if (TempLineSize > 0) then
            begin
              TempSrcOffset := ((dirtyRects[n].Y * width) + dirtyRects[n].X) *
                SizeOf(TRGBQuad);
              TempDstOffset := ((TempScanlineSize * pred(TempHeight)) -
                (dirtyRects[n].Y * TempScanlineSize)) +
                (dirtyRects[n].X * SizeOf(TRGBQuad));

              src := @PByte(buffer)[TempSrcOffset];
              dst := @PByte(TempBufferBits)[TempDstOffset];

              i := 0;
              j := min(dirtyRects[n].height, TempHeight - dirtyRects[n].Y);

              while (i < j) do
              begin
                Move(src^, dst^, TempLineSize);

                Inc(dst, DstStride);
                Inc(src, SrcStride);
                Inc(i);
              end;
            end;
          end;

          Inc(n);
        end;

        if FShowPopUp and (FPopUpBitmap <> nil) then
        begin
          TempSrcRect := rect(0, 0, min(FPopUpRect.Right - FPopUpRect.Left,
            FPopUpBitmap.width), min(FPopUpRect.Bottom - FPopUpRect.Top,
            FPopUpBitmap.height));

          Panel1.BufferDraw(FPopUpBitmap, TempSrcRect, FPopUpRect);
        end;
      end;

      Panel1.EndBufferDraw;
      Panel1.InvalidatePanel;

      if (kind = PET_VIEW) then
      begin
        if TempForcedResize or FPendingResize then
          PostMessage(Handle, CEF_PENDINGRESIZE, 0, 0);

        FResizing := False;
        FPendingResize := False;
      end;
    end;
  finally
    FResizeCS.Release;
  end;
end;

procedure TForm1.chrmosrPopupShow(Sender: TObject; const browser: ICefBrowser;
  show: Boolean);
begin
  if show then
    FShowPopUp := True
  else
  begin
    FShowPopUp := False;
    FPopUpRect := rect(0, 0, 0, 0);

    if (chrmosr <> nil) then
      chrmosr.Invalidate(PET_VIEW);
  end;
end;

procedure TForm1.chrmosrPopupSize(Sender: TObject; const browser: ICefBrowser;
  const rect: PCefRect);
begin
  LogicalToDevice(rect^, Panel1.ScreenScale);

  FPopUpRect.Left := rect.X;
  FPopUpRect.Top := rect.Y;
  FPopUpRect.Right := rect.X + rect.width - 1;
  FPopUpRect.Bottom := rect.Y + rect.height - 1;
end;

procedure TForm1.chrmosrRenderProcessTerminated(Sender: TObject; const browser: ICefBrowser;
  status: TCefTerminationStatus; error_code: Integer; const error_string: ustring);
begin
memo1.Lines.add('chrmosrRenderProcessTerminated');
end;

procedure TForm1.chrmosrRenderProcessUnresponsive(Sender: TObject; const browser: ICefBrowser;
  const callback: ICefUnresponsiveProcessCallback; var aResult: Boolean);
begin
memo1.Lines.add('chrmosrRenderProcessUnresponsive');
end;

procedure TForm1.chrmosrTooltip(Sender: TObject; const browser: ICefBrowser;
  var text: ustring; out Result: Boolean);
begin
  Panel1.hint := text;
  Panel1.ShowHint := (length(text) > 0);
  Result := True;
end;

procedure TForm1.AddressCbEnter(Sender: TObject);
begin
  chrmosr.SetFocus(False);
end;

function TForm1.getModifiers(Shift: TShiftState): TCefEventFlags;
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

function TForm1.GetButton(Button: TMouseButton): TCefMouseButtonType;
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

procedure TForm1.WMMove(var aMessage: TWMMove);
begin
  inherited;

  if (chrmosr <> nil) then
    chrmosr.NotifyMoveOrResizeStarted;
end;

procedure TForm1.WMMoving(var aMessage: TMessage);
begin
  inherited;

  if (chrmosr <> nil) then
    chrmosr.NotifyMoveOrResizeStarted;
end;

procedure TForm1.WMCaptureChanged(var aMessage: TMessage);
begin
  inherited;

  if (chrmosr <> nil) then
    chrmosr.SendCaptureLostEvent;
end;

procedure TForm1.WMCancelMode(var aMessage: TMessage);
begin
  inherited;

  if (chrmosr <> nil) then
    chrmosr.SendCaptureLostEvent;
end;

procedure TForm1.WMEnterMenuLoop(var aMessage: TMessage);
begin
  inherited;

  if (aMessage.wParam = 0) and (GlobalCEFApp <> nil) then
    GlobalCEFApp.OsmodalLoop := True;
end;

procedure TForm1.WMExitMenuLoop(var aMessage: TMessage);
begin
  inherited;

  if (aMessage.wParam = 0) and (GlobalCEFApp <> nil) then
    GlobalCEFApp.OsmodalLoop := False;
end;

procedure TForm1.BrowserCreatedMsg(var aMessage: TMessage);
begin
  //

end;

procedure TForm1.btnRotateClick(Sender: TObject);
begin
  MemoKingdoms.Lines.BeginUpdate;
  try
    // Move the first line to the end of the list
    MemoKingdoms.Lines.Add(MemoKingdoms.Lines[0]);
    MemoKingdoms.Lines.Delete(0);
  finally
    MemoKingdoms.Lines.EndUpdate;
  end;
end;

procedure TForm1.sendBackspaceKey(keycode: byte);
var
  KeyEvent: TCefKeyEvent;
begin
  if not Initialized then
    Exit;

  ZeroMemory(@KeyEvent, SizeOf(KeyEvent));

  // --- 1. Send Key Down event ---
  KeyEvent.kind := KEYEVENT_RAWKEYDOWN;
  KeyEvent.windows_key_code := keycode; // VK_BACK; // VK_BACK is 8
  // Use MapVirtualKey to get native_key_code (scancode)
  KeyEvent.native_key_code := MapVirtualKey(KeyEvent.windows_key_code,
    MAPVK_VK_TO_VSC);
  chrmosr.SendKeyEvent(@KeyEvent);

  // --- 2. Send Char event (optional for backspace, but good practice) ---
  // For 'Char' events, the WindowsKeyCode should be the character code itself.
  // Backspace char code is also 8.
  KeyEvent.kind := KEYEVENT_CHAR;
  KeyEvent.character := chr(keycode); // #8;
  KeyEvent.unmodified_character := chr(keycode); // #8;
  chrmosr.SendKeyEvent(@KeyEvent);

  // --- 3. Send Key Up event ---
  KeyEvent.kind := KEYEVENT_KEYUP;
  // Keep windows_key_code as VK_BACK
  KeyEvent.windows_key_code := keycode; // VK_BACK;
  // Keep native_key_code as scancode
  KeyEvent.native_key_code := MapVirtualKey(KeyEvent.windows_key_code,
    MAPVK_VK_TO_VSC);
  chrmosr.SendKeyEvent(@KeyEvent);
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  ShowWindow(Handle, SW_RESTORE);
end;

procedure TForm1.ConvertToGrayscale(Bitmap: TBitmap);
var
  X, Y: Integer;
  GrayColor: Integer;
  Color: TColor;
begin
  Bitmap.PixelFormat := pf24bit; // Ensure 24-bit pixel format
  for Y := 0 to Bitmap.height - 1 do
  begin
    for X := 0 to Bitmap.width - 1 do
    begin
      Color := Bitmap.Canvas.Pixels[X, Y];
      GrayColor := Round(0.299 * GetRValue(Color) + 0.587 * GetGValue(Color) +
        0.114 * GetBValue(Color));
      Bitmap.Canvas.Pixels[X, Y] := RGB(GrayColor, GrayColor, GrayColor);
    end;
  end;
end;

procedure TForm1.inputdata(chars: string);
var
  i: Integer;
begin

  for i := 1 to length(chars) do
  begin

    sendBackspaceKey(ord(chars[i]));
  end;
end;

function TForm1.getXCoords(const prevCoordX: Integer;
  out coordX: Integer): Boolean;
var
  coordsBMP: TBitmap;
  Match: TMatch;
begin
  Result := False;
  {
    TessPageSegMode = (PSM_OSD_ONLY, PSM_AUTO_OSD, PSM_AUTO_ONLY, PSM_AUTO, PSM_SINGLE_COLUMN, PSM_SINGLE_BLOCK_VERT_TEXT,
    PSM_SINGLE_BLOCK, PSM_SINGLE_LINE, PSM_SINGLE_WORD, PSM_CIRCLE_WORD, PSM_SINGLE_CHAR, PSM_SPARSE_TEXT,
    PSM_SPARSE_TEXT_OSD, PSM_RAW_LINE, PSM_COUNT);
  }


  // kingdom coords
  // try
  // FResizeCS.Acquire;
  // coordsBMP := nil;
  // try
  // coordsBMP := TBitmap.Create;
  // coordsBMP.width := 35;
  // coordsBMP.height := 20;
  //
  // if Assigned(Panel1.buffer) and not Panel1.buffer.Empty then
  // begin
  //
  // BitBlt(coordsBMP.Canvas.Handle, 0, 0, coordsBMP.width, coordsBMP.height,
  // Panel1.buffer.Canvas.Handle, 30, Panel1.height - 29, SRCCOPY);
  //
  // ConvertToGrayscale(coordsBMP);
  //
  // if Assigned(Image1) then
  // Image1.Picture.Assign(coordsBMP);
  //
  // if Assigned(tesseract) and not tesseract.Busy then
  // begin
  // if tesseract.SetImage(coordsBMP) then
  // begin
  // var
  // data := tesseract.RecognizeAsText(True);
  // Match := TRegex.Match(data, '\d+');
  // if Match.success then
  // Edit1.text := Match.Value
  // else
  // Edit1.text := data;
  // end;
  // end;
  // end;
  //
  // finally
  // if Assigned(coordsBMP) then
  // coordsBMP.Free;
  // end;
  // finally
  // FResizeCS.Release;
  // end;

  // X coords
  try
    FResizeCS.Acquire;
    coordsBMP := nil;
    try
      coordsBMP := TBitmap.Create;
      coordsBMP.width := 35;
      coordsBMP.height := 20;

      if assigned(Panel1.buffer) and not Panel1.buffer.Empty then
      begin
        BitBlt(coordsBMP.Canvas.Handle, 0, 0, coordsBMP.width, coordsBMP.height,
          Panel1.buffer.Canvas.Handle, 82, Panel1.height - 29, SRCCOPY);

        ConvertToGrayscale(coordsBMP);

        if assigned(Image2) then
          Image2.Picture.Assign(coordsBMP);

        if assigned(tesseract) and not tesseract.Busy then
        begin
          if tesseract.SetImage(coordsBMP) then
          begin
            var
            data := tesseract.RecognizeAsText(True);
            var
            value := '';
            Match := TRegex.Match(data, '\d+');
            if Match.success then
              value := Match.value
            else
              value := data;

            Edit2.text := value;

            coordX := prevCoordX;
            // default value, if convertion fails, it will reuse prev coord
            Result := tryStrToInt(value, coordX);
            // will update coordX if value is ok/integer

//            if not Result then
//            begin
//              Memo1.Lines.Add('failed ocr ' + value + ' X= ' + inttostr(coordX)
//                + ' PX= ' + inttostr(prevCoordX));
//            end;

          end;
        end;
      end;

    finally
      if assigned(coordsBMP) then
        coordsBMP.Free;
    end;

  finally
    FResizeCS.Release;
  end;

end;

function TForm1.getYCoords(const prevCoord: Integer;
  out coord: Integer): Boolean;
var
  coordsBMP: TBitmap;
  Match: TMatch;
begin
  Result := False;
  {
    TessPageSegMode = (PSM_OSD_ONLY, PSM_AUTO_OSD, PSM_AUTO_ONLY, PSM_AUTO, PSM_SINGLE_COLUMN, PSM_SINGLE_BLOCK_VERT_TEXT,
    PSM_SINGLE_BLOCK, PSM_SINGLE_LINE, PSM_SINGLE_WORD, PSM_CIRCLE_WORD, PSM_SINGLE_CHAR, PSM_SPARSE_TEXT,
    PSM_SPARSE_TEXT_OSD, PSM_RAW_LINE, PSM_COUNT);
  }



  // Y coords
  try
    FResizeCS.Acquire;
    coordsBMP := nil;
    try
      coordsBMP := TBitmap.Create;
      coordsBMP.width := 35;
      coordsBMP.height := 20;

      if assigned(Panel1.buffer) and not Panel1.buffer.Empty then
      begin
        BitBlt(coordsBMP.Canvas.Handle, 0, 0, coordsBMP.width, coordsBMP.height,
          Panel1.buffer.Canvas.Handle, 130, Panel1.height - 29, SRCCOPY);

        ConvertToGrayscale(coordsBMP);

        if assigned(Image3) then
          Image3.Picture.Assign(coordsBMP);

        if assigned(tesseract) and not tesseract.Busy then
        begin
          if tesseract.SetImage(coordsBMP) then
          begin
            var
            data := tesseract.RecognizeAsText(True);
            var
            value := '';
            Match := TRegex.Match(data, '\d+');
            if Match.success then
              value := Match.value
            else
              value := data;

            Edit3.text := value;

            coord := prevCoord;
            // default value, if convertion fails, it will reuse prev coord
            Result := tryStrToInt(value, coord);
            // will update coordX if value is ok/integer

            if not Result then
            begin
              Memo1.Lines.Add('failed ocr ' + value + ' X= ' + inttostr(coord)
                + ' PX= ' + inttostr(prevCoord));
            end;

          end;
        end;
      end;

    finally
      if assigned(coordsBMP) then
        coordsBMP.Free;
    end;

  finally
    FResizeCS.Release;
  end;

end;

procedure TForm1.Button2Click(Sender: TObject);
var
  sleepDelay: Integer;
begin

  if templateGoToLocation = nil then
    Exit;

  if memoKingdoms.GetTextLen() = 0 then
    Exit;

  if (FTask <> nil) and (FTask.Status = TTaskStatus.Running) then
    Exit; // already running

  Button2.Enabled := False;
  chkToRight.Enabled:=False;
  timer2.Enabled:=true;

  chkBrowserLock.Checked := True;
  // panelOverlay.Visible:=true;

  application.ProcessMessages;

  prevYCoords:=0;

  // Reset error flags before starting
  haveClientError := False;
  GlobalLock.Enter;
  try
    globalError := False;
  finally
    GlobalLock.Leave;
  end;

  FTask := ttask.run(
    procedure
    const

      // probablemente en procesadores mas lentos requiera mayor valor
      panSteps = 3;
      MIN_BOUNDARY = 50;
      MAX_BOUNDARY = 950;
      TOTAL_VERTICAL_STEPS = 40;
      panX1=145;
      panX2=1014;
      panY=426;
    var
      // Match: TMatch;
      kingdom: string;
      totalKingdoms:integer;
      i: Integer;
      // coordK, coordX, coordY: Integer;
      prevCoordX: Integer;
       sCoordX, sCoordY: String;
      searchMerc: TProc;
      // updateCoords: TProc;
      panRight: TProc;
      panDown: TProc;
      panLeft: TProc;
      haveError: TFunc<Boolean>;
      // ProcessGameTick: TProc;
      // GameState: TGameState;
      // IsCoordinateValid:TFunc<integer,integer,boolean>;
      currentXPosition: Integer;

      goingRight: Boolean;
      verticalStepsTaken: Integer;

      // /--------------------
    begin
      // ----------------
{$REGION 'haveError function'}
      haveError := function: Boolean
        var
          err1, err2: Boolean;
        begin
          GlobalLock.Enter; // Acquire the lock
          try
            err1 := globalError;
          finally
            GlobalLock.Leave; // Release the lock immediately when done
          end;

          TThread.Synchronize(nil,
            procedure
            begin
              err2 := haveClientError;
            end);

          Result := False;
          if (err1 or err2) then
            Result := True;
        end;
{$ENDREGION}
      // ---------------

{$REGION 'searchMerc procedure'}
      searchMerc := procedure
        var
          coordsBMP: TBitmap;

        begin
          if not initialized then exit;

          if (haveError) then
            Exit;

          TThread.Synchronize(nil,
            procedure
            begin
              // Use OpenCV to check the bitmap
              if assigned(TemplateImg) and searchImage(TemplateImg, 0.6) then
              begin
                playBeep();

                // capture coords from mini map
                // extract text k,x,y with tesseract ocr
                // add to a memo
                try
                  FResizeCS.Acquire;
                  coordsBMP := nil;
                  try
                    coordsBMP := TBitmap.Create;
                    coordsBMP.width := 160;
                    coordsBMP.height := 23;

                    if assigned(Panel1.buffer) and not Panel1.buffer.Empty then
                    begin
                      BitBlt(coordsBMP.Canvas.Handle, 0, 0, coordsBMP.width,
                        coordsBMP.height, Panel1.buffer.Canvas.Handle, 10,
                        Panel1.height - 30, SRCCOPY);

                      // coordsBMP.SaveToFile('coords.bmp');

                      if assigned(tesseract) and not tesseract.Busy then
                      begin
                        if tesseract.SetImage(coordsBMP) then
                        begin
                          var
                          data := tesseract.RecognizeAsText(True);
                          if assigned(Memo1) then
                          begin
                            Memo1.Lines.Add(data);
                          end;
                        end;
                      end;
                    end;

                  finally
                    if assigned(coordsBMP) then
                      coordsBMP.Free;
                  end;
                finally
                  FResizeCS.Release;
                end;
              end;

            end);
        end;
{$ENDREGION}

      // -----------
{$REGION 'panRight procedure'}
      panRight := procedure

        begin
          if not initialized then exit;

          if (haveError) then
            Exit;

          TThread.Synchronize(nil,
            procedure
            begin
              sleepDelay := seDelay.value;
            end);

          TThread.Synchronize(nil,
            procedure
            begin
              MouseMove([], panX2,panY); //870, 365);
              MouseDown(mbLeft, [], panX2,panY); //870, 365);
            end);

          // Add a small delay to allow the browser process to catch up
          // and for the UI to register the movement realistically.
          sleep(sleepDelay);

          var
          distance := panX2-panX1; //870 - 180;
          var
          stepSize := distance div panSteps;

          for var i := 1 to panSteps do
          begin
            var
            X := panX2 - (stepSize * i);


            TThread.Synchronize(nil,
              procedure
              begin
                MouseMove([], X, panY);

                application.ProcessMessages;
              end);

            sleep(sleepDelay);
          end;

          TThread.Synchronize(nil,
            procedure
            begin
              MouseMove([], panX1, panY);
              MouseUp(mbLeft, [], panX1, panY);
            end);

          sleep(sleepDelay);
        end;
{$ENDREGION}
      // -------------

{$REGION 'panLeft procedure'}
      panLeft := procedure

        begin
          if not initialized then exit;
          if (haveError) then
            Exit;

          TThread.Synchronize(nil,
            procedure
            begin
              sleepDelay := seDelay.value;
            end);

          TThread.Synchronize(nil,
            procedure
            begin
              MouseMove([], panX1, panY);
              MouseDown(mbLeft, [], panX1, panY);
            end);

          // Add a small delay to allow the browser process to catch up
          // and for the UI to register the movement realistically.
          sleep(sleepDelay);

          var
          distance := panX2 - panX1;
          var
          stepSize := distance div panSteps;

          for var i := 1 to panSteps do
          begin
            var
            X := panX1 + (stepSize * i);

            TThread.Synchronize(nil,
              procedure
              begin
                MouseMove([], X, panY);

                application.ProcessMessages;
              end);

            sleep(sleepDelay);
          end;


          TThread.Synchronize(nil,
            procedure
            begin
              MouseMove([], panX2, panY);
              MouseUp(mbLeft, [], panX2, panY);
            end);

          sleep(sleepDelay);
        end;
{$ENDREGION}

      // -----------------
{$REGION 'panDown procedure'}
      panDown := procedure
      const
         posX=920;
         posY1=163;
         posY2=736;
        begin
          if not initialized then exit;
          if (haveError) then
            Exit;

          TThread.Synchronize(nil,
            procedure
            begin
              sleepDelay := seDelay.value;
            end);

//          for var times := 0 to 1 do
//          begin

            TThread.Synchronize(nil,
              procedure
              begin
                MouseMove([], posX, posY2); // 600...210
                MouseDown(mbLeft, [], posX, posY2);
              end);

            // Add a small delay to allow the browser process to catch up
            // and for the UI to register the movement realistically.
            // sleep(sleepDelay);

            var
            distance := posY2 - posY1;
            var
            stepSize := distance div panSteps;

            for var i := 1 to panSteps do
            begin
              var
              Y := posY2 - (stepSize * i);
              sleep(sleepDelay);

              TThread.Synchronize(nil,
                procedure
                begin
                  MouseMove([], posX, Y);

                  application.ProcessMessages;
                end);

            end;

            TThread.Synchronize(nil,
              procedure
              begin
                MouseMove([], posX, posY1);
                MouseUp(mbLeft, [], posX, posY1);
              end);

//          end; // end for loop
        end;
{$ENDREGION}
      // -----------------------------------

      // ------------ main body -------------
      // GameState.LastKnownX:=0;
      // GameState.CurrentDirection:= dirRight;
      // GameState.OcrFailsInARow:=0;
      // GameState.LastOcrSuccessTime:=now;
      try
        try
          TThread.Synchronize(nil,
            procedure
            begin
              totalKingdoms:= memoKingdoms.Lines.Count - 1;
            end);

          for i := 0 to totalKingdoms do
          begin
            // if FTask.Status = TTaskStatus.Canceled then
            // Exit;

            if (haveError) then
              Exit;

            TThread.Synchronize(nil,
            procedure
            var posX,posY:integer;
            begin
              if chkReloading.Checked then begin
                chkReloading.Checked := false;

                // si es reloading , tengo los 3 datos
                kingdom := trim(edit1.text);
                sCoordX:=trim(edit2.text);
                sCoordY:=trim(edit3.text);

                if not tryStrToInt(sCoordX, posX) then begin
                   sCoordX:='20';
                end;
                if not tryStrToInt(sCoordY, posY) then begin
                   sCoordY:='20';
                end;
              end else begin
                kingdom := trim(memoKingdoms.Lines[i]);
                sCoordX:='20';
                sCoordY:='20';

                memo1.lines.Add('searching on '+kingdom);
//                 MemoKingdoms.Lines.BeginUpdate;
//                try
//                  // Move the first line to the end of the list
//                  MemoKingdoms.Lines.Add(MemoKingdoms.Lines[0]);
//                  MemoKingdoms.Lines.Delete(0);
//                finally
//                  MemoKingdoms.Lines.EndUpdate;
//                end;
              end;

              edit1.Text:=kingdom;
              edit2.text:=sCoordX;
              edit3.text:=sCoordY;
            end);

            if kingdom = '' then
              continue;

            TThread.Synchronize(nil,
              procedure
              begin
                sendBackspaceKey(VK_ESCAPE);
                sendBackspaceKey(VK_ESCAPE);
                sendBackspaceKey(VK_ESCAPE);
              end);

{$REGION 'enter kingdom coordinates'}
            TThread.Synchronize(nil,
              procedure
              const
                posX=90;
                posY=655;
              begin
                // search icon button  90, 655
                MouseMove([], posX, posY);
                MouseDown(mbLeft, [], posX, posY);
                sleep(10);
                MouseUp(mbLeft, [], posX, posY);
              end);

            sleep(100);

            // outputdebugstring('search starting goto loca');

            var
            WindowFound := False;
            var
            MaxAttempts := 3;
            // Try for ~10 seconds (20 * 500ms sleep + processing time)
            var
            CurrentAttempt := 0;

            while (not WindowFound) and (CurrentAttempt < MaxAttempts) do
            begin
              Inc(CurrentAttempt);

              TThread.Synchronize(nil,
                procedure
                begin
                  // Use OpenCV to check the bitmap
                  if assigned(templateGoToLocation) then
                    WindowFound := searchImage(templateGoToLocation, 0.6)
                  else
                    WindowFound := False;
                end);

              if not WindowFound then
                sleep(200); // Wait before the next attempt
            end;

            if not windowFound and (CurrentAttempt=MaxAttempts) then
            begin
                TThread.Synchronize(nil,
                procedure
                begin
                   Memo1.Lines.Add('cant enter kingdom coords ');
                   chrmosr.Reload;
                end);
              exit;
            end;

            // --- Step 3: Act if found, or exit if timeout ---
            if WindowFound then
            begin

              TThread.Synchronize(nil,
                procedure
                const
                  posX=481;
                  posY=416;
                begin
                  // // kindom 481,416
                  MouseMove([], posX, posY);
                  MouseDown(mbLeft, [], posX, posY);
                  sleep(10);
                  MouseUp(mbLeft, [], posX, posY);
                end);

              sleep(60);

              TThread.Synchronize(nil,
                procedure
                begin
                  sendBackspaceKey(VK_BACK);
                  sendBackspaceKey(VK_BACK);
                  sendBackspaceKey(VK_BACK);
                end);
              //
              TThread.Synchronize(nil,
                procedure
                begin
                  inputdata(kingdom);
                  // sendBackspaceKey(ord('1'));
                  // sendBackspaceKey(ord('0'));
                  // sendBackspaceKey(ord('1'));
                end);

              sleep(60);

              TThread.Synchronize(nil,
                procedure
                 const
                  posX=583;
                  posY=416;
                begin
                  // // x 512, 360
                  MouseMove([], posX, posY);
                  MouseDown(mbLeft, [], posX, posY);
                  sleep(10);
                  MouseUp(mbLeft, [], posX, posY);
                end);

              sleep(60);

              TThread.Synchronize(nil,
                procedure
                begin
                  sendBackspaceKey(VK_BACK);
                  sendBackspaceKey(VK_BACK);
                  sendBackspaceKey(VK_BACK);
                end);

              TThread.Synchronize(nil,
                procedure
                begin
                    inputdata(sCoordX);
//                    sendBackspaceKey(ord('2'));
//                    sendBackspaceKey(ord('0'));
//                    // sendBackspaceKey(ord('1'));
                 end);

              TThread.Synchronize(nil,
                procedure
                const
                  posX=686;
                  posY=416;
                begin
                  // y 615, 360
                  MouseMove([], posX, posY);
                  MouseDown(mbLeft, [], posX, posY);
                  sleep(10);
                  MouseUp(mbLeft, [], posX, posY);
                end);

              sleep(60);

              TThread.Synchronize(nil,
                procedure
                begin
                  sendBackspaceKey(VK_BACK);
                  sendBackspaceKey(VK_BACK);
                  sendBackspaceKey(VK_BACK);
                end);

              TThread.Synchronize(nil,
                procedure
                begin
                      inputdata(sCoordY);
//                      sendBackspaceKey(ord('2'));
//                      sendBackspaceKey(ord('0'));
                      // sendBackspaceKey(ord('1'));

                end);

              sleep(60);

              TThread.Synchronize(nil,
                procedure
                 const
                  posX=583;
                  posY=464;
                begin
                  // go button 509,402
                  MouseMove([], posX, posY);
                  MouseDown(mbLeft, [], posX, posY);
                  sleep(10);
                  MouseUp(mbLeft, [], posX, posY);
                end);
{$ENDREGION 'kingdom coordinates'}
              sleep(1000); // wait for window load on new location

              try
                /// ///////////////////
                TThread.Synchronize(nil,
                  procedure
                  begin
                    sleepDelay := seDelay.value;
                  end);

                // Initialize
                currentXPosition := 0;
                prevCoordX := 0;

                goingRight := True;
                verticalStepsTaken := 0;

                TThread.Synchronize(nil,
                  procedure
                  begin
                    // This nested procedure runs safely on the Main UI thread

                    prevCoordX := currentXPosition; // save old position
                    { coordXOK := } getXCoords(prevCoordX, currentXPosition);
                  end);

                // Main loop continues until 20 vertical steps have been taken
                while verticalStepsTaken < TOTAL_VERTICAL_STEPS do
                begin

                  if (haveError) then
                  begin
                    Exit;
                  end;

                  if FTask.Status = TTaskStatus.Canceled then
                    Exit;

                  var Yends := false;
                  TThread.Synchronize(nil,
                    procedure
                    var posY:integer;
                    begin
                      if (trim(edit3.text)<>'') and (TryStrToInt(edit3.text,posY)) then
                      begin
                        if posY>950 then
                          Yends:=true
                      end;
                    end);
                  if Yends then break;
                  

                  FTask.CheckCanceled;

                  TThread.Synchronize(nil,
                    procedure
                    begin
                      sendBackspaceKey(VK_ESCAPE);
                    end);

                  searchMerc;

                  // Continuous movement logic
                  if goingRight then
                  begin
                    panRight();
                  end
                  else
                  begin
                    panLeft();
                  end;

                  TThread.Synchronize(nil,
                    procedure
                    begin
                      // This nested procedure runs safely on the Main UI thread

                      var
                      coordXOK := getXCoords(prevCoordX, currentXPosition);

                      if coordXOK then
                      begin // ---->
                        // if goingright currX should be higher than prevX
                        if goingRight and (currentXPosition < prevCoordX) then
                        begin
//                           Memo1.Lines.Add('fixing right ' + inttostr(currentXPosition)+' prev: '+ inttostr(prevCoordX));
                          currentXPosition := prevCoordX + 10;
                          // fixing left 749 prev: 57
                        end
                        else if not goingRight and
                          (currentXPosition > prevCoordX) then
                        begin
//                           Memo1.Lines.Add('fixing left ' + inttostr(currentXPosition)+' prev: '+ inttostr(prevCoordX));
                          currentXPosition := prevCoordX - 10;
                        end;

                      end;

                      // OCR failed, predict next x position
                      if not coordXOK then
                      begin // ---->
                        if goingRight and (prevCoordX + 10 < MAX_BOUNDARY) then
                        begin
                          currentXPosition := prevCoordX + 10;
                        end
                        else if not goingRight and
                          (prevCoordX - 10 > MIN_BOUNDARY) then
                        begin
                          currentXPosition := prevCoordX - 10;
                        end;
//                         Memo1.Lines.Add('failed ' + inttostr(currentXPosition));
                      end;

//                      Memo1.Lines.Add('pX ' + inttostr(prevCoordX)+' nX '+ inttostr(currentXPosition));

                    end);



                  // --- Check for overshoot and execute required actions ---

                  // Check if it overshot the right boundary (>= 950)
                  if goingRight and (currentXPosition >= MAX_BOUNDARY) then
                  begin
                    // Go down 1 step
                    Inc(verticalStepsTaken);
                    panDown();
//
                    TThread.Synchronize(nil,
                     procedure
                     begin
                       chkToRight.Checked:=false;
                     end);

                    // Reverse direction
                    goingRight := False;
                  end
                  // Check if it overshot the left boundary (<= 50)
                  else if not goingRight and (currentXPosition <= MIN_BOUNDARY)
                  then
                  begin
                    // Go down 1 step
                    Inc(verticalStepsTaken);
                    panDown();

                     TThread.Synchronize(nil,
                     procedure
                     begin
                       chkToRight.Checked:=true;
                     end);

                    // Reverse direction
                    goingRight := True;
                  end;

                  prevCoordX := currentXPosition; // save old position
                  // Application.ProcessMessages; // Necessary for UI updates within a tight loop
                  // Sleep(20); // Optional: Add a small pause for visual demonstration speed
                end;

                /// ///////////////
              except
                on E: Exception do
                begin
                  outputdebugstring(pchar('exception task ' + E.message));
                end;

              end;
            end; // end if windowfound

          end; // end loop memo kingdom

        except
          on E: Exception do
          begin
            outputdebugstring(pchar('catched an error ' + E.message));
            TThread.Synchronize(nil,
              procedure
              begin
                outputdebugstring(pchar('An error occurred, reload the page: ' +
                  E.message));
              end);

          end;
        end;
      finally
        TThread.Queue(nil,
          procedure
          begin
            Button2.Enabled := True;
            chkToRight.Enabled:=True;
            chkBrowserLock.Checked := False;
            panelOverlay.Visible := False;
            timer2.Enabled:=false;
          end);
      end;

    end); // ttask.run ends

end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  FTask.Cancel;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin

 MemoKingdoms.Lines.BeginUpdate; // Prevents flicker
  try
    MemoKingdoms.Clear;
    MemoKingdoms.Lines.Add('142');
    MemoKingdoms.Lines.Add('147');
    MemoKingdoms.Lines.Add('150');
    MemoKingdoms.Lines.Add('143');
    MemoKingdoms.Lines.Add('151');
    MemoKingdoms.Lines.Add('138');
    MemoKingdoms.Lines.Add('139');
    MemoKingdoms.Lines.Add('148');
    MemoKingdoms.Lines.Add('152');
    MemoKingdoms.Lines.Add('154');
    MemoKingdoms.Lines.Add('155');
    MemoKingdoms.Lines.Add('144');
    MemoKingdoms.Lines.Add('148');
    MemoKingdoms.Lines.Add('156');
    MemoKingdoms.Lines.Add('141');
    MemoKingdoms.Lines.Add('145');
    MemoKingdoms.Lines.Add('149');
    MemoKingdoms.Lines.Add('153');
    MemoKingdoms.Lines.Add('157');
  finally
    MemoKingdoms.Lines.EndUpdate;
  end;
end;

procedure TForm1.FormAfterMonitorDpiChanged(Sender: TObject;
OldDPI, NewDPI: Integer);
begin
  if (GlobalCEFApp <> nil) then
    GlobalCEFApp.UpdateDeviceScaleFactor;

  if (chrmosr <> nil) then
  begin
    chrmosr.NotifyScreenInfoChanged;
    chrmosr.WasResized;
  end;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if (FTask <> nil) and (FTask.Status = TTaskStatus.Running) then
  begin
    FTask.Cancel;
    FTask.Wait;
  end;

  // CanClose := FCanClose;
  CanClose := (chrmosr.BrowserId = 0) or FCanClose;
  if not(FClosing) then
  begin
    FClosing := True;
    // Visible  := False;
    chrmosr.CloseBrowser(True);
  end;

end;

procedure TForm1.FormCreate(Sender: TObject);
var
  TempMajorVer, TempMinorVer: DWORD;
begin
  FPopUpBitmap := nil;
  FPopUpRect := rect(0, 0, 0, 0);
  FShowPopUp := False;
  FResizing := False;
  FPendingResize := False;
  FCanClose := False;
  FClosing := False;
  FDeviceBounds := nil;
  haveClientError := False;

  FAtLeastWin8 := GetWindowsMajorMinorVersion(TempMajorVer, TempMinorVer) and
    ((TempMajorVer > 6) or ((TempMajorVer = 6) and (TempMinorVer >= 2)));

  FSelectedRange.from := 0;
  FSelectedRange.to_ := 0;

  FResizeCS := TCriticalSection.Create;
  FIMECS := TCriticalSection.Create;
  FBrowserInfoCS := TCriticalSection.Create;

  Panel1.Transparent := TRANSPARENT_BROWSER;

  panelOverlay.width := Panel1.width;
  panelOverlay.height := Panel1.height;


  // screenshot:=TBitmap.Create;
  // screenshot.pixelFormat := pf24bit;

  InitializeLastClick;

  prevYCoords:=0;

  chrmosr.DefaultURL := trim(AddressCb.text);

  tesseract := TTesseractOCR5.Create(ExtractFilePath(application.ExeName)
    + 'DLL\');
  // Tesseract.OnRecognizeBegin    := OnRecognizeBegin;
  // Tesseract.OnRecognizeProgress := OnRecognizeProgress;
  // Tesseract.OnRecognizeEnd      := OnRecognizeEnd;
  tesseract.PageSegMode := PSM_SINGLE_LINE;
  // Set the character whitelist to digits only
  tesseract.SetVariable('tessedit_char_whitelist', ' 0123456789');

  if not tesseract.Initialize('tessdata\', 'eng') then
  begin
    MessageDlg('Error loading Tesseract data', mtError, [mbOk], 0);
    Close;
  end;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  chrmosr.ShutdownDragAndDrop;

  if (FPopUpBitmap <> nil) then
    FreeAndNil(FPopUpBitmap);
  if (FResizeCS <> nil) then
    FreeAndNil(FResizeCS);
  if (FIMECS <> nil) then
    FreeAndNil(FIMECS);
  if (FBrowserInfoCS <> nil) then
    FreeAndNil(FBrowserInfoCS);

  FreeAndNil(tesseract);

  if (FDeviceBounds <> nil) then
  begin
    Finalize(FDeviceBounds);
    FDeviceBounds := nil;
  end;

  if assigned(FTask) then
  begin
    FTask.Cancel;
    // Call CheckSynchronize to process any final TThread.Queue messages related to task termination
    CheckSynchronize;
    FTask := nil;
  end;

  // screenshot.Free;

  // Tell the main form that a child has been destroyed.
  // The main form will check if this was the last child to close itself
  PostMessage(MainForm.Handle, CEFBROWSER_CHILDDESTROYED, 0, 0);
end;

procedure TForm1.FormHide(Sender: TObject);
begin
  chrmosr.SetFocus(False);
  chrmosr.WasHidden(True);
end;

procedure TForm1.FormShow(Sender: TObject);
var
  TempContext: ICefRequestContext;
  TempCache: string;
begin
  if chrmosr.Initialized then
  begin
    chrmosr.WasHidden(False);
    chrmosr.SetFocus(True);
  end
  else
  begin
    // If you need transparency leave the chrmosr.Options.BackgroundColor property
    // with the default value or set the alpha channel to 0
    if TRANSPARENT_BROWSER then
      chrmosr.Options.BackgroundColor := CefColorSetARGB($00, $00, $00, $00)
    else
      chrmosr.Options.BackgroundColor := CefColorSetARGB($FF, $FF, $FF, $FF);

    // The IME handler needs to be created when Panel1 has a valid handle
    // and before the browser creation.
    // You can skip this if the user doesn't need an "Input Method Editor".
    Panel1.CreateIMEHandler;

{$IFDEF DELPHI14_UP}
    if not(ArePointerEventsSupported) then
      RegisterTouchWindow(Panel1.Handle, 0);
{$ENDIF}
    try
      TempCache := GlobalCEFApp.RootCache + '\cache' +
        inttostr(MainForm.BrowserCount);
      TempContext := TCefRequestContextRef.New(TempCache, '', '', False, False,
        chrmosr.ReqContextHandler);

      if chrmosr.CreateBrowser(nil, '', TempContext) then
        chrmosr.InitializeDragAndDrop(Panel1)
      else
        Timer1.Enabled := True;
    finally
      TempContext := nil;
    end;
  end;
end;

procedure TForm1.pClick;
begin
  Panel1.SetFocus;
end;

procedure TForm1.Panel1Click(Sender: TObject);
begin
  pClick;

  // SynchronizeMouseEvent('MouseClick' );
end;

procedure TForm1.Panel1CustomTouch(Sender: TObject; var aMessage: TMessage;
var aHandled: Boolean);
{$IFDEF DELPHI14_UP}
var
  TempScale: single;
  TempTouchEvent: TCefTouchEvent;
  TempHTOUCHINPUT: HTOUCHINPUT;
  TempNumPoints: Integer;
  i: Integer;
  TempTouchInputs: array of TTouchInput;
  TempPoint: TPoint;
  TempLParam: lParam;
  TempResult: LRESULT;
{$ENDIF}
begin
{$IFDEF DELPHI14_UP}
  if not(Panel1.Focused) or (GlobalCEFApp = nil) then
    Exit;

  TempNumPoints := LOWORD(aMessage.wParam);

  // Chromium only supports upto 16 touch points.
  if (TempNumPoints < 1) or (TempNumPoints > 16) then
    Exit;

  SetLength(TempTouchInputs, TempNumPoints);
  TempHTOUCHINPUT := HTOUCHINPUT(aMessage.lParam);
  TempScale := Panel1.ScreenScale;

  if GetTouchInputInfo(TempHTOUCHINPUT, TempNumPoints, @TempTouchInputs[0],
    SizeOf(TTouchInput)) then
  begin
    i := 0;
    while (i < TempNumPoints) do
    begin
      TempPoint := TouchPointToPoint(Panel1.Handle, TempTouchInputs[i]);

      if not(FAtLeastWin8) then
      begin
        // Windows 7 sends touch events for touches in the non-client area,
        // whereas Windows 8 does not. In order to unify the behaviour, always
        // ignore touch events in the non-client area.

        TempLParam := MakeLParam(TempPoint.X, TempPoint.Y);
        TempResult := SendMessage(Panel1.Handle, WM_NCHITTEST, 0, TempLParam);

        if (TempResult <> HTCLIENT) then
        begin
          SetLength(TempTouchInputs, 0);
          Exit;
        end;
      end;

      TempPoint := Panel1.ScreenToclient(TempPoint);
      TempTouchEvent.X := DeviceToLogical(TempPoint.X, TempScale);
      TempTouchEvent.Y := DeviceToLogical(TempPoint.Y, TempScale);

      // Touch point identifier stays consistent in a touch contact sequence
      TempTouchEvent.id := TempTouchInputs[i].dwID;

      if ((TempTouchInputs[i].dwFlags and TOUCHEVENTF_DOWN) <> 0) then
        TempTouchEvent.type_ := CEF_TET_PRESSED
      else if ((TempTouchInputs[i].dwFlags and TOUCHEVENTF_MOVE) <> 0) then
        TempTouchEvent.type_ := CEF_TET_MOVED
      else if ((TempTouchInputs[i].dwFlags and TOUCHEVENTF_UP) <> 0) then
        TempTouchEvent.type_ := CEF_TET_RELEASED;

      TempTouchEvent.radius_x := 0;
      TempTouchEvent.radius_y := 0;
      TempTouchEvent.rotation_angle := 0;
      TempTouchEvent.pressure := 0;
      TempTouchEvent.modifiers := EVENTFLAG_NONE;
      TempTouchEvent.pointer_type := CEF_POINTER_TYPE_TOUCH;

      chrmosr.SendTouchEvent(@TempTouchEvent);

      Inc(i);
    end;

    CloseTouchInputHandle(TempHTOUCHINPUT);
    aHandled := True;
  end;

  SetLength(TempTouchInputs, 0);
{$ENDIF}
end;

procedure TForm1.MouseDown(Button: TMouseButton; Shift: TShiftState;
X, Y: Integer);
var
  TempEvent: TCefMouseEvent;
  TempTime: Integer;
begin
{$IFDEF DELPHI14_UP}
  if (ssTouch in Shift) then
    Exit;
{$ENDIF}
  // Panel1.SetFocus;

  if not(CancelPreviousClick(X, Y, TempTime)) and (Button = FLastClickButton)
  then
    Inc(FLastClickCount)
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
  DeviceToLogical(TempEvent, Panel1.ScreenScale);
  chrmosr.SendMouseClickEvent(@TempEvent, GetButton(Button), False,
    FLastClickCount);


// outputdebugstring(pchar('mouse down ' + inttostr(X) + ',' + inttostr(Y)));


end;

procedure TForm1.Panel1MouseDown(Sender: TObject; Button: TMouseButton;
Shift: TShiftState; X, Y: Integer);
var
  TempEvent: TCefMouseEvent;
  TempTime: Integer;
begin
  MouseDown(Button, Shift, X, Y);

  SynchronizeMouseEvent('MouseDown', Button, Shift, X, Y);
end;

procedure TForm1.Panel1MouseLeave(Sender: TObject);
var
  TempEvent: TCefMouseEvent;
  TempPoint: TPoint;
  TempTime: Integer;
begin
  GetCursorPos(TempPoint);
  TempPoint := Panel1.ScreenToclient(TempPoint);

  if CancelPreviousClick(TempPoint.X, TempPoint.Y, TempTime) then
    InitializeLastClick;

  TempEvent.X := TempPoint.X;
  TempEvent.Y := TempPoint.Y;
  TempEvent.modifiers := GetCefMouseModifiers;
  DeviceToLogical(TempEvent, Panel1.ScreenScale);
  chrmosr.SendMouseMoveEvent(@TempEvent, True);
end;

procedure TForm1.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  TempEvent: TCefMouseEvent;
  TempTime: Integer;
begin
{$IFDEF DELPHI14_UP}
  if (ssTouch in Shift) then
    Exit;
{$ENDIF}
  if CancelPreviousClick(X, Y, TempTime) then
    InitializeLastClick;

  TempEvent.X := X;
  TempEvent.Y := Y;
  TempEvent.modifiers := getModifiers(Shift);
  DeviceToLogical(TempEvent, Panel1.ScreenScale);
  chrmosr.SendMouseMoveEvent(@TempEvent, False);
end;

procedure TForm1.Panel1MouseMove(Sender: TObject; Shift: TShiftState;
X, Y: Integer);
begin
  MouseMove(Shift, X, Y);

  // Application.MainForm.SyncMouseEvent('MouseMove', mbLeft, Shift, X, Y);
  SynchronizeMouseEvent('MouseMove', mbLeft, Shift, X, Y);
end;

procedure TForm1.MouseUp(Button: TMouseButton; Shift: TShiftState;
X, Y: Integer);
var
  TempEvent: TCefMouseEvent;
begin
{$IFDEF DELPHI14_UP}
  if (ssTouch in Shift) then
    Exit;
{$ENDIF}
  TempEvent.X := X;
  TempEvent.Y := Y;
  TempEvent.modifiers := getModifiers(Shift);
  DeviceToLogical(TempEvent, Panel1.ScreenScale);
  chrmosr.SendMouseClickEvent(@TempEvent, GetButton(Button), True,
    FLastClickCount);

//    outputdebugstring(pchar('mouse up ' + inttostr(X) + ',' + inttostr(Y)));
end;

procedure TForm1.Panel1MouseUp(Sender: TObject; Button: TMouseButton;
Shift: TShiftState; X, Y: Integer);
begin
  MouseUp(Button, Shift, X, Y);

  SynchronizeMouseEvent('MouseUp', Button, Shift, X, Y);
end;

procedure TForm1.Panel1PaintParentBkg(Sender: TObject);
begin
  // This event should only be used if you enabled transparency in the browser
  if TRANSPARENT_BROWSER then
  begin
    // This event should copy the background image into Panel1.Canvas
    // The TBufferPanel uses "AlphaBlend" to draw the browser contents over
    // this background image.
    // For simplicity, we just paint it green.
    Panel1.Canvas.Brush.Color := clGreen;
    Panel1.Canvas.Brush.Style := bsSolid;
    Panel1.Canvas.FillRect(rect(0, 0, Panel1.width, Panel1.height));
  end;
end;

procedure TForm1.Panel1PointerDown(Sender: TObject; var aMessage: TMessage;
var aHandled: Boolean);
begin
{$IFDEF DELPHI14_UP}
  aHandled := Panel1.Focused and (GlobalCEFApp <> nil) and
    ArePointerEventsSupported and HandlePointerEvent(aMessage);
{$ELSE}
  aHandled := False;
{$ENDIF}
end;

procedure TForm1.Panel1PointerUp(Sender: TObject; var aMessage: TMessage;
var aHandled: Boolean);
begin
{$IFDEF DELPHI14_UP}
  aHandled := Panel1.Focused and (GlobalCEFApp <> nil) and
    ArePointerEventsSupported and HandlePointerEvent(aMessage);
{$ELSE}
  aHandled := False;
{$ENDIF}
end;

procedure TForm1.Panel1PointerUpdate(Sender: TObject; var aMessage: TMessage;
var aHandled: Boolean);
begin
{$IFDEF DELPHI14_UP}
  aHandled := Panel1.Focused and (GlobalCEFApp <> nil) and
    ArePointerEventsSupported and HandlePointerEvent(aMessage);
{$ELSE}
  aHandled := False;
{$ENDIF}
end;

{$IFDEF DELPHI14_UP}

function TForm1.HandlePointerEvent(var aMessage: TMessage): Boolean;
const
  PT_TOUCH = 2;
  PT_PEN = 3;
var
  TempID: uint32;
  TempType: POINTER_INPUT_TYPE;
begin
  Result := False;
  TempID := LOWORD(aMessage.wParam);

  if GetPointerType(TempID, @TempType) then
    case TempType of
      PT_PEN:
        Result := HandlePenEvent(TempID, aMessage.Msg);
      PT_TOUCH:
        Result := HandleTouchEvent(TempID, aMessage.Msg);
    end;
end;

function TForm1.HandlePenEvent(const aID: uint32; aMsg: cardinal): Boolean;
var
  TempPenInfo: POINTER_PEN_INFO;
  TempTouchEvent: TCefTouchEvent;
  TempPoint: TPoint;
  TempScale: single;
begin
  Result := False;

  if not(GetPointerPenInfo(aID, @TempPenInfo)) then
    Exit;

  TempTouchEvent.id := aID;
  TempTouchEvent.X := 0;
  TempTouchEvent.Y := 0;
  TempTouchEvent.radius_x := 0;
  TempTouchEvent.radius_y := 0;
  TempTouchEvent.type_ := CEF_TET_RELEASED;
  TempTouchEvent.modifiers := EVENTFLAG_NONE;

  if ((TempPenInfo.penFlags and PEN_FLAG_ERASER) <> 0) then
    TempTouchEvent.pointer_type := CEF_POINTER_TYPE_ERASER
  else
    TempTouchEvent.pointer_type := CEF_POINTER_TYPE_PEN;

  if ((TempPenInfo.penMask and PEN_MASK_PRESSURE) <> 0) then
    TempTouchEvent.pressure := TempPenInfo.pressure / 1024
  else
    TempTouchEvent.pressure := 0;

  if ((TempPenInfo.penMask and PEN_MASK_ROTATION) <> 0) then
    TempTouchEvent.rotation_angle := TempPenInfo.rotation / 180 * Pi
  else
    TempTouchEvent.rotation_angle := 0;

  Result := True;

  case aMsg of
    WM_POINTERDOWN:
      TempTouchEvent.type_ := CEF_TET_PRESSED;

    WM_POINTERUPDATE:
      if ((TempPenInfo.pointerInfo.pointerFlags and POINTER_FLAG_INCONTACT) <> 0)
      then
        TempTouchEvent.type_ := CEF_TET_MOVED
      else
        Exit; // Ignore hover events.

    WM_POINTERUP:
      TempTouchEvent.type_ := CEF_TET_RELEASED;
  end;

  if ((TempPenInfo.pointerInfo.pointerFlags and POINTER_FLAG_CANCELED) <> 0)
  then
    TempTouchEvent.type_ := CEF_TET_CANCELLED;

  TempScale := Panel1.ScreenScale;
  TempPoint := Panel1.ScreenToclient(TempPenInfo.pointerInfo.ptPixelLocation);
  TempTouchEvent.X := DeviceToLogical(TempPoint.X, TempScale);
  TempTouchEvent.Y := DeviceToLogical(TempPoint.Y, TempScale);

  chrmosr.SendTouchEvent(@TempTouchEvent);
end;

function TForm1.HandleTouchEvent(const aID: uint32; aMsg: cardinal): Boolean;
var
  TempTouchInfo: POINTER_TOUCH_INFO;
  TempTouchEvent: TCefTouchEvent;
  TempPoint: TPoint;
  TempScale: single;
begin
  Result := False;

  if not(GetPointerTouchInfo(aID, @TempTouchInfo)) then
    Exit;

  TempTouchEvent.id := aID;
  TempTouchEvent.X := 0;
  TempTouchEvent.Y := 0;
  TempTouchEvent.radius_x := 0;
  TempTouchEvent.radius_y := 0;
  TempTouchEvent.rotation_angle := 0;
  TempTouchEvent.pressure := 0;
  TempTouchEvent.type_ := CEF_TET_RELEASED;
  TempTouchEvent.modifiers := EVENTFLAG_NONE;
  TempTouchEvent.pointer_type := CEF_POINTER_TYPE_TOUCH;

  Result := True;

  case aMsg of
    WM_POINTERDOWN:
      TempTouchEvent.type_ := CEF_TET_PRESSED;

    WM_POINTERUPDATE:
      if ((TempTouchInfo.pointerInfo.pointerFlags and POINTER_FLAG_INCONTACT)
        <> 0) then
        TempTouchEvent.type_ := CEF_TET_MOVED
      else
        Exit; // Ignore hover events.

    WM_POINTERUP:
      TempTouchEvent.type_ := CEF_TET_RELEASED;
  end;

  if ((TempTouchInfo.pointerInfo.pointerFlags and POINTER_FLAG_CANCELED) <> 0)
  then
    TempTouchEvent.type_ := CEF_TET_CANCELLED;

  TempScale := Panel1.ScreenScale;
  TempPoint := Panel1.ScreenToclient(TempTouchInfo.pointerInfo.ptPixelLocation);
  TempTouchEvent.X := DeviceToLogical(TempPoint.X, TempScale);
  TempTouchEvent.Y := DeviceToLogical(TempPoint.Y, TempScale);

  chrmosr.SendTouchEvent(@TempTouchEvent);
end;
{$ENDIF}

procedure TForm1.Panel1Resize(Sender: TObject);
begin
  DoResize;
end;

procedure TForm1.PendingResizeMsg(var aMessage: TMessage);
begin
  DoResize;
end;

procedure TForm1.RangeChangedMsg(var aMessage: TMessage);
begin
  try
    FIMECS.Acquire;
    Panel1.ChangeCompositionRange(FSelectedRange, FDeviceBounds);
  finally
    FIMECS.Release;
  end;
end;

procedure TForm1.FocusEnabledMsg(var aMessage: TMessage);
begin
  if Panel1.Focused then
    chrmosr.SetFocus(True)
  else
    Panel1.SetFocus;
end;

procedure TForm1.DevToolsDataAvailableMsg(var aMessage: TMessage);
var
  TempData: TBytes;
  TempFile: TFileStream;
  TempLen: Integer;
  Stream: TMemoryStream;
begin
  if (aMessage.wParam <> 0) then
  begin
    if (length(FDevToolsMsgValue) > 0) then
    begin
      TempData := nil;

      case FPendingMsgID of
        DEVTOOLS_SCREENSHOT_MSGID:
          begin
            SaveDialog1.DefaultExt := 'png';
            SaveDialog1.Filter := 'PNG files (*.png)|*.PNG';
{$IFDEF DELPHI21_UP}
            // TO-DO: TNetEncoding was a new feature in Delphi XE7. Replace
            // TNetEncoding.Base64.DecodeStringToBytes with Soap.EncdDecd.DecodeBase64 for older Delphi versions
            TempData := TNetEncoding.Base64.DecodeStringToBytes
              (FDevToolsMsgValue);

            Stream := TMemoryStream.Create;
            try
              Stream.WriteBuffer(TempData[0], length(TempData));
              Stream.Position := 0; // Reset stream position to start

              // Load the stream into the bitmap
              // screenshot.LoadFromStream(Stream);
            finally
              Stream.Free;
            end;

{$ENDIF}
          end;

      end;

      FPendingMsgID := 0;
      TempLen := length(TempData);

      if (TempLen > 0) then
      begin
        TempFile := nil;

        if SaveDialog1.Execute then
          try
            try
              TempFile := TFileStream.Create(SaveDialog1.FileName, fmCreate);
              TempFile.WriteBuffer(TempData[0], TempLen);
              showmessage('File saved successfully');
            except
              showmessage('There was an error saving the file');
            end;
          finally
            if (TempFile <> nil) then
              TempFile.Free;
          end;
      end
      else
        showmessage('There was an error decoding the data');
    end
    else
      showmessage('DevTools method executed successfully!');
  end
  else if (length(FDevToolsMsgValue) > 0) then
    showmessage(FDevToolsMsgValue)
  else
    showmessage('There was an error in the DevTools method');
end;

procedure TForm1.DoResize;
begin
  try
    FResizeCS.Acquire;

    if FResizing then
      FPendingResize := True
    else if Panel1.BufferIsResized then
      chrmosr.Invalidate(PET_VIEW)
    else
    begin
      FResizing := True;
      chrmosr.WasResized;
    end;
  finally
    FResizeCS.Release;
  end;
end;

procedure TForm1.InitializeLastClick;
begin
  FLastClickCount := 1;
  FLastClickTime := 0;
  FLastClickPoint.X := 0;
  FLastClickPoint.Y := 0;
  FLastClickButton := mbLeft;
end;

function TForm1.CancelPreviousClick(X, Y: Integer;
var aCurrentTime: Integer): Boolean;
begin
  aCurrentTime := GetMessageTime;

  Result := (abs(FLastClickPoint.X - X) > (GetSystemMetrics(SM_CXDOUBLECLK)
    div 2)) or (abs(FLastClickPoint.Y - Y) > (GetSystemMetrics(SM_CYDOUBLECLK)
    div 2)) or (cardinal(aCurrentTime - FLastClickTime) > GetDoubleClickTime);
end;

function TForm1.ArePointerEventsSupported: Boolean;
begin
{$IFDEF DELPHI14_UP}
  Result := FAtLeastWin8 and (@GetPointerType <> nil) and
    (@GetPointerTouchInfo <> nil) and (@GetPointerPenInfo <> nil);
{$ELSE}
  Result := False;
{$ENDIF}
end;

procedure TForm1.Panel1Enter(Sender: TObject);
begin
  // chrmosr.SetFocus(True);
end;

procedure TForm1.Panel1Exit(Sender: TObject);
begin
  // chrmosr.SetFocus(False);
end;

procedure TForm1.SnapshotBtnClick(Sender: TObject);
begin
  if SaveDialog1.Execute then
    Panel1.SaveToFile(SaveDialog1.FileName);
end;

procedure TForm1.SnapshotBtnEnter(Sender: TObject);
begin
  chrmosr.SetFocus(False);
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
  TempContext: ICefRequestContext;
  TempCache: string;
begin
  Timer1.Enabled := False;
  try
    TempCache := GlobalCEFApp.RootCache + '\cache' +
      inttostr(MainForm.BrowserCount);
    TempContext := TCefRequestContextRef.New(TempCache, '', '', False, False,
      chrmosr.ReqContextHandler);
    if chrmosr.CreateBrowser(nil, '', TempContext) then
      chrmosr.InitializeDragAndDrop(Panel1)
    else if not(chrmosr.Initialized) then
      Timer1.Enabled := True;

  finally

    TempContext := nil;
  end;
end;

procedure TForm1.Timer2Timer(Sender: TObject);
var
   coordY:integer;
begin
if getYCoords(prevYCoords, coordY) then
begin
   //
end;
end;

procedure TForm1.captureScreenshot;
begin
  // exit;
  // FPendingMsgID := DEVTOOLS_SCREENSHOT_MSGID;
  // chrmosr.ExecuteDevToolsMethod(0, 'Page.captureScreenshot', nil);
end;

procedure TForm1.chrmosrIMECompositionRangeChanged(Sender: TObject;
const browser: ICefBrowser; const selected_range: PCefRange;
character_boundsCount: NativeUInt; const character_bounds: PCefRect);
var
  TempPRect: PCefRect;
  i: NativeUInt;
  TempScale: single;
begin
  try
    FIMECS.Acquire;

    // TChromium.OnIMECompositionRangeChanged is triggered in a different thread
    // and all functions using a IMM context need to be executed in the same
    // thread, in this case the main thread. We need to save the parameters and
    // send a message to the form to execute Panel1.ChangeCompositionRange in
    // the main thread.

    if (FDeviceBounds <> nil) then
    begin
      Finalize(FDeviceBounds);
      FDeviceBounds := nil;
    end;

    FSelectedRange := selected_range^;

    if (character_boundsCount > 0) then
    begin
      SetLength(FDeviceBounds, character_boundsCount);

      i := 0;
      TempPRect := character_bounds;
      TempScale := Panel1.ScreenScale;

      while (i < character_boundsCount) do
      begin
        FDeviceBounds[i] := TempPRect^;
        LogicalToDevice(FDeviceBounds[i], TempScale);

        Inc(TempPRect);
        Inc(i);
      end;
    end;

    PostMessage(Handle, CEF_IMERANGECHANGED, 0, 0);
  finally
    FIMECS.Release;
  end;
end;

procedure TForm1.Panel1IMECancelComposition(Sender: TObject);
begin
  chrmosr.IMECancelComposition;
end;

procedure TForm1.Panel1IMECommitText(Sender: TObject; const aText: ustring;
const replacement_range: PCefRange; relative_cursor_pos: Integer);
begin
  chrmosr.IMECommitText(aText, replacement_range, relative_cursor_pos);
end;

procedure TForm1.Panel1IMESetComposition(Sender: TObject; const aText: ustring;
const underlines: TCefCompositionUnderlineDynArray;
const replacement_range: TCefRange; const selection_range: TCefRange);
begin
  chrmosr.IMESetComposition(aText, underlines, @replacement_range,
    @selection_range);
end;

function TForm1.searchImage(TemplateImg: pCvMat_t; threshold: Double): Boolean;
var
  matchCount: Double;
  screenshot: TBitmap;
begin
  Result := False;
  if TemplateImg = nil then
    Exit;

  try
    FResizeCS.Acquire;

    if Panel1.buffer = nil then
      Exit;
    if Panel1.buffer.Empty then
      Exit;

    screenshot := TBitmap.Create;
    try
      screenshot.width := Panel1.buffer.width;
      screenshot.height := Panel1.buffer.height;
      screenshot.PixelFormat := pf24bit;

      BitBlt(screenshot.Canvas.Handle, 0, 0, Panel1.buffer.width,
        Panel1.buffer.height, Panel1.buffer.Canvas.Handle, 0, 0, SRCCOPY);

      matchCount := PerformTemplateMatching(screenshot, TemplateImg, threshold);

      if not isInfinite(matchCount) then
      begin
        Form1.Caption := floatTostr(matchCount);

        if matchCount > threshold then
        begin
          // playBeep();
          Result := True;
        end;
      end;
    finally
      screenshot.Free;
    end;
  finally
    FResizeCS.Release;
  end;
end;

procedure TForm1.SynchronizeMouseEvent(EventType: string; Button: TMouseButton;
Shift: TShiftState; X, Y: Integer);
var
  i: Integer;
  Child: TForm1;
begin
  if not IsScrollLockOn then
    Exit;
  // outputdebugstring(pchar('sync mouse event pal child '+eventtype));
  // Loop through all MDI children except the current one
  for i := 0 to application.MainForm.MDIChildCount - 1 do
  begin
    Child := TForm1(application.MainForm.MDIChildren[i]);
    if Child <> Self then
    begin
      // Perform the action on each sibling (customize as needed)
      if EventType = 'MouseDown' then
      begin
        Child.MouseDown(Button, Shift, X, Y);
        // outputdebugstring(pchar(caption+' : sync mouse event pal child '+eventtype));
      end
      else if EventType = 'MouseUp' then
      begin
        Child.MouseUp(Button, Shift, X, Y);
        // outputdebugstring(pchar(caption+' : sync mouse event pal child '+eventtype));
      end
      else if EventType = 'MouseClick' then
      begin
        Child.pClick;
        // outputdebugstring(pchar(caption+' : sync mouse event pal child '+eventtype));
      end
      else if EventType = 'MouseMove' then
      begin
        Child.MouseMove(Shift, X, Y);
        // outputdebugstring(pchar(caption+' : sync mouse event pal child '+eventtype));
      end;
      // Add more event types as needed
    end;
  end;
end;

end.
