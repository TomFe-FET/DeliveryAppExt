
pageextension 51780 "GWS Delivery App salesord ext." extends Verkaufsauftrag
{
    layout
    {
        addlast(ctrlTabControl1_2)
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

