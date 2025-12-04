object Form1: TForm1
  Left = 0
  Top = 0
  Width = 1501
  Height = 957
  AutoScroll = True
  Caption = 'Simple OSR Browser - Initializing browser. Please wait...'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  FormStyle = fsMDIChild
  Position = poScreenCenter
  Visible = True
  OnAfterMonitorDpiChanged = FormAfterMonitorDpiChanged
  OnClose = FormClose
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnHide = FormHide
  OnShow = FormShow
  TextHeight = 13
  object Image1: TImage
    Left = 1190
    Top = 112
    Width = 51
    Height = 33
  end
  object Image2: TImage
    Left = 1247
    Top = 112
    Width = 53
    Height = 33
  end
  object Image3: TImage
    Left = 1306
    Top = 112
    Width = 53
    Height = 33
  end
  object Label1: TLabel
    Left = 1190
    Top = 237
    Width = 27
    Height = 13
    Caption = 'Delay'
  end
  object Panel1: TBufferPanel
    Left = 0
    Top = 32
    Width = 1163
    Height = 881
    OnIMECancelComposition = Panel1IMECancelComposition
    OnIMECommitText = Panel1IMECommitText
    OnIMESetComposition = Panel1IMESetComposition
    OnCustomTouch = Panel1CustomTouch
    OnPointerDown = Panel1PointerDown
    OnPointerUp = Panel1PointerUp
    OnPointerUpdate = Panel1PointerUpdate
    OnPaintParentBkg = Panel1PaintParentBkg
    Ctl3D = False
    ParentCtl3D = False
    BevelOuter = bvNone
    TabOrder = 2
    TabStop = True
    OnClick = Panel1Click
    OnEnter = Panel1Enter
    OnExit = Panel1Exit
    OnMouseDown = Panel1MouseDown
    OnMouseMove = Panel1MouseMove
    OnMouseUp = Panel1MouseUp
    OnResize = Panel1Resize
    OnMouseLeave = Panel1MouseLeave
    object panelOverlay: TPanel
      Left = 1
      Top = 0
      Width = 1023
      Height = 769
      BevelInner = bvRaised
      BevelKind = bkSoft
      BevelOuter = bvLowered
      BorderWidth = 10
      BorderStyle = bsSingle
      TabOrder = 0
      Visible = False
    end
  end
  object NavControlPnl: TPanel
    Left = 0
    Top = 0
    Width = 1485
    Height = 30
    Align = alTop
    BevelOuter = bvNone
    Padding.Left = 5
    Padding.Top = 5
    Padding.Right = 5
    Padding.Bottom = 5
    TabOrder = 0
    object AddressCb: TComboBox
      Left = 5
      Top = 5
      Width = 812
      Height = 21
      Align = alLeft
      TabOrder = 0
      Text = 'https://totalbattle.com?present=gold'
      OnEnter = AddressCbEnter
    end
    object Panel2: TPanel
      Left = 1355
      Top = 5
      Width = 125
      Height = 20
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Align = alRight
      BevelOuter = bvNone
      Padding.Left = 4
      TabOrder = 1
      object GoBtn: TButton
        Left = 4
        Top = 0
        Width = 40
        Height = 20
        Align = alLeft
        Caption = 'Go'
        TabOrder = 0
        OnClick = GoBtnClick
        OnEnter = GoBtnEnter
      end
      object SnapshotBtn: TButton
        Left = 94
        Top = 0
        Width = 31
        Height = 20
        Hint = 'Take snapshot'
        Margins.Left = 5
        Align = alRight
        Caption = #181
        Font.Charset = SYMBOL_CHARSET
        Font.Color = clWindowText
        Font.Height = -24
        Font.Name = 'Webdings'
        Font.Style = []
        ParentFont = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 1
        OnClick = SnapshotBtnClick
        OnEnter = SnapshotBtnEnter
      end
      object Button1: TButton
        Left = 64
        Top = 0
        Width = 30
        Height = 20
        Align = alRight
        Caption = 'R'
        TabOrder = 2
        OnClick = Button1Click
      end
    end
  end
  object Button2: TButton
    Left = 1169
    Top = 36
    Width = 96
    Height = 49
    Caption = 'Start'
    TabOrder = 1
    OnClick = Button2Click
  end
  object Memo1: TMemo
    Left = 1224
    Top = 280
    Width = 253
    Height = 520
    ScrollBars = ssVertical
    TabOrder = 3
  end
  object memoKingdoms: TMemo
    Left = 1169
    Top = 280
    Width = 49
    Height = 520
    Lines.Strings = (
      '142'
      '147'
      '150'
      '143'
      '151'
      '138'
      '139'
      '148'
      '152'
      '154'
      '155'
      '144'
      '148'
      '156'
      '141'
      '145'
      '149'
      '153'
      '157')
    TabOrder = 4
  end
  object Button3: TButton
    Left = 1271
    Top = 38
    Width = 89
    Height = 45
    Caption = 'Stop'
    TabOrder = 5
    OnClick = Button3Click
  end
  object Edit1: TEdit
    Left = 1190
    Top = 151
    Width = 51
    Height = 21
    TabOrder = 6
    Text = '0'
  end
  object Edit2: TEdit
    Left = 1247
    Top = 151
    Width = 53
    Height = 21
    TabOrder = 7
    Text = '0'
  end
  object Edit3: TEdit
    Left = 1306
    Top = 151
    Width = 57
    Height = 21
    TabOrder = 8
    Text = '0'
  end
  object chkBrowserLock: TCheckBox
    Left = 1190
    Top = 211
    Width = 97
    Height = 17
    Caption = 'BrowserLock'
    TabOrder = 9
    OnClick = chkBrowserLockClick
  end
  object seDelay: TSpinEdit
    Left = 1238
    Top = 234
    Width = 54
    Height = 22
    Increment = 10
    MaxValue = 1000
    MinValue = 10
    TabOrder = 10
    Value = 50
  end
  object chkToRight: TCheckBox
    Left = 1380
    Top = 153
    Width = 97
    Height = 17
    Caption = 'Going Right ?'
    Checked = True
    State = cbChecked
    TabOrder = 11
  end
  object Button4: TButton
    Left = 1169
    Top = 806
    Width = 49
    Height = 33
    Caption = 'Button4'
    TabOrder = 12
    OnClick = Button4Click
  end
  object chkReloading: TCheckBox
    Left = 1384
    Top = 256
    Width = 97
    Height = 17
    Caption = 'chkReloading'
    TabOrder = 13
  end
  object btnRotate: TButton
    Left = 1169
    Top = 845
    Width = 50
    Height = 25
    Caption = 'Rotate'
    TabOrder = 14
    OnClick = btnRotateClick
  end
  object chrmosr: TChromium
    OnCanFocus = chrmosrCanFocus
    OnTooltip = chrmosrTooltip
    OnConsoleMessage = chrmosrConsoleMessage
    OnCursorChange = chrmosrCursorChange
    OnBeforePopup = chrmosrBeforePopup
    OnAfterCreated = chrmosrAfterCreated
    OnBeforeClose = chrmosrBeforeClose
    OnRenderProcessUnresponsive = chrmosrRenderProcessUnresponsive
    OnRenderProcessTerminated = chrmosrRenderProcessTerminated
    OnGetViewRect = chrmosrGetViewRect
    OnGetScreenPoint = chrmosrGetScreenPoint
    OnGetScreenInfo = chrmosrGetScreenInfo
    OnPopupShow = chrmosrPopupShow
    OnPopupSize = chrmosrPopupSize
    OnPaint = chrmosrPaint
    OnIMECompositionRangeChanged = chrmosrIMECompositionRangeChanged
    OnDevToolsMethodResult = chrmosrDevToolsMethodResult
    Left = 24
    Top = 56
  end
  object AppEvents: TApplicationEvents
    OnMessage = AppEventsMessage
    Left = 24
    Top = 128
  end
  object SaveDialog1: TSaveDialog
    DefaultExt = 'bmp'
    Filter = 'Bitmap files (*.bmp)|*.BMP'
    Title = 'Save snapshot'
    Left = 24
    Top = 278
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 300
    OnTimer = Timer1Timer
    Left = 24
    Top = 206
  end
  object Timer2: TTimer
    Enabled = False
    OnTimer = Timer2Timer
    Left = 1424
    Top = 192
  end
end
