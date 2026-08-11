# TPDFiumControl

The latest version of the page scrolling PDF control for Delphi.

## Requires 

Andy's [PdfiumLib](https://github.com/ahausladen/PdfiumLib) core classes - PdfiumCore.pas and PdfiumLib.pas.

Note! PDFIUMCORE_PRINTER_ORIENTATION_FIX and PDFIUMCORE_PRINTER_ORIENTATION_FIX defines require fixes in PdfiumCore.pas. 

## Supports

- AlphaSkins (native) - https://www.alphaskins.com/

## Defines

Define | Description
------ | -----------
ALPHASKINS | Native AlphaSkins support
USE_LOAD_FROM_URL | Enables TCustomPDFiumControl.LoadFromURL, which downloads a PDF document over HTTP/HTTPS (TLS 1.1-1.3, redirects followed, 60 second timeouts) and opens it.
PDFIUMCORE_PRINTER_ORIENTATION_FIX | Enables per page printer orientation switching in TPDFDocumentVclPrinter, so that a document containing both portrait and landscape pages is printed with the correct orientation for every page, instead of rotating the pages into the single orientation selected before BeginDoc. 
PDFIUMCORE_PRINTER_ORIENTATION_FIX | Enables printing of multiple copies, with or without collation, in TPDFDocumentVclPrinter.PrintDocument. The copies are produced by the print loop itself and the printer driver's copy count is forced to 1, so collation also works on printers whose driver cannot collate.

## License

[MIT](https://github.com/TextEditorPro/TTextEditor/blob/main/LICENSE)