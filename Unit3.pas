unit Unit3;

interface

uses Vcl.Imaging.jpeg, Vcl.Controls, Vcl.ExtCtrls,
  OPENCVWrapper, Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Forms, Vcl.Dialogs, Vcl.ExtDlgs, Vcl.Graphics, Vcl.StdCtrls,
  System.Generics.Collections;

function PerformTemplateMatching(screenshot:TBitmap;TemplateImg: pCvMat_t; threshold: single): double;
 function IsScrollLockOn: Boolean;
 procedure playBeep();

implementation

uses uMainForm;

type
  TDetection = class
    confidence: double;
    classId: Integer;
    box: TRect;
    nsmValid: Boolean;
  end;

var
  NMS_THRES: single = 0.5;

  function IsScrollLockOn: Boolean;
begin
  // GetKeyState returns a value; check if the LSB is set (1 = on)
  Result := (GetKeyState(VK_SCROLL) and 1) <> 0;
end;


procedure playBeep();

begin

  Winapi.Windows.Beep(800, 100);
  // windows.sysutils.beep; // no funciona

end;

function DrawRectangleOnMatch(const SourceImg, ResultImg: pCvMat_t; const TemplateImg: pCvMat_t;
  threshold: single): double;
var
  MinVal, MaxVal: double;
  MinLoc, MaxLoc: pCvPoint_t;
 winame1,winame2,winame3: CvString_t;
begin
  Result := 0;
  try
//    MinLoc := pCvPointCreate();
//    MaxLoc := pCvPointCreate();
//    pcvminMaxLoc(ResultImg, @MinVal, @MaxVal, MinLoc, MaxLoc, nil);
    pcvminMaxLoc(ResultImg, @MinVal, @MaxVal, nil, nil, nil);
    Result := MaxVal;
//outputdebugstring(pchar('minmaxloc '+maxval.ToString()));

  // Display the result
//   winame1.pstr:= PAnsiChar(AnsiString('template'));
//   pCvimshow(@winame1, TemplateImg );
//
//   winame2.pstr:= PAnsiChar(AnsiString('SourceImg'));
//   pCvimshow(@winame2, SourceImg );
//
//   winame3.pstr:= PAnsiChar(AnsiString('result'));
//   pCvimshow(@winame3, ResultImg );


  finally
//    if assigned(MinLoc) then
//      pCvPointDelete(MinLoc);
//    if assigned(MaxLoc) then
//      pCvPointDelete(MaxLoc);
  end;
end;

function PerformTemplateMatching(screenshot:TBitmap;TemplateImg: pCvMat_t; threshold: single): double;
var
//  DesktopBitmap,
   tmp,tmp2,tmp3: TBitmap;
  SourceImg, ResultImg, templateClone: pCvMat_t;
  // GraySourceImg, GrayTemplateImg: pCvMat_t;
  TemplateFileName: string;

  ResultWidth, ResultHeight: Integer;
begin
  Result := 0;

  if screenshot = nil then exit;
  if templateImg = nil then exit;
  

//  DesktopBitmap := nil;
  tmp:=nil;
  SourceImg := nil;
  ResultImg := nil;

  try
//    DesktopBitmap := TBitmap.Create;

    // Capture the desktop image
//    CaptureDesktop(DesktopBitmap);

    // Convert the captured image to OpenCV Mat
    SourceImg := pCvMatImageCreate(screenshot.Width, screenshot.Height, CV_8UC3);
    Bitmap2MatImage(SourceImg, screenshot);

    // Perform template matching
    ResultWidth := pCvMatGetWidth(SourceImg) - pCvMatGetWidth(TemplateImg) + 1;
    ResultHeight := pCvMatGetHeight(SourceImg) - pCvMatGetHeight(TemplateImg) + 1;

    ResultImg := pCvMatImageCreate(ResultWidth, ResultHeight, CV_8UC3); // CV_32FC1   CV_8UC3

    templateClone := pCvMatClone (TemplateImg);
    pcvmatchTemplate(SourceImg, TemplateImg, ResultImg, ord(TM_CCOEFF_NORMED),templateClone);

    /// show result image
//    if form1.CheckBox2.Checked then begin
//      tmp:=Tbitmap.Create;
//      tmp.PixelFormat := pf24bit;
//
////      tmp.Width := pCvMatGetWidth(templateImg) ;
////      tmp.Height :=  pCvMatGetHeight(templateImg);
////      MatImage2Bitmap(templateImg,tmp);
////      form1.imgTemplate.Picture.Assign(tmp)  ;
//
//      tmp.Width := pCvMatGetWidth(SourceImg) ;
//      tmp.Height :=  pCvMatGetHeight(SourceImg);
//      MatImage2Bitmap(SourceImg,tmp);
//      form1.imgDesktop.Picture.Assign(tmp)  ;
//
////      tmp.Width := pCvMatGetWidth(ResultImg) ;
////      tmp.Height :=  pCvMatGetHeight(ResultImg);
////      MatImage2Bitmap(ResultImg,tmp);
////      form1.imgResult.Picture.Assign(tmp)  ;
//    end;


    // use grey images
    // ResultImg := MatchTemplate(GraySourceImg, GrayTemplateImg);

    // Draw rectangle on match and display result
    Result := DrawRectangleOnMatch(SourceImg, ResultImg, TemplateImg, threshold);

  finally
    // Release images

    if assigned(ResultImg) then
      pCvMatDelete(ResultImg);
    if assigned(SourceImg) then
      pCvMatDelete(SourceImg);
    if assigned(templateClone) then
      pCvMatDelete(templateClone);

//    if assigned(DesktopBitmap) then
//      DesktopBitmap.Free;

    if assigned(tmp) then
      tmp.Free;
  end;
end;

end.
