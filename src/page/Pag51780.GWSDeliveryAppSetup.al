page 51780 "GWS Delivery App Setup"
{

    Caption = 'GWS Delivery App Setup';
    PageType = Card;
    Editable = true;
    SourceTable = "GWS Delivery App Setup";
    UsageCategory = Administration;
    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Azure SQL DB Api Key"; Rec."Azure SQL DB Api Key")
                {
                    ApplicationArea = All;
                    ExtendedDatatype = Masked;
                }
                field("Azure SQL DB Base Adress"; Rec."Azure SQL DB Base Adress")
                {
                    ApplicationArea = All;
                }
                field("Update Orders Api Key"; Rec."Updated Orders Api Key")
                {
                    ApplicationArea = All;
                    ExtendedDatatype = Masked;
                }
                field("Update Orders Base Adress"; Rec."Updated Orders Base Adress")
                {
                    ApplicationArea = All;
                }
                field("Delete Orders Api Key"; Rec."Deleted Orders Api Key")
                {
                    ApplicationArea = All;
                    ExtendedDatatype = Masked;
                }
                field("Delete Orders Base Adress"; Rec."Deleted Orders Base Adress")
                {
                    ApplicationArea = All;
                }
                field("Post Delivery"; Rec."Post Delivery")
                {
                    ApplicationArea = All;
                }
                field("Post Invoice"; Rec."Post Invoice")
                {
                    ApplicationArea = All;
                }
                field("Mail Invoice"; Rec."Mail Invoice")
                {
                    ApplicationArea = All;
                }
                field("Percentage of Quantity Diff."; Rec."Percentage of Quantity Diff.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Percentage to control the difference between the updated Quantity from the DeliveryApp and the Quantity from the Order';
                }

            }
        }
    }
    trigger OnOpenPage()
    begin
        Rec.RESET;
        IF NOT Rec.GET THEN
            IF NOT Rec.INSERT THEN
                Err.Throw(STRSUBSTNO(Err.ERR_INSERT(), Rec.TABLECAPTION, Err.FormatPosition(Rec.GETPOSITION)));
    end;

    var
        Err: Codeunit ErrorHandler;
}
