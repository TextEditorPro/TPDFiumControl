// Native AlphaSkins support
{.$DEFINE ALPHASKINS}

// VCL style support
{.$DEFINE PDFIUM_CONTROL_STYLE_HOOKS}

{ Enables TCustomPDFiumControl.LoadFromURL, which downloads a PDF document over HTTP/HTTPS (TLS 1.1-1.3, redirects
  followed, 60 second timeouts) and opens it. Disabled by default so that the unit does not pull in the
  System.Net.HttpClient units when the feature is not needed. }
{.$DEFINE USE_LOAD_FROM_URL}

{ Enables per page printer orientation switching in TPDFDocumentVclPrinter, so that a document containing both
  portrait and landscape pages is printed with the correct orientation for every page, instead of rotating the
  pages into the single orientation selected before BeginDoc.

  Note! This requires a fix in PdfiumCore.pas (TPdfDocumentPrinter) that has not been reported to the PdfiumLib
  developer yet, so the define must stay disabled until the fix is in. The required fix:

  1. Add a new virtual method to the protected section of TPdfDocumentPrinter, after GetPrinterDC:

       // Called before PrinterStartPage when the orientation of the next page differs from the printer's current
       // orientation. A descendant that can switch the orientation of the running print job does so and returns
       // True; the printer DC and the printer bounds are then re-read. Returning False keeps the old behaviour
       // (the print area is rotated by swapping its width and height).
       function PrinterSetOrientation(const APortrait: Boolean): Boolean; virtual;

     with a default implementation that just returns False.

  2. In TPdfDocumentPrinter.Print(ADocument, AFromPageIndex, AToPageIndex), inside the page loop, right after
     PagePortraitOrientation has been calculated and before the FitPageToPrintArea block and the PrinterStartPage
     call, add:

       if (PagePortraitOrientation <> FPrintPortraitOrientation) and PrinterSetOrientation(PagePortraitOrientation) then
       begin
         FPrinterDC := GetPrinterDC;
         GetPrinterBounds;
         FPrintPortraitOrientation := IsPortraitOrientation(FPaperSize.cx, FPaperSize.cy);
       end; }
{.$DEFINE PDFIUMCORE_PRINTER_ORIENTATION_FIX}

{ Enables printing of multiple copies, with or without collation, in TPDFDocumentVclPrinter.PrintDocument. The
  copies are produced by the print loop itself and the printer driver's copy count is forced to 1, so collation
  also works on printers whose driver cannot collate.

  Note! This requires a fix in PdfiumCore.pas (TPdfDocumentPrinter) that has not been reported to the PdfiumLib
  developer yet, so the define must stay disabled until the fix is in. The required fix:

  1. Change the page range overload of Print to

       function Print(ADocument: TPdfDocument; AFromPageIndex, AToPageIndex: Integer; const ACopies: Integer;
         const ACollate: Boolean): Boolean; overload;

     and let the print all overload Print(ADocument) call it with ACopies = 1 and ACollate = False.

  2. In the implementation of the page range overload, wrap the body of the page loop (everything inside
     "for PageIndex := AFromPageIndex to AToPageIndex do") into a local procedure, for example PrintPage, declare
     a new local variable "CopyIndex: Integer", and replace the loop with:

       if ACollate then
       begin
         for CopyIndex := 1 to ACopies do
           for PageIndex := AFromPageIndex to AToPageIndex do
             PrintPage;
       end
       else
       begin
         for PageIndex := AFromPageIndex to AToPageIndex do
           for CopyIndex := 1 to ACopies do
             PrintPage;
       end; }
{.$DEFINE PDFIUMCORE_PRINTER_COPIES_COLLATE_FIX}