unit BrowserWindowFactory;

uses
    TBrowserWindow;

interface

TBrowserWindowInstance = class
    constructor Init;
    procedure SetTitle(NewTitle: AnsiString);
    private
        Window: TBrowserWindow;
        Title: String;
end;

TBrowserWindowInstances = array of TBrowserWindowInstance;

TBrowserWindowFactory = class
    constructor Init;
    private
        ActiveInstance: SizeInt = 0;
        Instances: TBrowserWindowInstances;

end;

implementation
