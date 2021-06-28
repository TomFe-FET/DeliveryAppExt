#pragma warning disable 0003
table 51781 "GWS Delivery App Setup"
#pragma warning restore 0003
{
    fields
    {
        field(1; "Primary Key"; Code[30])
        {
        }
        field(2; "Azure SQL DB Base Adress"; Text[250])
        {
        }
        field(3; "Azure SQL DB Api Key"; Text[250])
        {
        }
        field(4; "Updated Orders Base Adress"; Text[250])
        {
        }
        field(5; "Updated Orders Api Key"; Text[250])
        {
        }
        field(7; "Deleted Orders Base Adress"; Text[250])
        {
        }
        field(8; "Deleted Orders Api Key"; Text[250])
        {
        }
        field(6; "Percentage of Quantity Diff."; Decimal)
        {
            trigger OnValidate()
            begin
                if ("Percentage of Quantity Diff." > 100) or ("Percentage of Quantity Diff." <= 0) then
                    FieldError("Percentage of Quantity Diff.");
            end;
        }
        field(9; "Post Invoice"; Boolean)
        {
        }
        field(10; "Post Delivery"; Boolean)
        {
        }
        field(11; "Mail Invoice"; Boolean)
        {
        }

    }
    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
