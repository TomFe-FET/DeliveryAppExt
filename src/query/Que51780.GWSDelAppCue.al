query 51780 "GWS Del. App Cue"
{
    Caption = 'GWS Del. App Cue';
    Permissions = TableData Verkaufskopf = rimd;

    elements
    {
        dataitem(Verkaufskopf; Verkaufskopf)
        {
            Filter(Nr; "Nr.")
            {
            }
            Filter(Belegart; Belegart)
            {
            }
            Filter(Barverkauf; Barverkauf)
            {
            }
            Filter(StatusUpdatefromApp; "Status Update from App")
            {
            }
            Filter(Erledigt; Erledigt)
            {

            }
            column("CountOrders")
            {
                Method = Count;
            }
        }
    }

    trigger OnBeforeOpen()
    begin

    end;
}
