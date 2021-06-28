codeunit 51780 "GWS Delivery App Mgmt"
{
    trigger OnRun()
    begin

    end;

    [EventSubscriber(ObjectType::Table, 36, 'OnAfterModifyEvent', '', false, false)]
    procedure Subscriber_T36_OnAfterModify(Rec: Record Verkaufskopf; xRec: Record Verkaufskopf)
    var
        lDeliveryHead: Record Verkaufslieferkopf;
        lInvoiceHead: Record Verkaufsrechnungskopf;
    begin
        if Rec."Anzahl Änderungen Vorl. Lief." >= 0 then begin
            if ((Rec."Buchungsnr." <> '') and (not lInvoiceHead.Get(Rec."Buchungsnr."))
                or (Rec."Lieferungsnr." <> '') and (not lDeliveryHead.Get(Rec."Lieferungsnr."))) then begin
                BeforePost(Rec);
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, 36, 'OnAfterDeleteEvent', '', false, false)]
    procedure Subscriber_T36_OnAfterDelete(Rec: Record Verkaufskopf)
    var
        lAppDeliveryHead: Record "GWS Delivery App Orderhead";
    begin
        if lAppDeliveryHead.Get(Rec."Nr.") then begin
            BeforeDelete(Rec);
        end;
    end;

    local procedure BeforePost(pOrderHead: Record Verkaufskopf)
    var
        lArticle: Record Artikel;
        lArticleEnergy: Record "Artikel für Energieverkauf";
        lOrderLine: Record Verkaufszeile;
    begin
        if pOrderHead.Belegart = pOrderHead.Belegart::Auftrag then begin
            lOrderLine.SetRange("Belegnr.", pOrderHead."Nr.");
            lOrderLine.SetRange(Belegart, pOrderHead.Belegart);
            repeat
                if lOrderLine.Find('-') then begin
                    if lOrderLine.Art = lOrderLine.Art::Artikel then begin
                        lArticleEnergy.SetRange("Artikelnr.", lOrderLine."Nr.");
                        if lArticleEnergy.FindFirst() then begin
                            if lArticleEnergy.Dispositionsartikel then begin
                                PostNewOrder(pOrderHead, lOrderLine);
                            end;
                        end;
                    end;
                end;
            until lOrderline.Next() = 0;
        end else
            exit;
    end;

    local procedure PostNewOrder(pOrderHead: Record Verkaufskopf; pOrderLine: Record Verkaufszeile)
    var
        lDeliveryAppSetup: Record "GWS Delivery App Setup";
        lClient: HttpClient;
        lContent: HttpContent;
        lResponseMessage: HttpResponseMessage;
        lStream: InStream;
        lJsArray: JsonArray;
        lJsObject: JsonObject;
        lJsText: Text;
        lResponse: Text;
        lUrl: Text;
        ServiceResponseNotReadableErr: Label 'Error in Servicecall: The response of the service is not readable.';
        ServiceResponseNoJsonErr: Label 'Error in Servicecall: The response of the service is invalid: %1';
        ServiceErrorCode: Label 'Error in Servicecall: HTTP error code %1';
    begin
        if not (CheckIfExists(pOrderHead)) then begin
            GetDeliveryAppSetup(lDeliveryAppSetup);
            lJsObject := CreateJsonObjectHead(pOrderHead, pOrderLine);
            //lClient.DefaultRequestHeaders.Add('x-functions-key', 'HA8nagasU6D5kV7GIcaag8a4to/8k7JNRNmeRxkWeRMumc2pPKfaYg==');
            lClient.DefaultRequestHeaders.Add('x-functions-key', lDeliveryAppSetup."Azure SQL DB Api Key");
            lJsObject.WriteTo(lJsText);
            lContent.WriteFrom(lJsText);

            //lUrl := 'https://deliveryappgws.azurewebsites.net/api/postOrder?';
            lUrl := lDeliveryAppSetup."Azure SQL DB Base Adress";
            if not lClient.Post(lUrl, lContent, lResponseMessage) then
                exit;

            if not lResponseMessage.IsSuccessStatusCode() then
                Err.Throw(StrSubstNo(ServiceErrorCode, lResponseMessage.HttpStatusCode));

            if not lResponseMessage.Content().ReadAs(lResponse) then
                Err.Throw(ServiceResponseNotReadableErr);
        end else
            exit;
    end;

    procedure CreateJsonObjectHead(pOrderHead: Record Verkaufskopf; pOrderLine: Record Verkaufszeile): JsonObject
    var
        lJsObject: JsonObject;
        lOrderLinesObject: JsonObject;
        lJsArrayLines: JsonArray;
    begin
        repeat
            if (pOrderLine."Belegnr." = pOrderHead."Nr.") and (pOrderLine.Belegart = pOrderHead.Belegart) then begin
                lJsArrayLines.Add(CreateJsonObjectLine(pOrderLine));
            end;
        until pOrderLine.Next() = 0;
        lJsObject.add('OrderLines', lJsArrayLines);
        lJsObject.Add('No', Format(pOrderHead."Nr."));
        lJsObject.Add('DebNo', pOrderHead."Verk. an Deb.-Nr.");
        lJsObject.Add('DebName', pOrderHead."Verk. an Name");
        lJsObject.Add('DebName2', pOrderHead."Verk. an Name 2");
        lJsObject.Add('Barcode', Format(GenerateBarcode(pOrderHead)));
        exit(lJsObject);
    end;

    procedure CreateJsonObjectLine(pOrderLine: Record Verkaufszeile): JsonObject
    var
        lJsToken: JsonToken;
        lJsObject: JsonObject;
    begin
        lJsObject.Add('LinesID', Format(pOrderLine."Zeilennr."));
        lJsObject.Add('Amount', pOrderLine.Menge);
        lJsObject.Add('ArticleDescription', pOrderLine.Beschreibung);
        lJsObject.Add('ArticleDescription2', pOrderLine."Beschreibung 2");
        lJsObject.Add('ArticleDescription3', pOrderLine."Beschreibung 3");
        lJsObject.Add('ArticleNo', pOrderLine."Nr.");
        exit(lJsObject);
    end;

    procedure GenerateBarcode(pOrderHead: Record Verkaufskopf): Code[30]
    var
        lGWSVerw: Codeunit GWSVerwaltung;
        lDelNo: Code[20];
        lBarcode: Code[30];
    begin
        if pOrderHead."Lieferungsnr." <> '' then
            lDelNo := pOrderHead."Lieferungsnr."
        else
            lDelNo := pOrderHead."Buchungsnr.";
        lDelNo := lGWSVerw.EntfernePunktAmEnde(lDelNo);
        exit(lGWSVerw.genStrichcode39(lDelNo + '26'));
    end;

    local procedure CheckIfExists(pOrderHead: Record Verkaufskopf): Boolean
    var
        lAppOrderHead: Record "GWS Delivery App Orderhead";
    begin
        if not (lAppOrderHead.Get(pOrderHead."Nr.")) then begin
            lAppOrderHead.No := pOrderHead."Nr.";
            lAppOrderHead."Debitor No." := pOrderHead."Verk. an Deb.-Nr.";
            lAppOrderHead."Debitor Name" := pOrderHead."Verk. an Name";
            lAppOrderHead."Debitor Name 2" := pOrderHead."Verk. an Name 2";
            if not lAppOrderHead.Insert() then exit(false);
        end else
            exit(true);
    end;

    local procedure GetDeliveryAppSetup(var pDeliveryAppSetup: Record "GWS Delivery App Setup")
    var
        CouldNotGetSetup: Label 'Error: Die Delivery App Einrichtung konnte nicht gefunden werden';
    begin
        if not pDeliveryAppSetup.FindFirst() then
            Err.Throw(CouldNotGetSetup);
    end;

    local procedure BeforeDelete(pOrderHead: Record Verkaufskopf)
    var
        lJsToken: JsonToken;
        lJsObject: JsonObject;
    begin
        lJsObject.Add('No', pOrderHead."Nr.");
        DeleteOrderInTable(pOrderHead);
        DeleteOrder(lJsObject);
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

    local procedure DeleteOrder(lJsObject: JsonObject)
    var
        lDeliveryAppSetup: Record "GWS Delivery App Setup";
        lAppOrderHead: Record "GWS Delivery App Orderhead";
        lClient: HttpClient;
        lContent: HttpContent;
        lResponseMessage: HttpResponseMessage;
        lStream: InStream;
        lJsArray: JsonArray;
        lJsText: Text;
        lResponse: Text;
        lUrl: Text;
        ServiceResponseNotReadableErr: Label 'Error in Servicecall: The response of the service is not readable.';
        ServiceResponseNoJsonErr: Label 'Error in Servicecall: The response of the service is invalid: %1';
        ServiceErrorCode: Label 'Error in Servicecall: HTTP error code %1';
    begin
        GetDeliveryAppSetup(lDeliveryAppSetup);
        //lClient.DefaultRequestHeaders.Add('x-functions-key', 'HA8nagasU6D5kV7GIcaag8a4to/8k7JNRNmeRxkWeRMumc2pPKfaYg==');
        lClient.DefaultRequestHeaders.Add('x-functions-key', lDeliveryAppSetup."Deleted Orders Api Key");
        lJsObject.WriteTo(lJsText);
        lContent.WriteFrom(lJsText);

        //lUrl := 'https://deliveryappgws.azurewebsites.net/api/deleteOrder';
        lUrl := lDeliveryAppSetup."Deleted Orders Base Adress";
        if not lClient.Put(lUrl, lContent, lResponseMessage) then
            exit;

        if not lResponseMessage.IsSuccessStatusCode() then
            Err.Throw(StrSubstNo(ServiceErrorCode, lResponseMessage.HttpStatusCode));

        if not lResponseMessage.Content().ReadAs(lResponse) then
            Err.Throw(ServiceResponseNotReadableErr);
    end;

    var
        Err: Codeunit ErrorHandler;

}