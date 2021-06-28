tableextension 51780 "GWS Delivery App OrderHead ext" extends Verkaufskopf
{
    fields
    {
        field(50000; "Receipt Picture"; Text[1024])
        {
            ExtendedDatatype = URL;
            Editable = false;
        }
        field(50001; "Status Update from App"; Option)
        {
            Editable = false;
            OptionMembers = " ","Quantity difference from PowerApp above Percentage","Received new Quantity";
        }
    }
}
