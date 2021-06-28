codeunit 51781 "GWS Delivery App Api"
{
    trigger OnRun()
    begin
        GetAllUpdatedOrders();
    end;

    local procedure GetAllUpdatedOrders()
    var
        lDeliveryAppSetup: Record "GWS Delivery App Setup";
        lClient: HttpClient;
        lContent: HttpContent;
        lResponseMessage: HttpResponseMessage;
        lStream: InStream;
        lJsArray: JsonArray;
        lJsObject: JsonObject;
        lResponse: Text;
        lUrl: Text;
        ServiceResponseNotReadableErr: Label 'Error in Servicecall: The response of the service is not readable.';
        ServiceResponseNoJsonErr: Label 'Error in Servicecall: The response of the service is invalid: %1';
        ServiceErrorCode: Label 'Error in Servicecall: HTTP error code %1';
    begin
        GetDeliveryAppSetup(lDeliveryAppSetup);
        //lClient.DefaultRequestHeaders.Add('x-functions-key', '6fYaN5CaNoIqKIaahtTDIHaPoKKX8Z1D7SgZqQg5sNDLuqd8ByT5xA==');
        lClient.DefaultRequestHeaders.Add('x-functions-key', lDeliveryAppSetup."Updated Orders Api Key");

        //lUrl := 'https://deliveryappgws.azurewebsites.net/api/getUpdatedOrders?';
        lUrl := lDeliveryAppSetup."Updated Orders Base Adress";
        if not lClient.Get(lUrl, lResponseMessage) then
            exit;

        if not lResponseMessage.IsSuccessStatusCode() then
            Err.Throw(StrSubstNo(ServiceErrorCode, lResponseMessage.HttpStatusCode));

        if (lResponseMessage.HttpStatusCode = 204) then
            exit;

        if not lResponseMessage.Content().ReadAs(lResponse) then
            Err.Throw(ServiceResponseNotReadableErr);

        if not lJsArray.ReadFrom(lResponse) then
            Err.Throw(StrSubstNo(ServiceResponseNoJsonErr, lResponse));

        ReadToRecord(lJsArray);
    end;

    local procedure ReadToRecord(pJsArray: JsonArray)
    var
        lOrderHead: Record Verkaufskopf;
        lOrderLine: Record Verkaufszeile;
        lJsonHelper: Codeunit "GWSBSY JSON Helper Functions";
        lSaleBooking: Codeunit "Verkauf-buchen";
        lJsObject: JsonObject;
        lJsToken: JsonToken;
        lNo: Code[20];
        lLineNr: Integer;
        lQuantity: Decimal;
    begin
        FOREACH lJsToken IN pJsArray DO BEGIN
            lJsObject := lJsToken.AsObject();
            lNo := lJsonHelper.GetJSONValue(lJsObject, 'OrderHeadNo').AsCode();
            lLineNr := lJsonHelper.GetJSONValue(lJsObject, 'LinesID').AsInteger();
            GetOrderLineAndHead(lOrderHead, lOrderLine, lNo, lLineNr);
            lQuantity := lJsonHelper.GetJSONValue(lJsObject, 'Amount').AsDecimal();
            if CheckQuantityDifference(lQuantity, lOrderLine) then begin
                lOrderHead.Validate("Status Update from App", lOrderHead."Status Update from App"::"Quantity difference from PowerApp above Percentage");
                lOrderHead.Validate(Rechnungssperre, true);
                lOrderHead.Validate(Lieferungssperre, true);
            end else begin
                lOrderHead.Validate("Status Update from App", lOrderHead."Status Update from App"::"Received new Quantity");
            end;

            lOrderLine.Validate("Externe Belegnummer", lJsonHelper.GetJSONValue(lJsObject, 'ReceiptNo').AsCode());
            lOrderLine.Validate(Menge, lQuantity);
            if not lOrderLine.Modify() then
                Err.Throw(strsubstno(Err.ERR_MODIFY, lOrderLine."Nr.", lNo));

            lOrderHead.Validate("Receipt Picture", lJsonHelper.GetJSONValue(lJsObject, 'PictureURL').AsText());
            lOrderHead.Validate("Externe Belegnummer", lJsonHelper.GetJSONValue(lJsObject, 'ReceiptNo').AsCode());
            if not lOrderHead.Modify() then
                Err.Throw(strsubstno(Err.ERR_MODIFY, lOrderHead."Nr.", lNo));

            if not (lOrderHead.Lieferungssperre) or not (lOrderHead.Rechnungssperre) then begin
                if CheckBooking(lOrderHead) then begin
                    if not lOrderHead.Modify() then
                        Err.Throw(strsubstno(Err.ERR_MODIFY, lOrderHead."Nr.", lNo));
                    lSaleBooking.Run(lOrderHead);
                    UpdateNewFields(lOrderHead);
                    MailInvoice(lOrderHead);
                end;
            end;
            DeleteOrderInTable(lOrderHead);
        END;
    end;

    local procedure MailInvoice(pOrderHead: Record Verkaufskopf)
    var
        lInvoiceHead: Record Verkaufsrechnungskopf;
        lGwsDelAppSetup: Record "GWS Delivery App Setup";
        lPrintRec: Codeunit "Beleg-drucken";
    begin
        GetDeliveryAppSetup(lGwsDelAppSetup);
        if lGwsDelAppSetup."Mail Invoice" then begin
            lInvoiceHead.Reset();
            lInvoiceHead.SetRange(Auftragsnummer, pOrderHead."Nr.");
            if lInvoiceHead.FindFirst() then begin
                lPrintRec.VerkRechKopfMailen(lInvoiceHead);
            end;
        end;
    end;

    local procedure DeleteOrderInTable(pOrderHead: Record Verkaufskopf)
    var
        lDelAppOrderHead: Record "GWS Delivery App Orderhead";
    begin
        lDelAppOrderHead.Reset();
        if lDelAppOrderHead.Get(pOrderHead."Nr.") then begin
            if not lDelAppOrderHead.Delete() then
                Err.Throw(Strsubstno(Err.ERR_DELETE(), 'Verkaufskopf ', pOrderHead."Nr."));

        end;
    end;

    local procedure CheckBooking(var pOrderHead: Record Verkaufskopf): Boolean
    var
        lGwsDelAppSetup: Record "GWS Delivery App Setup";
        lOk: Boolean;
    begin
        lOk := false;
        GetDeliveryAppSetup(lGwsDelAppSetup);
        if lGwsDelAppSetup."Post Delivery" then begin
            pOrderHead.Validate(Lieferung, true);
            lOk := true;
        end;
        if lGwsDelAppSetup."Post Invoice" then begin
            pOrderHead.Validate(Rechnung, true);
            lOk := true;
        end;
        exit(lOk);
    end;

    procedure GetOrderLineAndHead(var pOrderHead: Record Verkaufskopf; var pOrderLine: Record Verkaufszeile; lNo: Code[20]; lLineNr: Integer)
    var
        NotFoundError: Label 'Error: Es konnte der Auftrag mit der Nummer: %1 nicht gefunden werden.';
    begin
        pOrderHead.Reset();
        if not pOrderHead.Get(pOrderHead.Belegart::Auftrag, lNo) then
            Err.Throw(StrSubstNo(NotFoundError, lNo));

        pOrderLine.Reset();
        if not pOrderLine.Get(pOrderLine.Belegart::Auftrag, lNo, lLineNr) then
            Err.Throw(StrSubstNo(NotFoundError, lNo));
    end;

    procedure CheckQuantityDifference(pQuantity: Decimal; pOrderLine: Record Verkaufszeile): Boolean
    var
        lDeliveryAppSetup: Record "GWS Delivery App Setup";
        lDiff: Decimal;
    begin
        lDiff := pQuantity / pOrderLine.Menge;
        GetDeliveryAppSetup(lDeliveryAppSetup);
        if (lDiff < (1 - lDeliveryAppSetup."Percentage of Quantity Diff." / 100)) or (lDiff > (1 + lDeliveryAppSetup."Percentage of Quantity Diff." / 100)) then
            exit(true);
        exit(false);
    end;

    procedure GetDeliveryAppSetup(var lDeliveryAppSetup: Record "GWS Delivery App Setup")
    var
        CouldNotGetSetup: Label 'Error: Die Delivery App Einrichtung konnte nicht gefunden werden';
    begin
        if not lDeliveryAppSetup.FindFirst() then
            Err.Throw(CouldNotGetSetup);
    end;

    procedure UpdateNewFields(var pOrderHead: Record Verkaufskopf)
    var
        lInvoiceHead: Record Verkaufsrechnungskopf;
        lDeliveryHead: Record Verkaufslieferkopf;
    begin
        lInvoiceHead.Reset();
        lInvoiceHead.SetRange(Auftragsnummer, pOrderHead."Nr.");
        if lInvoiceHead.FindFirst() then begin
            lInvoiceHead.Validate("Status Update from App", pOrderHead."Status Update from App");
            lInvoiceHead.Validate("Receipt Picture", pOrderHead."Receipt Picture");
            if not lInvoiceHead.Modify() then begin
                Err.Throw(Strsubstno(Err.ERR_MODIFY(), lInvoiceHead."Nr.", pOrderHead."Nr."));
            end;
        end;

        lDeliveryHead.Reset();
        lDeliveryHead.SetRange(Auftragsnummer, pOrderHead."Nr.");
        if lDeliveryHead.FindFirst() then begin
            lDeliveryHead.Validate("Status Update from App", pOrderHead."Status Update from App");
            lDeliveryHead.Validate("Receipt Picture", pOrderHead."Receipt Picture");
            if not lDeliveryHead.Modify() then begin
                Err.Throw(Strsubstno(Err.ERR_MODIFY(), lDeliveryHead."Nr.", pOrderHead."Nr."));
            end;
        end;
    end;

    var
        Err: Codeunit ErrorHandler;

}