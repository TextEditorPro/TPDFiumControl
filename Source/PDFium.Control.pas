﻿unit PDFium.Control;

{.$DEFINE USE_LOAD_FROM_URL}

interface

uses
  Winapi.Messages, Winapi.Windows, System.Classes, System.Math, System.SysUtils, System.UITypes, System.Variants,
  Vcl.Controls, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Forms, Vcl.Graphics, Vcl.Grids, PDFiumCore, PDFiumLib
{$IFDEF ALPHASKINS}
  , acSBUtils, sCommonData
{$ENDIF};

const
  CDefaultDrawOptions = [proAnnotations];

type
  TPDFZoomMode = (zmActualSize, zmFitHeight, zmFitWidth, zmPercent);

  TPDFControlRectArray = array of TRect;
  TPDFControlPDFRectArray = TArray<TPDFRect>;

  TPDFControlClickLinkEvent = procedure(const ASender: TObject; const AURL: string) of object;
  TPDFControlScrollEvent = procedure(const ASender: TObject; const AScrollBar: TScrollBarKind) of object;
  TPDFLoadProtectedEvent = procedure(const ASender: TObject; var APassword: UTF8String) of object;

  TPageInfo = record
    Height: Single;
    Index: Integer;
    Rect: TRect;
    Rotation: TPDFPageRotation;
    SearchCurrentIndex: Integer;
    SearchRects: TPDFControlPDFRectArray;
    Visible: Integer;
    Width: Single;
  end;

  { Page is not a public property in core class }
  TPDFPageHelper = class helper for PDFiumCore.TPDFPage
    function Page: FPDF_PAGE;
  end;

  TPDFiumControl = class(TScrollingWinControl)
  strict private
    FAllowFormFieldEdit: Boolean;
    FAllowTextSelection: Boolean;
    FChanged: Boolean;
    FDrawOptions: TPdfPageRenderOptions;
    FFilename: string;
    FFormFieldFocused: Boolean;
    FFormOutputSelectedRects: TPDFControlPDFRectArray;
    FHeight: Single;
    FMouseDownPoint: TPoint;
    FMousePressed: Boolean;
    FOnClickLink: TPDFControlClickLinkEvent;
    FOnLoadProtected: TPDFLoadProtectedEvent;
    FOnPageChanged: TNotifyEvent;
    FOnPaint: TNotifyEvent;
    FOnScroll: TPDFControlScrollEvent;
    FPageBorderColor: TColor;
    FPageCount: Integer;
    FPageIndex: Integer;
    FPageInfo: TArray<TPageInfo>;
    FPageMargin: Integer;
    FPDFDocument: TPDFDocument;
    FPrintJobTitle: string;
{$IFDEF ALPHASKINS}
    FScrollWnd: TacScrollWnd;
{$ENDIF}
    FSearchCount: Integer;
    FSearchHighlightAll: Boolean;
    FSearchIndex: Integer;
    FSearchMatchCase: Boolean;
    FSearchText: string;
    FSearchWholeWords: Boolean;
    FSelectionActive: Boolean;
    FSelectionStartCharIndex: Integer;
    FSelectionStopCharIndex: Integer;
{$IFDEF ALPHASKINS}
    FSkinData: TsScrollWndData;
{$ENDIF}
    FWebLinksInfo: TPdfPageWebLinksInfo;
    FWidth: Single;
    FZoomMode: TPDFZoomMode;
    FZoomPercent: Single;
    function CreatePDFDocument: TPDFDocument;
    function DeviceToPage(const X, Y: Integer): TPDFPoint;
    function GetCurrentPage: TPDFPage;
    function GetPageIndexAt(const APoint: TPoint): Integer;
    function GetSelectionLength: Integer;
    function GetSelectionRects: TPDFControlRectArray;
    function GetSelectionStart: Integer;
    function GetSelectionText: string;
    function InternPageToDevice(const APage: TPDFPage; const APageRect: TPDFRect; const ARect: TRect): TRect;
    function IsAnnotationLinkAt(const X, Y: Integer; var AURL: string; out ALinkRect: TRect): Boolean;
    function IsCurrentPageValid: Boolean;
    function IsWebLinkAt(const X, Y: Integer): Boolean; overload;
    function IsWebLinkAt(const X, Y: Integer; var AURL: string): Boolean; overload;
    function PageHeightZoomPercent: Single;
    function PageWidthZoomPercent: Single;
    function SelectWord(const ACharIndex: Integer): Boolean;
    function SetSelStopCharIndex(const X, Y: Integer): Boolean;
    procedure AdjustPageInfo;
    procedure AdjustScrollBar(const APageIndex: Integer);
    procedure AdjustZoom;
    procedure AfterLoad;
    procedure CMGesture(var AMessage: TCMGesture); message CM_GESTURE;
    procedure DoScroll(const AScrollBarKind: TScrollBarKind);
    procedure DoSizeChanged;
    procedure FormFieldFocus(ADocument: TPDFDocument; AValue: PWideChar; AValueLen: Integer; AFieldFocused: Boolean);
    procedure FormGetCurrentPage(ADocument: TPDFDocument; var APage: TPDFPage);
    procedure FormInvalidate(ADocument: TPDFDocument; APage: TPDFPage; const APageRect: TPDFRect);
    procedure FormOutputSelectedRect(ADocument: TPDFDocument; APage: TPDFPage; const APageRect: TPDFRect);
    procedure GetPageWebLinks;
    procedure HideHint;
    procedure InvalidateRectDiffs(const AOldRects, ANewRects: TPDFControlRectArray);
    procedure PageChanged;
    procedure PaintAlphaSelection(ADC: HDC; const APage: TPDFPage; const ARects: TPDFControlPDFRectArray; const AIndex: Integer;
      const AColor: TColor = TColors.SysNone);
    procedure PaintPage(ADC: HDC; const APage: TPDFPage; const AIndex: Integer); overload;
    procedure PaintPageBorder(ADC: HDC; const ARect: TRect);
    procedure PaintPageSearchResults(ADC: HDC; const APage: TPDFPage; const AIndex: Integer);
    procedure PaintPageSelection(ADC: HDC; const APage: TPDFPage; const AIndex: Integer);
    procedure SetPageCount(const AValue: Integer);
    procedure SetPageIndex(const AValue: Integer);
    procedure SetPageNumber(const AValue: Integer);
    procedure SetScrollSize;
    procedure SetSearchHighlightAll(const AValue: Boolean);
    procedure SetSelection(const AActive: Boolean; const AStartIndex, AStopIndex: Integer);
    procedure SetZoomMode(const AValue: TPDFZoomMode);
    procedure SetZoomPercent(const AValue: Single);
    procedure ShowHint(const AHint: string; const ARect: TRect);
    procedure UpdatePageIndex;
    procedure WMChar(var AMessage: TWMChar); message WM_CHAR;
    procedure WMEraseBkGnd(var AMessage: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMGetDlgCode(var AMessage: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure WMHScroll(var AMessage: TWMHScroll); message WM_HSCROLL;
    procedure WMKeyDown(var AMessage: TWMKeyDown); message WM_KEYDOWN;
    procedure WMKeyUp(var AMessage: TWMKeyUp); message WM_KEYUP;
    procedure WMKillFocus(var AMessage: TWMKillFocus); message WM_KILLFOCUS;
    procedure WMPaint(var AMessage: TWMPaint); message WM_PAINT;
    procedure WMVScroll(var AMessage: TWMVScroll); message WM_VSCROLL;
  protected
    function DoMouseWheel(AShift: TShiftState; AWheelDelta: Integer; AMousePos: TPoint): Boolean; override;
    function GetPageNumber: Integer;
    function GetPageTop(const APageIndex: Integer): Integer;
    function PageToScreen(const AValue: Single): Integer; inline;
    function ZoomToScreen: Single;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
{$IFDEF ALPHASKINS}
    procedure Loaded; override;
{$ENDIF}
    procedure MouseDown(AButton: TMouseButton; AShift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(AShift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(AButton: TMouseButton; AShift: TShiftState; X, Y: Integer); override;
    procedure PaintWindow(ADC: HDC); override;
    procedure Resize; override;
    procedure ShowError(const AMessage: string); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function GetPage(const AIndex: Integer): TPDFPage;
    function FindNext: Integer;
    function FindPrevious: Integer;
    function IsPageIndexValid(const APageIndex: Integer): Boolean;
    function IsTextSelected: Boolean;
    function SearchAll: Integer; overload;
    function SearchAll(const ASearchText: string): Integer; overload;
    function SearchAll(const ASearchText: string; const AHighlightAll: Boolean; const AMatchCase: Boolean;
      const AWholeWords: Boolean; const AScrollIntoView: Boolean = True; const APageIndex: Integer = -1): Integer; overload;
{$IFDEF ALPHASKINS}
    procedure AfterConstruction; override;
{$ENDIF}
    procedure ClearSearch;
    procedure ClearSelection;
    procedure CloseDocument;
    procedure CopyFormTextToClipboard;
    procedure CopyToClipboard;
    procedure CreateParams(var AParams: TCreateParams); override;
    procedure CutFormTextToClipboard;
    procedure GotoNextPage;
    procedure GotoPage(const AIndex: Integer; const ASetScrollBar: Boolean = True);
    procedure GotoPreviousPage;
    procedure LoadFromFile(const AFilename: string);
    procedure LoadFromStream(const AStream: TStream);
{$IFDEF USE_LOAD_FROM_URL}
    procedure LoadFromURL(const AURL: string);
{$ENDIF}
    procedure PaintPage(ADC: HDC; const ARect: TRect; const AIndex: Integer); overload;
    procedure PasteFormTextFromClipboard;
    procedure Print;
    procedure RotatePageClockwise;
    procedure RotatePageCounterClockwise;
    procedure SaveToFile(const AFilename: string; const AOption: TPdfDocumentSaveOption = dsoRemoveSecurity; const AFileVersion: Integer = -1);
    procedure SaveToStream(const AStream: TStream; const AOption: TPdfDocumentSaveOption = dsoRemoveSecurity; const AFileVersion: Integer = -1);
    procedure SelectAll;
    procedure SelectAllFormText;
    procedure SelectText(const ACharIndex: Integer; const ACount: Integer);
    procedure SetFocus; override;
{$IFDEF ALPHASKINS}
    procedure WndProc(var AMessage: TMessage); override;
{$ENDIF}
    procedure ZoomToHeight;
    procedure ZoomToWidth;
    procedure Zoom(const APercent: Single);
    property CurrentPage: TPDFPage read GetCurrentPage;
    property Filename: string read FFilename write FFilename;
    property PDFDocument: TPDFDocument read FPDFDocument;
    property PageCount: Integer read FPageCount;
    property PageIndex: Integer read FPageIndex write SetPageIndex;
    property PageNumber: Integer read GetPageNumber write SetPageNumber;
    property SearchCount: Integer read FSearchCount write FSearchCount;
    property SearchIndex: Integer read FSearchIndex write FSearchIndex;
    property SearchText: string read FSearchText write FSearchText;
    property SelectionLength: Integer read GetSelectionLength;
    property SelectionStart: Integer read GetSelectionStart;
    property SelectionText: string read GetSelectionText;
{$IFDEF ALPHASKINS}
    property SkinData: TsScrollWndData read FSkinData write FSkinData;
{$ENDIF}
  published
    property Align;
    property AllowFormFieldEdit: Boolean read FAllowFormFieldEdit write FAllowFormFieldEdit default False;
    property AllowTextSelection: Boolean read FAllowTextSelection write FAllowTextSelection default True;
    property Color;
    property DrawOptions: TPdfPageRenderOptions read FDrawOptions write FDrawOptions default CDefaultDrawOptions;
    property OnClickLink: TPDFControlClickLinkEvent read FOnClickLink write FOnClickLink;
    property OnLoadProtected: TPDFLoadProtectedEvent read FOnLoadProtected write FOnLoadProtected;
    property OnPageChanged: TNotifyEvent read FOnPageChanged write FOnPageChanged;
    property OnPaint: TNotifyEvent read FOnPaint write FOnPaint;
    property OnScroll: TPDFControlScrollEvent read FOnScroll write FOnScroll;
    property PageBorderColor: TColor read FPageBorderColor write FPageBorderColor default TColors.Silver;
    property PageMargin: Integer read FPageMargin write FPageMargin default 6;
    property PopupMenu;
    property PrintJobTitle: string read FPrintJobTitle write FPrintJobTitle;
    property SearchHighlightAll: Boolean read FSearchHighlightAll write SetSearchHighlightAll;
    property SearchMatchCase: Boolean read FSearchMatchCase write FSearchMatchCase;
    property SearchWholeWords: Boolean read FSearchWholeWords write FSearchWholeWords;
    property Visible;
    property ZoomMode: TPDFZoomMode read FZoomMode write SetZoomMode default zmActualSize;
    property ZoomPercent: Single read FZoomPercent write SetZoomPercent;
  end;

  TPDFiumControlThumbnails = class(TDrawGrid)
  private
    FDefaultSizeSet: Boolean;
    FIsMousedown: Boolean;
    FPDFiumControl: TPDFiumControl;
{$IFDEF ALPHASKINS}
    FScrollWnd: TacScrollWnd;
    FSkinData: TsScrollWndData;
{$ENDIF}
    FTimerStarted: Boolean;
    procedure DoPDFiumControlPageChanged(Sender: TObject);
    procedure SetDefaultSize;
    procedure SetPDFiumControl(const AValue: TPDFiumControl);
  protected
    function SelectCell(ACol, ARow: Longint): Boolean; override;
    procedure DrawCell(ACol, ARow: Longint; ARect: TRect; AState: TGridDrawState); override;
{$IFDEF ALPHASKINS}
    procedure Loaded; override;
{$ENDIF}
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X: Integer; Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X: Integer; Y: Integer); override;
    procedure Resize; override;
  published
    property PDFiumControl: TPDFiumControl read FPDFiumControl write SetPDFiumControl;
  public
    constructor Create(AOwner: TComponent); override;
{$IFDEF ALPHASKINS}
    destructor Destroy; override;
    procedure AfterConstruction; override;
    procedure WndProc(var AMessage: TMessage); override;
    property SkinData: TsScrollWndData read FSkinData write FSkinData;
{$ENDIF}
  end;

  TPDFDocumentVclPrinter = class(TPDFDocumentPrinter)
  private
    FBeginDocCalled: Boolean;
    FPagePrinted: Boolean;
  protected
    function GetPrinterDC: HDC; override;
    function PrinterStartDoc(const AJobTitle: string): Boolean; override;
    procedure PrinterEndDoc; override;
    procedure PrinterEndPage; override;
    procedure PrinterStartPage; override;
  public
    class function PrintDocument(const ADocument: TPDFDocument; const AJobTitle: string;
      const AShowPrintDialog: Boolean = True; const AAllowPageRange: Boolean = True;
      const AParentWnd: HWND = 0): Boolean; static;
  end;

implementation

uses
  System.Character, System.Generics.Collections, System.Generics.Defaults, System.Types, Vcl.Clipbrd, Vcl.Printers
{$IFDEF ALPHASKINS}
  , sConst, sDialogs, sMessages, sStyleSimply, sVCLUtils
{$ENDIF}
{$IFDEF USE_LOAD_FROM_URL}
  , IdHTTP, IdSSLOpenSSL
{$ENDIF};

var
  GHintWindow: THintWindow;

function GetHintWindow: THintWindow;
begin
  if not Assigned(GHintWindow) then
  begin
    GHintWindow := THintWindow.Create(Application);
    GHintWindow.DoubleBuffered := True;
  end;

  Result := GHintWindow;
end;

{ TPDFPage }

function TPDFPageHelper.Page: FPDF_PAGE;
begin
  with Self do { Trick to get the private property }
  Result := FPage;
end;

{ TPDFiumControl }

constructor TPDFiumControl.Create(AOwner: TComponent);
begin
{$IFDEF ALPHASKINS}
  FSkinData := TsScrollWndData.Create(Self, True);
  FSkinData.COC := COC_TsMemo;
  FSkinData.CustomFont := True;
  StyleElements := [seBorder];
{$ENDIF}

  inherited Create(AOwner);

  ControlStyle := ControlStyle + [csOpaque];
  FZoomMode := zmActualSize;
  FZoomPercent := 100;
  FPageIndex := 0;
  FPageMargin := 6;
  FPrintJobTitle := 'Print PDF';
  FAllowFormFieldEdit := False;
  FAllowTextSelection := True;
  FDrawOptions := CDefaultDrawOptions;

  if not (csDesigning in ComponentState) then
    FPDFDocument := CreatePDFDocument;

  DoubleBuffered := True;
  ParentBackground := False;
  ParentColor := False;
  Color := clWhite;
  FPageBorderColor := TColors.Silver;
  TabStop := True;
  Width := 200;
  Height := 250;

  VertScrollBar.Smooth := True;
  VertScrollBar.Tracking := True;
  HorzScrollBar.Smooth := True;
  HorzScrollBar.Tracking := True;
end;

function TPDFiumControl.CreatePDFDocument: TPDFDocument;
begin
  Result := TPDFDocument.Create;
  Result.OnFormInvalidate := FormInvalidate;
  Result.OnFormFieldFocus := FormFieldFocus;
  Result.OnFormGetCurrentPage := FormGetCurrentPage;
  Result.OnFormOutputSelectedRect := FormOutputSelectedRect;
end;

procedure TPDFiumControl.CreateParams(var AParams: TCreateParams);
begin
  inherited CreateParams(AParams);

  with AParams.WindowClass do
  Style := Style and not (CS_HREDRAW or CS_VREDRAW);
end;

destructor TPDFiumControl.Destroy;
begin
{$IFDEF ALPHASKINS}
  if Assigned(FScrollWnd) then
  begin
    FScrollWnd.Free;
    FScrollWnd := nil;
  end;

  if Assigned(FSkinData) then
  begin
    FSkinData.Free;
    FSkinData := nil;
  end;
{$ENDIF}

  if Assigned(FWebLinksInfo) then
    FreeAndNil(FWebLinksInfo);

  if Assigned(FPDFDocument) then
    FPDFDocument.Free;

  inherited;
end;

{$IFDEF ALPHASKINS}
procedure TPDFiumControl.AfterConstruction;
begin
  inherited AfterConstruction;

  if HandleAllocated then
    RefreshEditScrolls(SkinData, FScrollWnd);

  UpdateData(FSkinData);
end;

procedure TPDFiumControl.Loaded;
begin
  inherited Loaded;

  FSkinData.Loaded(False);
end;

procedure TPDFiumControl.WndProc(var AMessage: TMessage);
var
  LPaintStruct: TPaintStruct;
begin
  if AMessage.Msg = SM_ALPHACMD then
    case AMessage.WParamHi of
      AC_CTRLHANDLED:
        begin
          AMessage.Result := 1;
          Exit;
        end;
      AC_SETNEWSKIN:
        if ACUInt(AMessage.LParam) = ACUInt(SkinData.SkinManager) then
        begin
          CommonMessage(AMessage, FSkinData);
          Exit;
        end;
      AC_REMOVESKIN:
        if ACUInt(AMessage.LParam) = ACUInt(SkinData.SkinManager) then
        begin
          if Assigned(FScrollWnd) then
          begin
            FreeAndNil(FScrollWnd);
            RecreateWnd;
          end;

          Exit;
        end;
      AC_REFRESH:
        if RefreshNeeded(SkinData, AMessage) then
        begin
          RefreshEditScrolls(SkinData, FScrollWnd);
          CommonMessage(AMessage, FSkinData);

          if HandleAllocated and Visible then
            RedrawWindow(Handle, nil, 0, RDWA_REPAINT);

          Exit;
        end;
      AC_GETDEFSECTION:
        begin
          AMessage.Result := 1;
          Exit;
        end;
      AC_GETDEFINDEX:
        begin
          if Assigned(FSkinData.SkinManager) then
            AMessage.Result := FSkinData.SkinManager.SkinCommonInfo.Sections[ssEdit] + 1;

          Exit;
        end;
      AC_SETGLASSMODE:
        begin
          CommonMessage(AMessage, FSkinData);
          Exit;
        end;
    end;

  if not ControlIsReady(Self) or not Assigned(FSkinData) or not FSkinData.Skinned then
    inherited
  else
  begin
    case AMessage.Msg of
      WM_ERASEBKGND:
        if (SkinData.SkinIndex >= 0) and InUpdating(FSkinData) then
          Exit;
      WM_PAINT:
        begin
          if InUpdating(FSkinData) then
          begin
            BeginPaint(Handle, LPaintStruct);
            EndPaint(Handle, LPaintStruct);
          end
          else
            inherited;

          Exit;
        end;
    end;

    if CommonWndProc(AMessage, FSkinData) then
      Exit;

    inherited;

    case AMessage.Msg of
      CM_SHOWINGCHANGED:
        RefreshEditScrolls(SkinData, FScrollWnd);
      CM_VISIBLECHANGED, CM_ENABLEDCHANGED, WM_SETFONT:
        FSkinData.Invalidate;
      CM_TEXTCHANGED, CM_CHANGED:
        if Assigned(FScrollWnd) then
          UpdateScrolls(FScrollWnd, True);
    end;
  end;
end;
{$ENDIF}

procedure TPDFiumControl.WMEraseBkgnd(var AMessage: TWMEraseBkgnd);
begin
  AMessage.Result := 1;
end;

procedure TPDFiumControl.WMGetDlgCode(var AMessage: TWMGetDlgCode);
begin
  inherited;

  AMessage.Result := AMessage.Result or DLGC_WANTARROWS;
end;

function TPDFiumControl.IsCurrentPageValid: Boolean;
begin
  Result := IsPageIndexValid(PageIndex);
end;

function TPDFiumControl.GetCurrentPage: TPDFPage;
begin
  Result := GetPage(PageIndex);
end;

procedure TPDFiumControl.DoScroll(const AScrollBarKind: TScrollBarKind);
begin
  if Assigned(FOnScroll) then
    FOnScroll(Self, AScrollBarKind);
end;

function TPDFiumControl.DoMouseWheel(AShift: TShiftState; AWheelDelta: Integer; AMousePos: TPoint): Boolean;
begin
  FChanged := True;

  VertScrollBar.Position := VertScrollBar.Position - AWheelDelta;
  UpdatePageIndex;
  DoScroll(sbVertical);

  Result := True;
end;

procedure TPDFiumControl.WMHScroll(var AMessage: TWMHScroll);
begin
  FChanged := True;

  inherited;

  DoScroll(sbHorizontal);
  Invalidate;
end;

procedure TPDFiumControl.WMKeyDown(var AMessage: TWMKeyDown);
var
  LShiftState: TShiftState;
begin
  if FAllowFormFieldEdit and IsCurrentPageValid and CurrentPage.FormEventKeyDown(AMessage.CharCode, AMessage.KeyData) then
  begin
    case AMessage.CharCode of
      Ord('C'), Ord('X'), Ord('V'), VK_INSERT, VK_DELETE:
        begin
          LShiftState := KeyDataToShiftState(AMessage.KeyData);

          if LShiftState = [ssCtrl] then
          case AMessage.CharCode of
            Ord('C'), VK_INSERT:
              CopyFormTextToClipboard;
            Ord('X'):
              CutFormTextToClipboard;
            Ord('V'):
              PasteFormTextFromClipboard;
          end
          else
          if LShiftState = [ssShift] then
          case AMessage.CharCode of
            VK_INSERT:
              PasteFormTextFromClipboard;
            VK_DELETE:
              CutFormTextToClipboard;
          end;
        end;
    end;

    Exit;
  end;

  inherited;
end;

procedure TPDFiumControl.WMKeyUp(var AMessage: TWMKeyUp);
begin
  if FAllowFormFieldEdit and IsCurrentPageValid and CurrentPage.FormEventKeyUp(AMessage.CharCode, AMessage.KeyData) then
    Exit;

  inherited;
end;

procedure TPDFiumControl.WMChar(var AMessage: TWMChar);
begin
  if FAllowFormFieldEdit and IsCurrentPageValid and CurrentPage.FormEventKeyPress(AMessage.CharCode, AMessage.KeyData) then
    Exit;

  inherited;
end;

procedure TPDFiumControl.WMKillFocus(var AMessage: TWMKillFocus);
begin
  if FAllowFormFieldEdit and IsCurrentPageValid then
    CurrentPage.FormEventKillFocus;

  inherited;
end;

procedure TPDFiumControl.UpdatePageIndex;
var
  LIndex: Integer;
  LPageIndex: Integer;
  LTop: Integer;
begin
  LTop := Height div 3;
  LPageIndex := FPageCount - 1;

  { Can't use binary search. Page info rect is not always up to date - see AdjustPageInfo. }
  for LIndex := 0 to FPageCount - 1 do
  if FPageInfo[LIndex].Rect.Top >= LTop then
  begin
    LPageIndex := LIndex - 1;
    Break;
  end;

  PageIndex := Max(LPageIndex, 0);
end;

procedure TPDFiumControl.WMVScroll(var AMessage: TWMVScroll);
begin
  FChanged := True;

  inherited;

  UpdatePageIndex;
  DoScroll(sbVertical);

  Invalidate;
end;

procedure TPDFiumControl.LoadFromFile(const AFilename: string);
var
  LPassword: UTF8String;
begin
  FFilename := AFilename;
  try
    FPDFDocument.LoadFromFile(AFilename);
  except
    on E: Exception do
    if FPDF_GetLastError = FPDF_ERR_PASSWORD then
    begin
      LPassword := '';

      if Assigned(FOnLoadProtected) then
        FOnLoadProtected(Self, LPassword);

      try
        FPDFDocument.LoadFromFile(AFilename, LPassword);
      except
        on E: Exception do
          raise;
      end;
    end
    else
      raise;
  end;

  AfterLoad;
end;

procedure TPDFiumControl.LoadFromStream(const AStream: TStream);
var
  LPassword: UTF8String;
begin
  try
    FPDFDocument.LoadFromStream(AStream);
  except
    on E: Exception do
    if FPDF_GetLastError = FPDF_ERR_PASSWORD then
    begin
      LPassword := '';
      if Assigned(FOnLoadProtected) then
        FOnLoadProtected(Self, LPassword);
      try
        FPDFDocument.LoadFromStream(AStream, LPassword);
      except
        on E: Exception do
          raise;
      end;
    end
    else
      raise;
  end;

  AfterLoad;
end;

{$IFDEF USE_LOAD_FROM_URL}
procedure TPDFiumControl.LoadFromURL(const AURL: string);
var
  LStream: TMemoryStream;
  LHTTPClient: TIdHTTP;
begin
  LHTTPClient := TIdHTTP.Create;
  try
    LStream := TMemoryStream.Create;
    try
      LHTTPClient.ReadTimeout := 60000;

      if AURL.StartsWith('https://') then
      begin
        LHTTPClient.IOHandler := TIdSSLIOHandlerSocketOpenSSL.Create(LHTTPClient);
        with TIdSSLIOHandlerSocketOpenSSL(LHTTPClient.IOHandler).SSLOptions do
        begin
          Method := sslvTLSv1_2;
          SSLVersions := SSLVersions + [sslvTLSv1_2];
        end;
        LHTTPClient.Request.BasicAuthentication := True;
      end;

      LHTTPClient.Get(AURL, LStream);
      LStream.Position := 0;
      LoadFromStream(LStream);
    finally
      FreeAndNil(LStream);
    end;
  finally
    LHTTPClient.Free;
  end;
end;
{$ENDIF}

procedure TPDFiumControl.AfterLoad;
begin
  ClearSearch;

  if Assigned(FPDFDocument) then
  begin
    SetPageCount(FPDFDocument.PageCount);
    GetPageWebLinks;
  end;

  FChanged := True;

  Invalidate;
end;

procedure TPDFiumControl.CMGesture(var AMessage: TCMGesture);
begin
  inherited;

  FChanged := True;
  Invalidate;
end;

function TPDFiumControl.ZoomToScreen: Single;
begin
  Result := FZoomPercent / 100 * Screen.PixelsPerInch / 72;
end;

procedure TPDFiumControl.SetPageCount(const AValue: Integer);
var
  LIndex: Integer;
  LPage: TPDFPage;
begin
  FPageCount := AValue;
  FPageIndex := 0;
  FWidth := 0;
  FHeight := 0;

  if FPageCount > 0 then
  begin
    SetLength(FPageInfo, FPageCount);

    for LIndex := 0 to FPageCount - 1 do
    begin
      LPage := FPDFDocument.Pages[LIndex];

      with FPageInfo[LIndex] do
      begin
        Width := LPage.Width;
        Height := LPage.Height;
        Rotation := prNormal;
        SearchCurrentIndex := -1;
      end;

      if LPage.Width > FWidth then
        FWidth := LPage.Width;

      FHeight := FHeight + LPage.Height;
    end;
  end;

  HorzScrollBar.Position := 0;
  VertScrollBar.Position := 0;
  SetScrollSize;
end;

procedure TPDFiumControl.SetPageNumber(const AValue: Integer);
var
  LValue: Integer;
begin
  LValue := AValue - 1;

  if IsPageIndexValid(LValue) and (FPageIndex <> LValue) then
  begin
    FPageIndex := LValue;
    FChanged := True;
    VertScrollBar.Position := GetPageTop(FPageIndex);
    PageChanged;
  end;
end;

procedure TPDFiumControl.SetPageIndex(const AValue: Integer);
begin
  if FPageIndex <> AValue then
  begin
    FPageIndex := AValue;
    PageChanged;

    if Assigned(FOnPageChanged) then
      FOnPageChanged(Self);
  end;
end;

procedure TPDFiumControl.PageChanged;
begin
  FSelectionStartCharIndex := 0;
  FSelectionStopCharIndex := 0;
  FSelectionActive := False;

  GetPageWebLinks;
end;

procedure TPDFiumControl.SetScrollSize;
type
  TScrollInfo = record
    Position: Int64;
    Range: Int64;
  end;

  procedure SetScrollInfo(var AScrollInfo: TScrollInfo; const AScrollBar: TControlScrollBar);
  begin
    AScrollInfo.Position := AScrollBar.Position;
    AScrollInfo.Range := AScrollBar.Range;
  end;

  procedure SetPosition(const AScrollInfo: TScrollInfo; const AScrollBar: TControlScrollBar);
  begin
    if AScrollInfo.Range > 0 then
      AScrollBar.Position := AScrollBar.Range * AScrollInfo.Position div AScrollInfo.Range;
  end;

var
  LZoom: Single;
  LHorzScrollInfo: TScrollInfo;
  LVertScrollInfo: TScrollInfo;
begin
  SetScrollInfo(LHorzScrollInfo, HorzScrollBar);
  SetScrollInfo(LVertScrollInfo, VertScrollBar);

  LZoom := FZoomPercent / 100 * Screen.PixelsPerInch / 72;

  HorzScrollBar.Range := Round(FWidth * LZoom) + FPageMargin * 2;
  VertScrollBar.Range := Round(FHeight * LZoom) + FPageMargin * (FPageCount + 1);

  SetPosition(LHorzScrollInfo, HorzScrollBar);
  SetPosition(LVertScrollInfo, VertScrollBar);
end;

procedure TPDFiumControl.SetSearchHighlightAll(const AValue: Boolean);
begin
  FSearchHighlightAll := AValue;

  Invalidate;
end;

procedure TPDFiumControl.SetZoomPercent(const AValue: Single);
var
  LValue: Single;
begin
  LValue := AValue;

  if LValue < 0.65 then
    LValue := 0.65
  else
  if LValue > 6400 then
    LValue := 6400;

  FZoomPercent := LValue;
  SetScrollSize;
  DoSizeChanged;
end;

procedure TPDFiumControl.Zoom(const APercent: Single);
begin
  FZoomMode := zmPercent;
  SetZoomPercent(APercent);
end;

procedure TPDFiumControl.DoSizeChanged;
begin
  FChanged := True;
  Invalidate;

  if Assigned(OnResize) then
    OnResize(Self);
end;

procedure TPDFiumControl.SetZoomMode(const AValue: TPDFZoomMode);
begin
  FZoomMode := AValue;
  AdjustZoom;
end;

procedure TPDFiumControl.AdjustZoom;
begin
  case FZoomMode of
    zmPercent:
      Exit;
    zmActualSize:
      SetZoomPercent(100);
    zmFitHeight:
      SetZoomPercent(PageHeightZoomPercent);
    zmFitWidth:
      SetZoomPercent(PageWidthZoomPercent);
  end;
end;

procedure TPDFiumControl.ClearSelection;
begin
  SetSelection(False, 0, 0);
end;

function TPDFiumControl.SearchAll: Integer;
begin
  Result := SearchAll(FSearchText, FSearchHighlightAll, FSearchMatchCase, FSearchWholeWords);
end;

function TPDFiumControl.SearchAll(const ASearchText: string): Integer;
begin
  Result := SearchAll(ASearchText, FSearchHighlightAll, FSearchMatchCase, FSearchWholeWords);
end;

procedure TPDFiumControl.AdjustScrollBar(const APageIndex: Integer);
var
  LRect: TRect;
  LPageRect: TRect;
begin
  with FPageInfo[APageIndex] do
  begin
    LPageRect := System.Types.Rect(0, 0, Round(Width), Round(Height));
    LRect := InternPageToDevice(FPDFDocument.Pages[APageIndex], SearchRects[SearchCurrentIndex], LPageRect);
    VertScrollBar.Position := GetPageTop(APageIndex) + Round( (VertScrollBar.Range / PageCount) *
      LRect.Top / LPageRect.Height ) - 2 * LRect.Height;
  end;

  FChanged := True;
end;

function TPDFiumControl.SearchAll(const ASearchText: string; const AHighlightAll: Boolean; const AMatchCase: Boolean;
  const AWholeWords: Boolean; const AScrollIntoView: Boolean = True; const APageIndex: Integer = -1): Integer;
var
  LCount, LRectCount: Integer;
  LCharIndex, LCharCount: Integer;
  LIndex, LPageIndex: Integer;
  LPage: TPDFPage;
  LSearchText: string;
  LFromPage, LToPage: Integer;
begin
  Result := 0;

  FSearchText := ASearchText;
  FSearchHighlightAll := AHighlightAll;
  FSearchMatchCase := AMatchCase;
  FSearchWholeWords := AWholeWords;

  ClearSearch;
  FSearchIndex := 0;

  if IsCurrentPageValid then
  begin
    LFromPage := IfThen(APageIndex = -1, 0, APageIndex);
    LToPage := IfThen(APageIndex = -1, FPageCount - 1, APageIndex);

    for LPageIndex := LFromPage to LToPage do
    with FPageInfo[LPageIndex] do
    begin
      LPage := FPDFDocument.Pages[LPageIndex];

      LCount := 0;

      if not FSearchText.IsEmpty then
      begin
        LSearchText := FSearchText;

        if not FSearchMatchCase then
          LSearchText := LSearchText.ToLower; { Bug in PDFium }

        if LPage.BeginFind(LSearchText, FSearchMatchCase, FSearchWholeWords, False) then
        try
          while LPage.FindNext(LCharIndex, LCharCount) do
          begin
            LRectCount := LPage.GetTextRectCount(LCharIndex, LCharCount);

            if LCount + LRectCount > Length(SearchRects) then
              SetLength(SearchRects, (LCount + LRectCount) * 2);

            for LIndex := 0 to LRectCount - 1 do
            begin
              SearchRects[LCount] := LPage.GetTextRect(LIndex);
              Inc(LCount);
            end;

            Inc(Result);
          end;
        finally
          LPage.EndFind;
        end;

        if LCount <> Length(SearchRects) then
          SetLength(SearchRects, LCount);

        if Length(SearchRects) > 0 then
          TArray.Sort<TPDFRect>(SearchRects, TComparer<TPDFRect>.Construct(
            function (const ALeft, ARight: TPDFRect): Integer
            begin
              Result := Trunc(ARight.Top) - Trunc(ALeft.Top);

              if Result = 0 then
                Result := Trunc(ALeft.Left) - Trunc(ARight.Left);
            end)
          );
      end;
    end;

    for LPageIndex := LFromPage to LToPage do
    with FPageInfo[LPageIndex] do
    if Length(SearchRects) > 0 then
    begin
      SearchCurrentIndex := 0;

      if AScrollIntoView then
      begin
        GotoPage(LPageIndex, False);
        AdjustScrollBar(LPageIndex);
      end;

      Break;
    end;
  end;

  FSearchCount := Result;

  Invalidate;
end;

function TPDFiumControl.GetPage(const AIndex: Integer): TPDFPage;
begin
  if IsPageIndexValid(AIndex) then
    Result := FPDFDocument.Pages[AIndex]
  else
    Result := nil;
end;

function TPDFiumControl.FindNext: Integer;
var
  LPageIndex: Integer;
  LNextPage: Boolean;
begin
  Result := FSearchIndex;

  if FSearchIndex + 1 >= FSearchCount then
    Exit;

  Inc(FSearchIndex);

  LNextPage := False;

  for LPageIndex := 0 to FPageCount - 1 do
  with FPageInfo[LPageIndex] do
  begin
    if LNextPage and (Length(SearchRects) > 0) then
    begin
      SearchCurrentIndex := 0;
      Break;
    end
    else
    if SearchCurrentIndex <> -1 then
    begin
      if SearchCurrentIndex + 1 < Length(SearchRects) then
      begin
        Inc(SearchCurrentIndex);
        Break;
      end
      else
      begin
        SearchCurrentIndex := -1;
        LNextPage := True;
      end;
    end;
  end;

  GotoPage(LPageIndex, False);
  AdjustScrollBar(LPageIndex);

  Result := FSearchIndex;

  Invalidate;
end;

function TPDFiumControl.FindPrevious: Integer;
var
  LPageIndex: Integer;
  LPreviousPage: Boolean;
begin
  Result := FSearchIndex;

  if FSearchIndex - 1 < 0 then
    Exit;

  Dec(FSearchIndex);

  LPreviousPage := False;

  for LPageIndex := FPageCount - 1 downto 0 do
  with FPageInfo[LPageIndex] do
  begin
    if LPreviousPage and (Length(SearchRects) > 0) then
    begin
      SearchCurrentIndex := Length(SearchRects) - 1;
      Break;
    end
    else
    if SearchCurrentIndex <> -1 then
    begin
      if SearchCurrentIndex - 1 >= 0 then
      begin
        Dec(SearchCurrentIndex);
        Break;
      end
      else
      begin
        SearchCurrentIndex := -1;
        LPreviousPage := True;
      end;
    end;
  end;

  GotoPage(LPageIndex, False);
  AdjustScrollBar(LPageIndex);

  Result := FSearchIndex;

  Invalidate;
end;

procedure TPDFiumControl.ClearSearch;
var
  LIndex: Integer;
begin
  SearchCount := 0;
  SearchIndex := 0;

  if IsCurrentPageValid then
  for LIndex := 0 to FPageCount - 1 do
  begin
    SetLength(FPageInfo[LIndex].SearchRects, 0);
    FPageInfo[LIndex].SearchCurrentIndex := -1;
  end;
end;

procedure TPDFiumControl.SaveToFile(const AFilename: string; const AOption: TPdfDocumentSaveOption = dsoRemoveSecurity; const AFileVersion: Integer = -1);
begin
  FPDFDocument.SaveToFile(AFilename, AOption, AFileVersion);
end;

procedure TPDFiumControl.SaveToStream(const AStream: TStream; const AOption: TPdfDocumentSaveOption = dsoRemoveSecurity; const AFileVersion: Integer = -1);
begin
  FPDFDocument.SaveToStream(AStream, AOption, AFileVersion);
end;

procedure TPDFiumControl.SelectAll;
begin
  SelectText(0, -1);
end;

procedure TPDFiumControl.SelectAllFormText;
begin
  if FFormFieldFocused and IsCurrentPageValid then
    CurrentPage.FormSelectAllText;
end;

procedure TPDFiumControl.SelectText(const ACharIndex: Integer; const ACount: Integer);
begin
  if (ACount = 0) or not IsCurrentPageValid then
    ClearSelection
  else
  begin
    if ACount = -1 then
      SetSelection(True, 0, CurrentPage.GetCharCount - 1)
    else
      SetSelection(True, ACharIndex, Min(ACharIndex + ACount - 1, CurrentPage.GetCharCount - 1));
  end;
end;

procedure TPDFiumControl.CloseDocument;
begin
  FPDFDocument.Close;
  SetPageCount(0);
  FFormFieldFocused := False;
  Invalidate;
end;

procedure TPDFiumControl.CopyFormTextToClipboard;
var
  LText: string;
begin
  if FFormFieldFocused and IsCurrentPageValid then
  begin
    LText := CurrentPage.FormGetSelectedText;
    if not LText.IsEmpty then
      Clipboard.AsText := LText;
  end;
end;

procedure TPDFiumControl.CutFormTextToClipboard;
begin
  if FFormFieldFocused and IsCurrentPageValid then
  begin
    CopyFormTextToClipboard;
    CurrentPage.FormReplaceSelection('');
  end;
end;
procedure TPDFiumControl.PasteFormTextFromClipboard;
begin
  if FFormFieldFocused and IsCurrentPageValid then
  begin
    Clipboard.Open;
    try
      if Clipboard.HasFormat(CF_UNICODETEXT) or Clipboard.HasFormat(CF_TEXT) then
        CurrentPage.FormReplaceSelection(Clipboard.AsText);
    finally
      Clipboard.Close;
    end;
  end;
end;

procedure TPDFiumControl.CopyToClipboard;
begin
  Clipboard.AsText := GetSelectionText;
end;

function TPDFiumControl.GetPageNumber: Integer;
begin
  Result := FPageIndex + 1;
end;

function TPDFiumControl.PageToScreen(const AValue: Single): Integer;
begin
  Result := Round(AValue * ZoomToScreen);
end;

function TPDFiumControl.GetPageTop(const APageIndex: Integer): Integer;
var
  LY: Double;
  LPageIndex: Integer;
begin
  LPageIndex := APageIndex;
  LY := 0;

  Result := LPageIndex * FPageMargin;

  while LPageIndex > 0 do
  begin
    Dec(LPageIndex);
    LY := LY + FPageInfo[LPageIndex].Height;
  end;

  Inc(Result, PageToScreen(LY));
end;

procedure TPDFiumControl.GotoPage(const AIndex: Integer; const ASetScrollBar: Boolean = True);
begin
  if FPageIndex = AIndex then
    Exit;

  if IsPageIndexValid(AIndex) then
  begin
    PageIndex := AIndex;
    FChanged := True;

    if ASetScrollBar then
      VertScrollBar.Position := GetPageTop(AIndex);

    DoScroll(sbVertical);
  end;
end;

procedure TPDFiumControl.AdjustPageInfo;
var
  LIndex: Integer;
  LTop: Double;
  LScale: Double;
  LClient: TRect;
  LRect: TRect;
  LMargin: Integer;
begin
  for LIndex := 0 to FPageCount - 1 do
    FPageInfo[LIndex].Visible := 0;

  LClient := ClientRect;
  LTop := 0;
  LMargin := FPageMargin;
  LScale := FZoomPercent / 100 * Screen.PixelsPerInch / 72;

  for LIndex := 0 to FPageCount - 1 do
  begin
    LRect.Top := Round(LTop * LScale) + LMargin - VertScrollBar.Position;
    LRect.Left := FPageMargin + Round((FWidth - FPageInfo[LIndex].Width) / 2 * LScale) - HorzScrollBar.Position;
    LRect.Width := Round(FPageInfo[LIndex].Width * LScale);
    LRect.Height := Round(FPageInfo[LIndex].Height * LScale);

    if LRect.Width < LClient.Width - 2 * FPageMargin then
      LRect.Offset((LClient.Width - LRect.Width) div 2 - LRect.Left, 0);

    FPageInfo[LIndex].Rect := LRect;

    if LRect.IntersectsWith(LClient) then
      FPageInfo[LIndex].Visible := 1;

    if LRect.Top > LClient.Bottom then
      Break;

    LTop := LTop + FPageInfo[LIndex].Height;
    Inc(LMargin, FPageMargin);
  end;
end;

function TPDFiumControl.GetSelectionText: string;
begin
  if FSelectionActive and IsCurrentPageValid then
    Result := CurrentPage.ReadText(SelectionStart, SelectionLength)
  else
    Result := '';
end;

function TPDFiumControl.GetSelectionLength: Integer;
begin
  if FSelectionActive and IsCurrentPageValid then
    Result := Abs(FSelectionStartCharIndex - FSelectionStopCharIndex) + 1
  else
    Result := 0;
end;

function TPDFiumControl.GetSelectionStart: Integer;
begin
  if FSelectionActive and IsCurrentPageValid then
    Result := Min(FSelectionStartCharIndex, FSelectionStopCharIndex)
  else
    Result := 0;
end;

function TPDFiumControl.GetSelectionRects: TPDFControlRectArray;
var
  LCount: Integer;
  LIndex: Integer;
  LPage: TPDFPage;
begin
  if FSelectionActive and HandleAllocated then
  begin
    LPage := CurrentPage;

    if Assigned(LPage) then
    begin
      LCount := CurrentPage.GetTextRectCount(SelectionStart, SelectionLength);
      SetLength(Result, LCount);

      for LIndex := 0 to LCount - 1 do
        Result[LIndex] := InternPageToDevice(LPage, LPage.GetTextRect(LIndex), FPageInfo[FPageIndex].Rect);

      Exit;
    end;
  end;

  Result := nil;
end;

procedure TPDFiumControl.InvalidateRectDiffs(const AOldRects, ANewRects: TPDFControlRectArray);

  function ContainsRect(const Rects: TPDFControlRectArray; const ARect: TRect): Boolean;
  var
    LIndex: Integer;
  begin
    Result := True;

    for LIndex := 0 to Length(Rects) - 1 do
    if EqualRect(Rects[LIndex], ARect) then
      Exit;

    Result := False;
  end;

var
  LIndex: Integer;
begin
  if HandleAllocated then
  begin
    for LIndex := 0 to Length(AOldRects) - 1 do
    if not ContainsRect(ANewRects, AOldRects[LIndex]) then
      InvalidateRect(Handle, @AOldRects[LIndex], True);

    for LIndex := 0 to Length(ANewRects) - 1 do
    if not ContainsRect(AOldRects, ANewRects[LIndex]) then
      InvalidateRect(Handle, @ANewRects[LIndex], True);
  end;
end;

procedure TPDFiumControl.SetSelection(const AActive: Boolean; const AStartIndex, AStopIndex: Integer);
var
  LOldRects, LNewRects: TPDFControlRectArray;
begin
  if (AActive <> FSelectionActive) or (AStartIndex <> FSelectionStartCharIndex) or (AStopIndex <> FSelectionStopCharIndex) then
  begin
    LOldRects := GetSelectionRects;

    FSelectionStartCharIndex := AStartIndex;
    FSelectionStopCharIndex := AStopIndex;
    FSelectionActive := AActive and (FSelectionStartCharIndex >= 0) and (FSelectionStopCharIndex >= 0);

    LNewRects := GetSelectionRects;

    InvalidateRectDiffs(LOldRects, LNewRects);
  end;
end;

function TPDFiumControl.SelectWord(const ACharIndex: Integer): Boolean;
var
  LChar: Char;
  LStartCharIndex, LStopCharIndex, LCharCount: Integer;
  LPage: TPDFPage;
  LCharIndex: Integer;
begin
  Result := False;

  LPage := CurrentPage;
  if Assigned(LPage) then
  begin
    ClearSelection;
    LCharCount := LPage.GetCharCount;
    LCharIndex := ACharIndex;

    if (LCharIndex >= 0) and (LCharIndex < LCharCount) then
    begin
      while (LCharIndex < LCharCount) and CurrentPage.ReadChar(LCharIndex).IsWhiteSpace do
        Inc(LCharIndex);

      if LCharIndex < LCharCount then
      begin
        LStartCharIndex := LCharIndex - 1;

        while LStartCharIndex >= 0 do
        begin
          LChar := CurrentPage.ReadChar(LStartCharIndex);

          if LChar.IsWhiteSpace then
            Break;

          Dec(LStartCharIndex);
        end;

        Inc(LStartCharIndex);

        LStopCharIndex := LCharIndex + 1;
        while LStopCharIndex < LCharCount do
        begin
          LChar := CurrentPage.ReadChar(LStopCharIndex);

          if LChar.IsWhiteSpace then
            Break;

          Inc(LStopCharIndex);
        end;

        Dec(LStopCharIndex);

        SetSelection(True, LStartCharIndex, LStopCharIndex);
        Result := True;
      end;
    end;
  end;
end;

procedure TPDFiumControl.MouseDown(AButton: TMouseButton; AShift: TShiftState; X, Y: Integer);
var
  LPoint: TPDFPoint;
  LCharIndex: Integer;
  LPage: TPdfPage;
begin
  inherited MouseDown(AButton, AShift, X, Y);

  if AButton = mbLeft then
  begin
    SetFocus;

    FMousePressed := True;
    FMouseDownPoint := Point(X, Y); // used to find out if the selection must be cleared or not
  end;

  if IsCurrentPageValid then
  begin
    LPage := CurrentPage;

    if FAllowFormFieldEdit then
    begin
      LPoint := DeviceToPage(X, Y);
      if AButton = mbLeft then
      begin
        if LPage.FormEventLButtonDown(AShift, LPoint.X, LPoint.Y) then
          Exit;
      end
      else
      if AButton = mbRight then
      begin
        if LPage.FormEventFocus(AShift, LPoint.X, LPoint.Y) then
          Exit;

        if LPage.FormEventRButtonDown(AShift, LPoint.X, LPoint.Y) then
          Exit;
      end;
    end;

    if AllowTextSelection and not FFormFieldFocused and (AButton = mbLeft) then
    begin
      LPoint := DeviceToPage(X, Y);
      LCharIndex := LPage.GetCharIndexAt(LPoint.X, LPoint.Y, MAXWORD, MAXWORD);

      if ssDouble in AShift then
      begin
        FMousePressed := False;
        SelectWord(LCharIndex);
      end
      else
        SetSelection(False, LCharIndex, LCharIndex);
    end;
  end;
end;

function TPDFiumControl.GetPageIndexAt(const APoint: TPoint): Integer;
var
  LIndex: Integer;
begin
  Result := FPageIndex;

  if APoint.Y > 5 then
  for LIndex := 0 to FPageCount - 1 do
  if FPageInfo[LIndex].Rect.Contains(APoint) then
    Exit(LIndex);
end;

procedure TPDFiumControl.MouseMove(AShift: TShiftState; X, Y: Integer);
var
  LPoint: TPDFPoint;
  LPage: TPdfPage;
  LCursor: TCursor;
  LPageIndex: Integer;
  LURL: string;
  LRect: TRect;
begin
  inherited MouseMove(AShift, X, Y);

  if not Assigned(FPDFDocument) or not FPDFDocument.Active then
    Exit;

  LPageIndex := GetPageIndexAt(Point(X, Y));

  if LPageIndex <> FPageIndex then
    PageIndex := LPageIndex;

  LCursor := Cursor;
  try
    if FAllowFormFieldEdit and IsCurrentPageValid then
    begin
      LPoint := DeviceToPage(X, Y);
      LPage := CurrentPage;

      if LPage.FormEventMouseMove(AShift, LPoint.X, LPoint.Y) then
      case LPage.HasFormFieldAtPoint(LPoint.X, LPoint.Y) of
        fftTextField:
          LCursor := crIBeam;
        fftComboBox, fftSignature:
          LCursor := crHandPoint;
      else
        LCursor := crDefault;
      end;
    end;

    if AllowTextSelection and not FFormFieldFocused then
    begin
      if FMousePressed then
      begin
        if SetSelStopCharIndex(X, Y) then
          if LCursor <> crIBeam then
          begin
            LCursor := crIBeam;
            Cursor := LCursor;
            SetCursor(Screen.Cursors[Cursor]); { Show the mouse cursor change immediately }
          end;
      end
      else
      if IsCurrentPageValid then
      begin
        LPoint := DeviceToPage(X, Y);

        if Assigned(FOnClickLink) and IsWebLinkAt(X, Y) then
          LCursor := crHandPoint
        else
        if Assigned(FOnClickLink) and IsAnnotationLinkAt(X, Y, LURL, LRect) then
        begin
          LCursor := crHandPoint;
          ShowHint(LURL, LRect);
        end
        else
        if CurrentPage.GetCharIndexAt(LPoint.X, LPoint.Y, 5, 5) >= 0 then
          LCursor := crIBeam
        else
        if Cursor <> crDefault then
        begin
          LCursor := crDefault;
          HideHint;
        end;
      end;
    end;
  finally
    if LCursor <> Cursor then
      Cursor := LCursor;
  end;
end;

procedure TPDFiumControl.MouseUp(AButton: TMouseButton; AShift: TShiftState; X, Y: Integer);
var
  LPage: TPdfPage;
  LPoint: TPDFPoint;
  LURL: string;
  LRect: TRect;
begin
  inherited MouseUp(AButton, AShift, X, Y);

  if FAllowFormFieldEdit and IsCurrentPageValid then
  begin
    LPoint := DeviceToPage(X, Y);
    LPage := CurrentPage;

    if (AButton = mbLeft) and LPage.FormEventLButtonUp(AShift, LPoint.X, LPoint.Y) then
    begin
      if FMousePressed and (AButton = mbLeft) then
        FMousePressed := False;

      Exit;
    end;

    if (AButton = mbRight) and LPage.FormEventRButtonUp(AShift, LPoint.X, LPoint.Y) then
      Exit;
  end;

  if FMousePressed and (AButton = mbLeft) then
  begin
    FMousePressed := False;

    if AllowTextSelection and not FFormFieldFocused then
      SetSelStopCharIndex(X, Y);

    if not FSelectionActive then
      if Assigned(FOnClickLink) then
      begin
        if IsAnnotationLinkAt(X, Y, LURL, LRect) then
          FOnClickLink(Self, LURL)
        else
        if IsWebLinkAt(X, Y, LURL) then
          FOnClickLink(Self, LURL);
      end;
  end;
end;

function TPDFiumControl.DeviceToPage(const X, Y: Integer): TPDFPoint;
var
  LPage: TPDFPage;
begin
  LPage := CurrentPage;

  if Assigned(LPage) then
  with FPageInfo[FPageIndex] do
    Result := LPage.DeviceToPage(Rect.Left, Rect.Top, Rect.Width, Rect.Height, X, Y, Rotation)
  else
    Result := TPDFPoint.Empty;
end;

procedure TPDFiumControl.GetPageWebLinks;
var
  LPage: TPDFPage;
begin
  if Assigned(FWebLinksInfo) then
    FreeAndNil(FWebLinksInfo);

  LPage := CurrentPage;

  if Assigned(LPage) then
    FWebLinksInfo := TPdfPageWebLinksInfo.Create(LPage);
end;

function TPDFiumControl.IsWebLinkAt(const X, Y: Integer): Boolean;
var
  LPoint: TPdfPoint;
begin
  if Assigned(FWebLinksInfo) then
  begin
    LPoint := DeviceToPage(X, Y);
    Result := FWebLinksInfo.IsWebLinkAt(LPoint.X, LPoint.Y);
  end
  else
    Result := False;
end;

{ Note! There is an issue with multiline URLs in PDF - PDFium.dll returns the url using a hyphen as a word wrap separator.
  The hyphen is a valid character in the url, so it can't just be removed. }
function TPDFiumControl.IsWebLinkAt(const X, Y: Integer; var AURL: string): Boolean;
var
  LPoint: TPDFPoint;
begin
  AURL := '';

  if Assigned(CurrentPage) and Assigned(FWebLinksInfo) then
  begin
    LPoint := DeviceToPage(X, Y);
    Result := FWebLinksInfo.IsWebLinkAt(LPoint.X, LPoint.Y, AURL);
  end
  else
    Result := False;
end;

function TPDFiumControl.IsAnnotationLinkAt(const X, Y: Integer; var AURL: string; out ALinkRect: TRect): Boolean;
var
  LPage: TPDFPage;
  LPoint: TPdfPoint;
  LAnnotation: TPdfAnnotation;
begin
  LPage := CurrentPage;

  Result := False;

  if Assigned(LPage) then
  begin
    LPoint := DeviceToPage(X, Y);
    LAnnotation := LPage.GetLinkAtPoint(LPoint.X, LPoint.Y);

    if Assigned(LAnnotation) then
    begin
      AURL := LAnnotation.LinkUri;
      ALinkRect := InternPageToDevice(LPage, LAnnotation.AnnotationRect, FPageInfo[FPageIndex].Rect);
    end
    else
      Exit;
  end
  else
    Exit;

  Result := True;
end;

procedure TPDFiumControl.ShowHint(const AHint: string; const ARect: TRect);
var
  LHintWindow: THintWindow;
  LRect: TRect;
  LPoint: TPoint;
begin
  LHintWindow := GetHintWindow;
  LRect := LHintWindow.CalcHintRect(200, AHint, nil);
  LPoint := ClientToScreen(Point(ARect.Left, ARect.Bottom));
  OffsetRect(LRect, LPoint.X, LPoint.Y);
  LHintWindow.ActivateHint(LRect, AHint);
  LHintWindow.Update;
end;

procedure TPDFiumControl.HideHint;
begin
  if Assigned(GHintWindow) then
    ShowWindow(GHintWindow.Handle, SW_HIDE);
end;

procedure TPDFiumControl.GotoNextPage;
begin
  GotoPage(FPageIndex + 1);
end;

procedure TPDFiumControl.WMPaint(var AMessage: TWMPaint);
begin
  ControlState := ControlState + [csCustomPaint];

  inherited;

  ControlState := ControlState - [csCustomPaint];
end;

function TPDFiumControl.PageHeightZoomPercent: Single;
var
  LScale: Single;
  LZoom1, LZoom2: Single;
begin
  if not IsPageIndexValid(FPageIndex) then
    Exit(100);

  LScale := 72 / Screen.PixelsPerInch;
  LZoom1 := (ClientWidth - 2 * FPageMargin) * LScale / FPageInfo[FPageIndex].Width;
  LZoom2 := (ClientHeight - 2 * FPageMargin) * LScale / FPageInfo[FPageIndex].Height;

  if LZoom1 > LZoom2 then
    LZoom1 := LZoom2;

  Result := 100 * LZoom1;
end;

function TPDFiumControl.PageWidthZoomPercent: Single;
var
  LScale: Single;
begin
  if not IsPageIndexValid(FPageIndex) then
    Exit(100);

  LScale := 72 / Screen.PixelsPerInch;
  Result := 100 * (ClientWidth - 2 * FPageMargin) * LScale / Max(FWidth, 1);
end;

function TPDFiumControl.SetSelStopCharIndex(const X, Y: Integer): Boolean;
var
  LPoint: TPDFPoint;
  LCharIndex: Integer;
  LActive: Boolean;
  LRect: TRect;
begin
  if not Assigned(CurrentPage) then
    Exit(False);

  LPoint := DeviceToPage(X, Y);
  LCharIndex := CurrentPage.GetCharIndexAt(LPoint.X, LPoint.Y, MAXWORD, MAXWORD);

  Result := LCharIndex >= 0;

  if not Result then
    LCharIndex := FSelectionStopCharIndex;

  if FSelectionStartCharIndex <> LCharIndex then
    LActive := True
  else
  begin
    LRect := InternPageToDevice(CurrentPage, CurrentPage.GetCharBox(FSelectionStartCharIndex), FPageInfo[FPageIndex].Rect);
    LActive := PtInRect(LRect, FMouseDownPoint) xor PtInRect(LRect, Point(X, Y));
  end;

  SetSelection(LActive, FSelectionStartCharIndex, LCharIndex);
end;

procedure TPDFiumControl.SetFocus;
begin
  if CanFocus then
  begin
    Winapi.Windows.SetFocus(Handle);

    inherited;
  end;
end;

procedure TPDFiumControl.PaintWindow(ADC: HDC);
var
  LIndex: Integer;
  LPage: TPDFPage;
  LBrush: HBrush;
begin
  LBrush := CreateSolidBrush(Color);
  try
    FillRect(ADC, ClientRect, LBrush);

    if not Assigned(FPDFDocument) or (FPageCount = 0) then
      Exit;

    if FChanged or (FPageCount = 0) then
    begin
      AdjustPageInfo;
      FChanged := False;
    end;

    for LIndex := 0 to FPageCount - 1 do
    with FPageInfo[LIndex] do
    if Visible > 0 then
    begin
      LPage := FPDFDocument.Pages[LIndex];

      FillRect(ADC, Rect, LBrush);
      PaintPage(ADC, LPage, LIndex);

      { Selections are drawn only to selected page without rotation. }
      if (LIndex = FPageIndex) and (Rotation = prNormal) then
      begin
        if FSelectionActive then
          PaintPageSelection(ADC, LPage, LIndex);
        PaintAlphaSelection(ADC, LPage, FFormOutputSelectedRects, LIndex);
      end;

      PaintPageSearchResults(ADC, LPage, LIndex);

{$IFDEF ALPHASKINS}
      if IsLightStyleColor(Color) then
{$ENDIF}
        PaintPageBorder(ADC, Rect);
    end;

    if Assigned(FOnPaint) then
      FOnPaint(Self);
  finally
    DeleteObject(LBrush);
  end;
end;

procedure TPDFiumControl.PaintPage(ADC: HDC; const APage: TPDFPage; const AIndex: Integer);
var
  LRect: TRect;
  LPoint: TPoint;
begin
  with FPageInfo[AIndex] do
  if (Rect.Left <> 0) or (Rect.Top <> 0) then
  begin
    LRect := TRect.Create(0, 0, Rect.Width, Rect.Height);
    SetViewportOrgEx(ADC, Rect.Left, Rect.Top, @LPoint);
    APage.Draw(ADC, LRect.Left, LRect.Top, LRect.Width, LRect.Height, Rotation, FDrawOptions);
    SetViewportOrgEx(ADC, LPoint.X, LPoint.Y, nil);
  end
  else
    FPDF_RenderPage(ADC, APage.Handle, Rect.Left, Rect.Top, Rect.Width, Rect.Height, Ord(Rotation), 0);
end;

procedure TPDFiumControl.PaintPageSelection(ADC: HDC; const APage: TPDFPage; const AIndex: Integer);
var
  LCount: Integer;
  LIndex: Integer;
  LRects: TPDFControlPDFRectArray;
begin
  LCount := APage.GetTextRectCount(SelectionStart, SelectionLength);

  if LCount > 0 then
  begin
    SetLength(LRects, LCount);

    for LIndex := 0 to LCount - 1 do
      LRects[LIndex] := APage.GetTextRect(LIndex);

    PaintAlphaSelection(ADC, APage, LRects, AIndex);
  end;
end;

procedure TPDFiumControl.PaintPage(ADC: HDC; const ARect: TRect; const AIndex: Integer);
var
  LPage: TPDFPage;
begin
  if FPDFDocument.Active and (AIndex < FPDFDocument.PageCount) then
  begin
    LPage := FPDFDocument.Pages[AIndex];
    LPage.Draw(ADC, ARect.Left, ARect.Top, ARect.Width, ARect.Height, FPageInfo[AIndex].Rotation, FDrawOptions);
  end;
end;

procedure TPDFiumControl.PaintPageSearchResults(ADC: HDC; const APage: TPDFPage; const AIndex: Integer);
begin
  if Length(FPageInfo[AIndex].SearchRects) > 0 then
    PaintAlphaSelection(ADC, APage, FPageInfo[AIndex].SearchRects, AIndex, RGB(204, 224, 204));
end;

function TPDFiumControl.InternPageToDevice(const APage: TPDFPage; const APageRect: TPDFRect; const ARect: TRect): TRect;
begin
  Result := APage.PageToDevice(ARect.Left, ARect.Top, ARect.Width, ARect.Height, APageRect, APage.Rotation);
end;

procedure TPDFiumControl.PaintAlphaSelection(ADC: HDC; const APage: TPDFPage; const ARects: TPDFControlPDFRectArray;
  const AIndex: Integer; const AColor: TColor = TColors.SysNone);
var
  LCount: Integer;
  LIndex: Integer;
  LRect: TRect;
  LDC: HDC;
  LBitmap: TBitmap;
  LBlendFunction: TBlendFunction;
  LSearchColors: Boolean;

  function SetBrushColor: Boolean;
  var
    LColor: TColor;
  begin
    Result := True;

    LColor := AColor;

    if not LSearchColors then
      LColor := RGB(204, 204, 255)
    else
    if FPageInfo[AIndex].SearchCurrentIndex = LIndex then
      LColor := RGB(240, 204, 238)
    else
    if not FSearchHighlightAll then
      Result := False;

    if Result and (LColor <> LBitmap.Canvas.Brush.Color) then
    begin
      LBitmap.Canvas.Brush.Color := LColor;
      LBitmap.SetSize(100, 0);
      LBitmap.SetSize(100, 50);
      LDC := LBitmap.Canvas.Handle;
    end;
  end;
begin
  LCount := Length(ARects);

  if LCount > 0 then
  begin
    LBitmap := TBitmap.Create;
    try
      LSearchColors := AColor <> TColors.SysNone;

      LBlendFunction.BlendOp := AC_SRC_OVER;
      LBlendFunction.BlendFlags := 0;
      LBlendFunction.SourceConstantAlpha := 128;
      LBlendFunction.AlphaFormat := 0;

      for LIndex := 0 to LCount - 1 do
      begin
        if not SetBrushColor then
          Continue;

        LRect := InternPageToDevice(APage, ARects[LIndex], FPageInfo[AIndex].Rect);

        if RectVisible(ADC, LRect) then
          AlphaBlend(ADC, LRect.Left, LRect.Top, LRect.Width, LRect.Height, LDC, 0, 0, LBitmap.Width, LBitmap.Height,
            LBlendFunction);
      end;
    finally
      LBitmap.Free;
    end;
  end;
end;

procedure TPDFiumControl.PaintPageBorder(ADC: HDC; const ARect: TRect);
var
  LPen: HPen;
begin
  LPen := CreatePen(PS_SOLID, 1, FPageBorderColor);
  try
    SelectObject(ADC, LPen);
    MoveToEx(ADC, ARect.Left, ARect.Top, nil);
    LineTo(ADC, ARect.Left + ARect.Width - 1, ARect.Top);
    LineTo(ADC, ARect.Left + ARect.Width - 1, ARect.Top + ARect.Height - 1);
    LineTo(ADC, ARect.Left, ARect.Top + ARect.Height - 1);
    LineTo(ADC, ARect.Left, ARect.top);
  finally
    DeleteObject(LPen);
  end;
end;

procedure TPDFiumControl.GotoPreviousPage;
begin
  GotoPage(FPageIndex - 1);
end;

procedure TPDFiumControl.Print;
begin
  try
    TPDFDocumentVclPrinter.PrintDocument(FPDFDocument, PrintJobTitle);
  except
    on E: Exception do
      ShowError(E.Message);
  end;
end;

procedure TPDFiumControl.Resize;
begin
  inherited;

  AdjustZoom;
  FChanged := True;
  Invalidate;
end;

function TPDFiumControl.IsPageIndexValid(const APageIndex: Integer): Boolean;
begin
  Result := FPDFDocument.Active and (APageIndex >= 0) and (APageIndex < FPageCount);
end;

function TPDFiumControl.IsTextSelected: Boolean;
begin
  Result := SelectionLength <> 0;
end;

procedure TPDFiumControl.RotatePageClockwise;
var
  LPage: TPDFPage;
begin
  if FPageIndex = -1 then
    Exit;

  LPage := FPDFDocument.Pages[FPageIndex];

  with FPageInfo[FPageIndex] do
  begin
    Inc(Rotation);

    if Ord(Rotation) > Ord(pr90CounterClockwide) then
      Rotation := prNormal;

    if Rotation in [prNormal, pr180] then
    begin
      Height := LPage.Height;
      Width := LPage.Width;
    end
    else
    begin
      Height := LPage.Width;
      Width := LPage.Height;
    end;
  end;

  DoSizeChanged;
end;

procedure TPDFiumControl.RotatePageCounterClockwise;
var
  LPage: TPDFPage;
begin
  if FPageIndex = -1 then
    Exit;

  LPage := FPDFDocument.Pages[FPageIndex];

  with FPageInfo[FPageIndex] do
  begin
    Dec(Rotation);

    if Ord(Rotation) < Ord(prNormal) then
      Rotation := pr90CounterClockwide;

    if Rotation in [prNormal, pr180] then
    begin
      Height := LPage.Height;
      Width := LPage.Width;
    end
    else
    begin
      Height := LPage.Width;
      Width := LPage.Height;
    end;
  end;

  DoSizeChanged;
end;

procedure TPDFiumControl.ZoomToHeight;
begin
  ZoomMode := zmFitHeight;
  DoSizeChanged;
end;

procedure TPDFiumControl.ZoomToWidth;
begin
  ZoomMode := zmFitWidth;
  DoSizeChanged;
end;

procedure TPDFiumControl.FormOutputSelectedRect(ADocument: TPDFDocument; APage: TPDFPage; const APageRect: TPDFRect);
begin
  if HandleAllocated then
  begin
    SetLength(FFormOutputSelectedRects, Length(FFormOutputSelectedRects) + 1);
    FFormOutputSelectedRects[Length(FFormOutputSelectedRects) - 1] := APageRect;
  end;
end;

procedure TPDFiumControl.FormGetCurrentPage(ADocument: TPDFDocument; var APage: TPDFPage);
begin
  APage := CurrentPage;
end;

procedure TPDFiumControl.FormInvalidate(ADocument: TPdfDocument; APage: TPdfPage; const APageRect: TPdfRect);
var
  LRect: TRect;
begin
  FFormOutputSelectedRects := nil;

  if HandleAllocated then
  begin
    LRect := InternPageToDevice(APage, APageRect, FPageInfo[FPageIndex].Rect);
    InvalidateRect(Handle, @LRect, True);
  end;
end;

procedure TPDFiumControl.FormFieldFocus(ADocument: TPDFDocument; AValue: PWideChar; AValueLen: Integer; AFieldFocused: Boolean);
begin
  ClearSelection;
  FFormFieldFocused := AFieldFocused;
end;

procedure TPDFiumControl.ShowError(const AMessage: string);
begin
{$IFDEF ALPHASKINS}
  sMessageDlg(AMessage, mtError, [mbOK], 0);
{$ELSE}
  MessageDlg(AMessage, mtError, [mbOK], 0);
{$ENDIF}
end;

procedure TPDFiumControl.KeyDown(var Key: Word; Shift: TShiftState);
const
  DefaultScrollOffset = 50;
begin
  inherited KeyDown(Key, Shift);

  case Key of
    VK_RIGHT, VK_LEFT, VK_UP, VK_DOWN:
      FChanged := True;
  end;

  case Key of
    Ord('C'), VK_INSERT:
      if AllowTextSelection and (Shift = [ssCtrl]) then
      begin
        if FSelectionActive then
          CopyToClipboard;

        Key := 0;
      end;
    Ord('A'):
      if AllowTextSelection and (Shift = [ssCtrl]) then
      begin
        SelectAll;
        SelectAllFormText;

        Key := 0;
      end;
    VK_RIGHT:
      HorzScrollBar.Position := HorzScrollBar.Position - DefaultScrollOffset;
    VK_LEFT:
      HorzScrollBar.Position := HorzScrollBar.Position + DefaultScrollOffset;
    VK_UP:
      VertScrollBar.Position := VertScrollBar.Position - DefaultScrollOffset;
    VK_DOWN:
      VertScrollBar.Position := VertScrollBar.Position + DefaultScrollOffset;
    VK_PRIOR:
      GotoPreviousPage;
    VK_NEXT:
      GotoNextPage;
    VK_HOME:
      GotoPage(0);
    VK_END:
      GotoPage(PageCount - 1);
  end;

  case Key of
    VK_UP, VK_DOWN:
      UpdatePageIndex;
  end;

  case Key of
    VK_UP, VK_DOWN, VK_PRIOR, VK_NEXT, VK_HOME, VK_END:
      if Assigned(OnScroll) then
        OnScroll(Self, sbVertical);
  end;
end;

{ TPDFiumControlThumbnails }

constructor TPDFiumControlThumbnails.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

{$IFDEF ALPHASKINS}
  FSkinData := TsScrollWndData.Create(Self, True);
  FSkinData.COC := COC_TsDBGrid;
  FSkinData.CustomFont := True;
  StyleElements := [seBorder];
{$ENDIF}
  BorderStyle := bsNone;
  ColCount := 1;
  Color := TColors.SysWindow;
  DefaultDrawing := False;
  DoubleBuffered := True;
  FDefaultSizeSet := False;
  FixedCols := 0;
  FixedRows := 0;
  Options := [goFixedVertLine, goFixedHorzLine, goVertLine, goRowSelect, goThumbTracking];
  ScrollBars := System.UITypes.TScrollStyle.ssVertical;
  Width := 180;
end;

{$IFDEF ALPHASKINS}
destructor TPDFiumControlThumbnails.Destroy;
begin
  if Assigned(FScrollWnd) then
  begin
    FScrollWnd.Free;
    FScrollWnd := nil;
  end;

  if Assigned(FSkinData) then
  begin
    FSkinData.Free;
    FSkinData := nil;
  end;

  inherited;
end;

procedure TPDFiumControlThumbnails.AfterConstruction;
begin
  inherited AfterConstruction;

  if HandleAllocated then
    RefreshEditScrolls(SkinData, FScrollWnd);

  UpdateData(FSkinData);
end;

procedure TPDFiumControlThumbnails.Loaded;
begin
  inherited Loaded;

  FSkinData.Loaded(False);
end;

procedure TPDFiumControlThumbnails.WndProc(var AMessage: TMessage);
var
  LPaintStruct: TPaintStruct;
begin
  if AMessage.Msg = SM_ALPHACMD then
    case AMessage.WParamHi of
      AC_CTRLHANDLED:
        begin
          AMessage.Result := 1;
          Exit;
        end;
      AC_SETNEWSKIN:
        if ACUInt(AMessage.LParam) = ACUInt(SkinData.SkinManager) then
        begin
          CommonMessage(AMessage, FSkinData);
          Exit;
        end;
      AC_REMOVESKIN:
        if ACUInt(AMessage.LParam) = ACUInt(SkinData.SkinManager) then
        begin
          if Assigned(FScrollWnd) then
          begin
            FreeAndNil(FScrollWnd);
            RecreateWnd;
          end;
          Exit;
        end;
      AC_REFRESH:
        if RefreshNeeded(SkinData, AMessage) then
        begin
          RefreshEditScrolls(SkinData, FScrollWnd);
          CommonMessage(AMessage, FSkinData);
          if HandleAllocated and Visible then
            RedrawWindow(Handle, nil, 0, RDWA_REPAINT);
          Exit;
        end;
      AC_GETDEFSECTION:
        begin
          AMessage.Result := 1;
          Exit;
        end;
      AC_GETDEFINDEX:
        begin
          if Assigned(FSkinData.SkinManager) then
            AMessage.Result := FSkinData.SkinManager.SkinCommonInfo.Sections[ssEdit] + 1;
          Exit;
        end;
      AC_SETGLASSMODE:
        begin
          CommonMessage(AMessage, FSkinData);
          Exit;
        end;
    end;

  if not ControlIsReady(Self) or not Assigned(FSkinData) or not FSkinData.Skinned then
    inherited
  else
  begin
    case AMessage.Msg of
      WM_ERASEBKGND:
        if (SkinData.SkinIndex >= 0) and InUpdating(FSkinData) then
          Exit;
      WM_PAINT:
        begin
          if InUpdating(FSkinData) then
          begin
            BeginPaint(Handle, LPaintStruct);
            EndPaint(Handle, LPaintStruct);
          end
          else
            inherited;

          Exit;
        end;
    end;

    if CommonWndProc(AMessage, FSkinData) then
      Exit;

    inherited;

    case AMessage.Msg of
      CM_SHOWINGCHANGED:
        RefreshEditScrolls(SkinData, FScrollWnd);
      CM_VISIBLECHANGED, CM_ENABLEDCHANGED, WM_SETFONT:
        FSkinData.Invalidate;
      CM_TEXTCHANGED, CM_CHANGED:
        if Assigned(FScrollWnd) then
          UpdateScrolls(FScrollWnd, True);
    end;
  end;
end;
{$ENDIF}

procedure TPDFiumControlThumbnails.DrawCell(ACol, ARow: Longint; ARect: TRect; AState: TGridDrawState);
var
  LRect: TRect;
begin
  if not Assigned(PDFiumControl) then
    Exit;

  RowCount := PDFiumControl.PageCount;
  Row := PDFiumControl.PageIndex;

  if (RowCount > 0) and not FDefaultSizeSet then
  begin
    SetDefaultSize;
    FDefaultSizeSet := True;
  end;

  if gdSelected in AState then
  begin
{$IFDEF ALPHASKINS}
    if FSkinData.SkinManager.Active then
    begin
      Canvas.Brush.Color := FSkinData.SkinManager.GetHighLightColor;
      Canvas.Font.Color := FSkinData.SkinManager.GetHighLightFontColor;
    end
    else
    begin
{$ENDIF}
      Canvas.Brush.Color := TColors.SysHighlight;
      Canvas.Font.Color := TColors.SysHighlightText;
{$IFDEF ALPHASKINS}
    end;
{$ENDIF}
  end
  else
  begin
{$IFDEF ALPHASKINS}
    if FSkinData.SkinManager.Active then
    begin
      Canvas.Brush.Color := FSkinData.SkinManager.GetActiveEditColor;
      Canvas.Font.Color := FSkinData.SkinManager.GetActiveEditFontColor;
    end
    else
    begin
{$ENDIF}
      Canvas.Brush.Color := TColors.SysWindow;
      Canvas.Font.Color := TColors.SysWindowText;
{$IFDEF ALPHASKINS}
    end;
{$ENDIF}
  end;

  Canvas.FillRect(ARect);

  LRect := ARect;
  InflateRect(LRect, -9, -9);
  Inc(LRect.Left, 8);

{$IFDEF ALPHASKINS}
  if IsLightStyleColor(Color) then
  begin
{$ENDIF}
    Canvas.Pen.Color := TColors.Silver;
    Canvas.Rectangle(LRect);

    InflateRect(LRect, -1, -1);
{$IFDEF ALPHASKINS}
  end;
{$ENDIF}

  PDFiumControl.PaintPage(Canvas.Handle, LRect, ARow);

  Canvas.Pen.Color := TColors.Black;
  Canvas.Brush.Color := TColors.SysBtnFace;
  SetBkMode(Canvas.Handle, TRANSPARENT);
  Canvas.Textout(ARect.Left + 2, ARect.Top, IntToStr(ARow + 1));
  SetBkMode(Canvas.Handle, OPAQUE);
end;

{ https://quality.embarcadero.com/browse/RSP-18542 }
procedure TPDFiumControlThumbnails.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FTimerStarted := False;

  FIsMousedown := True;
  try
    inherited;
  finally
    FIsMousedown := False;
  end;

  if FGridState = gsSelecting then
    KillTimer(Handle, 1);
end;

procedure TPDFiumControlThumbnails.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  if not FTimerStarted and (FGridState = gsSelecting) then
  begin
    SetTimer(Handle, 1, 60, nil);
    FTimerStarted := True;
  end;

  inherited;
end;

procedure TPDFiumControlThumbnails.Resize;
begin
  inherited Resize;

  SetDefaultSize;
end;

procedure TPDFiumControlThumbnails.SetDefaultSize;
var
  LPage: TPDFPage;
  LHeigth: Integer;
begin
  if not Assigned(PDFiumControl) then
    Exit;

  if DefaultColWidth <> ClientWidth then
    DefaultColWidth := ClientWidth;

  LPage := PDFiumControl.GetPage(0);

  if Assigned(LPage) then
  begin
    LHeigth := Round(((DefaultColWidth - 8) / LPage.Width) * LPage.Height);

    if DefaultRowHeight <> LHeigth then
      DefaultRowHeight := LHeigth;
  end;
end;

procedure TPDFiumControlThumbnails.DoPDFiumControlPageChanged(Sender: TObject);
begin
  Invalidate;
end;

procedure TPDFiumControlThumbnails.SetPDFiumControl(const AValue: TPDFiumControl);
begin
  FPDFiumControl := AValue;
  FPDFiumControl.OnPageChanged := DoPDFiumControlPageChanged;
end;

function TPDFiumControlThumbnails.SelectCell(ACol, ARow: Longint): Boolean;
begin
  Result := inherited;

  if Result and FIsMousedown then
  begin
    FIsMousedown := False;
    try
      MoveColRow(ACol, ARow, True, False);
    finally
      FIsMousedown := True;
    end;

    Result := False;
  end;

  if Result and Assigned(PDFiumControl) then
    PDFiumControl.GoToPage(ARow);
end;

{ TPDFDocumentVclPrinter }

function VclAbortProc(Prn: HDC; Error: Integer): Bool; stdcall;
begin
  Application.ProcessMessages;

  Result := not Printer.Aborted;
end;

function FastVclAbortProc(Prn: HDC; Error: Integer): Bool; stdcall;
begin
  Result := not Printer.Aborted;
end;

function TPDFDocumentVclPrinter.PrinterStartDoc(const AJobTitle: string): Boolean;
begin
  Result := False;

  FPagePrinted := False;

  if not Printer.Printing then
  begin
    if AJobTitle <> '' then
      Printer.Title := AJobTitle;

    Printer.BeginDoc;
    FBeginDocCalled := Printer.Printing;
    Result := FBeginDocCalled;
  end;

  if Result then
    SetAbortProc(GetPrinterDC, @FastVclAbortProc);
end;

procedure TPDFDocumentVclPrinter.PrinterEndDoc;
begin
  if Printer.Printing and FBeginDocCalled then
    Printer.EndDoc;

  SetAbortProc(GetPrinterDC, @VclAbortProc);
end;

procedure TPDFDocumentVclPrinter.PrinterStartPage;
begin
  if (Printer.PageNumber > 1) or FPagePrinted then
    Printer.NewPage;
end;

procedure TPDFDocumentVclPrinter.PrinterEndPage;
begin
  FPagePrinted := True;
end;

function TPDFDocumentVclPrinter.GetPrinterDC: HDC;
begin
  Result := Printer.Handle;
end;

class function TPDFDocumentVclPrinter.PrintDocument(const ADocument: TPDFDocument;
  const AJobTitle: string; const AShowPrintDialog: Boolean = True; const AAllowPageRange: Boolean = True;
  const AParentWnd: HWND = 0): Boolean;
var
  LPDFDocumentVclPrinter: TPDFDocumentVclPrinter;
  LPrintDialog: TPrintDialog;
  LFromPage, LToPage: Integer;
begin
  Result := False;

  if not Assigned(ADocument) then
    Exit;

  LFromPage := 1;
  LToPage := ADocument.PageCount;

  if AShowPrintDialog then
  begin
    LPrintDialog := TPrintDialog.Create(nil);
    try
      if AAllowPageRange then
      begin
        LPrintDialog.Options := LPrintDialog.Options + [poPageNums];
        LPrintDialog.MinPage := 1;
        LPrintDialog.MaxPage := ADocument.PageCount;
        LPrintDialog.ToPage := ADocument.PageCount;
      end;

      if (AParentWnd = 0) or not IsWindow(AParentWnd) then
        Result := LPrintDialog.Execute
      else
        Result := LPrintDialog.Execute(AParentWnd);

      if not Result then
        Exit;

      if AAllowPageRange and (LPrintDialog.PrintRange = prPageNums) then
      begin
        LFromPage := LPrintDialog.FromPage;
        LToPage := LPrintDialog.ToPage;
      end;
      { Note! Copies and collate won't work. Andy's core class needs to be fixed to get it working.
        Capture here the variables and pass them to following Print function.

        LCopies := LPrintDialog.Copies;
        LCollate := LPrintDialog.Collate; }
    finally
      LPrintDialog.Free;
    end;
  end;

  { Note! If the document has pages in portrait and landscape orientation, this will not work properly. The problem is
    that the orientation of the printer can be changed only when outside BeginDoc and EndDoc. If there is a need for
    that, then Andy's core class needs to be fixed. }
  if ADocument.PageCount > 0 then
    if ADocument.Pages[0].Height > ADocument.Pages[0].Width then
      Printer.Orientation := poPortrait
    else
      Printer.Orientation := poLandscape;

  LPDFDocumentVclPrinter := TPDFDocumentVclPrinter.Create;
  try
    if LPDFDocumentVclPrinter.BeginPrint(AJobTitle) then
    try
      Result := LPDFDocumentVclPrinter.Print(ADocument, LFromPage - 1, LToPage - 1);
    finally
      LPDFDocumentVclPrinter.EndPrint;
    end;
  finally
    LPDFDocumentVclPrinter.Free;
  end;
end;

end.
