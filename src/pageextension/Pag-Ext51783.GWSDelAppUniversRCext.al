pageextension 51783 "GWS Del. App Univers RC ext" extends "Universal RC Activities"
{
    layout
    {
        addlast("Sale Cues")
        {
            field("GWS Del. App Quantity Diff."; GwsDelApp)
            {
                Caption = 'GWS Del. App Quantity Diff.';
                StyleExpr = 'Middle Range Style';
                Visible = true;
                DrillDownPageId = "GWS Del. App Quant. Diff. Cue";
                ApplicationArea = all;

                trigger OnDrillDown()
                var
                    lCueSetup: Record "GWS Cue Setup";
                begin
                    CalcOrders();
                    OpenOrdersQuantityDiff();
                end;
            }
        }
    }
    trigger OnOpenPage()
    var
    begin
        CalcOrders();
    end;

    var
        GwsDelApp: Integer;

    procedure CalcOrders()
    var
        lDelAppCue: Query "GWS Del. App Cue";
    begin
        lDelAppCue.SetFilter(Belegart, 'Auftrag');
        lDelAppCue.SetFilter(Barverkauf, 'false');
        lDelAppCue.SetFilter(StatusUpdatefromApp, '1');
        lDelAppCue.SetFilter(Erledigt, 'false');
        lDelAppCue.Open();
        lDelAppCue.Read();
        GwsDelApp := lDelAppCue.CountOrders;
    end;

    local procedure OpenOrdersQuantityDiff()
    var
        lOrdersQuantDiff: Page "GWS Del. App Quant. Diff. Cue";
    begin
        lOrdersQuantDiff.Run();
    end;
}