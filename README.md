# TPDFiumControl

Page scrolling PDF control for Delphi.

## Requires 

Andy's [PdfiumLib](https://github.com/ahausladen/PdfiumLib) core classes - PdfiumCore.pas and PdfiumLib.pas.

## Supports

- AlphaSkins (native) - https://www.alphaskins.com/

## Defines

Define | Description
------ | -----------
ALPHASKINS | Native AlphaSkins support

## Annotation links

Use of annotation links requires a following fix for PdfiumCore.pas.
```Pascal
TPdfAnnotation = class(TObject)
private
  FFormField: TPdfFormField;
  FHandle: FPDF_ANNOTATION;
  FIsFormField: Boolean;
  FIsLink: Boolean;
  FLinkRect: TPDFRect;
  FPage: TPdfPage;
  FURL: string;
protected
  constructor Create(APage: TPdfPage; AHandle: FPDF_ANNOTATION);
public
  destructor Destroy; override;
  property FormField: TPdfFormField read FFormField;
  property Handle: FPDF_ANNOTATION read FHandle;
  property IsFormField: Boolean read FIsFormField;
  property IsLink: Boolean read FIsLink;
  property LinkRect: TPDFRect read FLinkRect;
  property URL: string read FURL;
end;

constructor TPdfAnnotation.Create(APage: TPdfPage; AHandle: FPDF_ANNOTATION);
var
  LSubType: FPDF_ANNOTATION_SUBTYPE;
  LRect: FS_RECTF;
  LLink: FPDF_LINK;
  LAction: FPDF_ACTION;
  LActionType: LongWord;
  LBufferSize: LongWord;
  LBuffer: array of AnsiChar;
begin
  inherited Create;

  FPage := APage;
  FHandle := AHandle;

  LSubType := FPDFAnnot_GetSubtype(AHandle);

  FIsFormField := LSubType in [FPDF_ANNOT_WIDGET, FPDF_ANNOT_XFAWIDGET];

  if FIsFormField then
    FFormField := TPdfFormField.Create(Self);

  FIsLink := LSubType = FPDF_ANNOT_LINK;

  if FIsLink then
  begin
    FPDFAnnot_GetRect(AHandle, @LRect);

    FLinkRect.Left := LRect.Left;
    FLinkRect.Top := LRect.Top;
    FLinkRect.Right := LRect.Right;
    FLinkRect.Bottom := LRect.Bottom;

    LLink := FPDFAnnot_GetLink(AHandle);

    if Assigned(LLink) then
    begin
      LAction := FPDFLink_GetAction(LLink);
      LActionType := FPDFAction_GetType(LAction);

      if LActionType = PDFACTION_URI then
      begin
        LBufferSize := FPDFAction_GetURIPath(APage.FDocument.FDocument, LAction, nil, 0);
        SetLength(LBuffer, LBufferSize);
        FPDFAction_GetURIPath(APage.FDocument.FDocument, LAction, PAnsiChar(LBuffer), LBufferSize);
        SetString(FURL, PAnsiChar(LBuffer), LBufferSize);
      end;
    end;
  end;
end;

destructor TPdfAnnotation.Destroy;
begin
  if Assigned(FFormField) then
    FreeAndNil(FFormField);

  if FHandle <> nil then
  begin
    FPDFPage_CloseAnnot(FHandle);
    FHandle := nil;
  end;

  if FPage.FAnnotations <> nil then
    FPage.FAnnotations.DestroyingItem(Self);

  inherited Destroy;
end;
```
## License

[MIT](https://github.com/TextEditorPro/TTextEditor/blob/main/LICENSE)

## Connect 

https://www.linkedin.com/in/lassemarkusrautiainen/

## Donations

https://www.texteditor.pro/support/donations/
