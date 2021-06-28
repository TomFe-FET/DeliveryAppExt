pageextension 51781 "GWS Del. App Booked Inv. ext." extends "Geb. Verkaufsrechnung"
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
