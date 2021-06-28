pageextension 51782 "GWS Del. App Booked Del. ext." extends "Geb. Verkaufslieferung"
{
    layout
    {
        addlast(Lieferung)
        {
            field("Status Update from App"; Rec."Status Update from App")
            {
                ApplicationArea = all;
            }
            field("Receipt Picture"; Rec."Receipt Picture")
            {
                ApplicationArea = all;
            }
        }

    }
}
