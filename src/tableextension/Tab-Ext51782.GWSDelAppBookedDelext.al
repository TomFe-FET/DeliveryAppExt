tableextension 51782 "GWS Del. App Booked Del. ext" extends Verkaufslieferkopf
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
