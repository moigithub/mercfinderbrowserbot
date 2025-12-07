unit uWSHandler;

{$I D:\downloads\delphi.components\CEF4Delphi\source\cef.inc}

interface

uses
  {$IFDEF DELPHI16_UP}
  Vcl.Forms,
  Winapi.Windows,
  {$ELSE}
  Forms,
  Windows,
  {$ENDIF}
  uCEFRenderProcessHandler, uCEFBrowserProcessHandler, uCEFInterfaces, uCEFProcessMessage,
  uCEFv8Context, uCEFTypes, uCEFv8Handler;

type
  TWSHandler  = class(TCefv8HandlerOwn)
    protected
      function Execute(const name: ustring; const object_: ICefv8Value; const arguments: TCefv8ValueArray; var retval: ICefv8Value; var exception: ustring): Boolean; override;
   public
    constructor Create;
  end;

var
  // Use a Windows Message to safely pass data from the CEF Render process thread
  // to the main VCL thread.
  WS_MESSAGE : Cardinal;

implementation

uses
  uCEFMiscFunctions, uCEFConstants;

constructor TWSHandler .Create;
begin
  inherited Create;
  // Register a custom Windows message ID
  WS_MESSAGE := RegisterWindowMessage('CEF4Delphi_WS_Data');
end;

function TWSHandler .Execute(const name      : ustring;
                                       const object_   : ICefv8Value;
                                       const arguments : TCefv8ValueArray;
                                       var   retval    : ICefv8Value;
                                       var   exception : ustring): Boolean;

var
  Data: ustring;
  MainWindowHandle: THandle;
   ProcessMessage: ICefProcessMessage;
    Args: ICefListValue;
      TempFrame   : ICefFrame;
        Context: ICefV8Context;
  Browser: ICefBrowser;
  Frame: ICefFrame;
begin
  Result := True;
  if name = 'sendWebSocketData' then
  begin
    if (length(arguments) > 0) and arguments[0].IsString then
    begin
      Data := arguments[0].GetStringValue;
      // Send the data safely to the main Delphi form using a Windows message
//      MainWindowHandle := Application.MainFormHandle;
//      if MainWindowHandle <> 0 then
//      begin
        // We use CopyDataStruct to send the string safely between threads/processes
        // For simplicity here, we'll use PostMessage and a global variable or similar
        // IPC mechanism for this example, but a process message (CefProcessMessage)
        // is the standard, robust CEF way (see JSExtension demo for full IPC).
        // For simple VCL apps, using Windows messages is a quick solution.

        // **Simplified (less robust) VCL PostMessage example:**
        // PostMessage(MainWindowHandle, WS_MESSAGE, 0, integer(PChar(Data))); // Requires memory management

        // **The correct way for CEF is usually CefProcessMessage or the JSExtension demo IPC**
        // Since that is complex, we stick to the ConsoleMessage trick for simplicity
        // as mentioned previously, or use the exact IPC method from the CEF4Delphi demos.

        // Reverting to the console message trick for simplicity as IPC is complex
        // within this format. The handler is mostly used for simple command calls.
        // The previous OnConsoleMessage method is much simpler for raw data transfer.

        // If you need the handler method, you should use the IPC in the JSExtension demo.
//     end;
      Context := TCefV8ContextRef.Current;
      if Assigned(Context) and Context.Enter then
      try
        Browser := Context.GetBrowser;
        Frame := Context.GetFrame;

        if Assigned(Browser) then
        begin
         // 1. Create a new process message named 'WebSocketDataMessage'
      ProcessMessage := TCefProcessMessageRef.New('WebSocketDataMessage');
      Args := ProcessMessage.GetArgumentList;

      // 2. Add the captured data as the first argument (index 0)
      Args.SetString(0, Data);

      // 3. Send the message from the Render process to the Browser process
//      browser.SendProcessMessage(PID_BROWSER, ProcessMessage);
//       TempFrame := TCefv8ContextRef.Current.Browser.MainFrame;
//        if (TempFrame <> nil) and TempFrame.IsValid then
//              TempFrame.SendProcessMessage(PID_BROWSER, ProcessMessage);

          Browser.MainFrame.SendProcessMessage(PID_BROWSER, ProcessMessage);
      end;

      finally
        Context.Exit;
      end;
    end;
  end;
end;




end.

