#pragma warning disable 0004
#pragma warning disable 0003
#pragma warning restore 0004
table 51780 "GWS Delivery App Orderhead"
#pragma warning restore 0003
{
    Fields
    {
        Field(1; No; Code[30])
        {
        }
        Field(2; "Debitor No."; Code[30])
        {
        }
        Field(3; "Debitor Name"; Text[100])
        {
        }
        Field(4; "Debitor Name 2"; Text[100])
        {
        }
    }
    keys
    {
        key(PK; No)
        {
            Clustered = true;
        }
    }
}