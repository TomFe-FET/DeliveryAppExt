page 51781 "GWS Del. App Quant. Diff. Cue"
{

    Caption = 'GWS Del. App Quantity Diff. Cue';
    PageType = List;
    Editable = false;
    CardPageID = Verkaufsauftrag;
    SourceTable = Verkaufskopf;
    RefreshOnActivate = true;
    SourceTableView = where(Belegart = filter(Auftrag),
                            Barverkauf = CONST(false),
                            Erledigt = CONST(false),
                            "Rücklieferung" = CONST(false),
                            "Status Update from App" = filter(1));
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Nr."; Rec."Nr.")
                {
                    ApplicationArea = All;
                }
                field(Auftragsdatum; Rec.Auftragsdatum)
                {
                    ApplicationArea = All;
                }
                field("Status Update from App"; Rec."Status Update from App")
                {
                    ApplicationArea = All;
                }
                field("Receipt Picture"; Rec."Receipt Picture")
                {
                    ApplicationArea = All;
                }
                field(Betrag; Rec.Betrag)
                {
                    ApplicationArea = All;
                }
                field(Lagerortcode; Rec.Lagerortcode)
                {
                    ApplicationArea = All;
                }
                field("Verk. an Deb.-Nr."; Rec."Verk. an Deb.-Nr.")
                {
                    ApplicationArea = All;
                }
                field("Verk. an Name"; Rec."Verk. an Name")
                {
                    ApplicationArea = All;
                }
                field("Verk. an Name 2"; Rec."Verk. an Name 2")
                {
                    ApplicationArea = All;
                }
                field(Lieferdatum; Rec.Lieferdatum)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
    actions
    {
        area(Creation)
        {
            action(testfet)
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = codeunit "GWS Delivery App Api";

            }
        }

    }
}
