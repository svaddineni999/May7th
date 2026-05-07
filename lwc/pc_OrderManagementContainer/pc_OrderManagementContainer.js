import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import errorWrongPrescriptionProduct from '@salesforce/label/c.PC_WrongPrescriptionProduct';
import backButtonLabel from '@salesforce/label/c.PC_Back';
import nextButtonLabel from '@salesforce/label/c.PC_Next';
import saveButtonLabel from '@salesforce/label/c.PC_Save';
import saveWarning from '@salesforce/label/c.PC_SaveWarning';
import OrderDetailsTile from '@salesforce/label/c.PC_OrderDetailsTile';
import ShippingDetailsTile from '@salesforce/label/c.PC_ShippingDetailsTile';
import toastSuccessTitle from '@salesforce/label/c.PC_Toast_Title_Success';
import toastErrorTitle from '@salesforce/label/c.PC_Toast_Title_Error';


export default class Pc_OrderManagementContainer_lwc extends LightningElement {
    @api recordId;
    @api programId;
    @api prescriptionId = '';
    @api currentStep = 1;
    @api currentValue = 'step1';
    @api fsOrderDetails;
    @api fsProduct;
    @api fsOrderItem;
    @api fsOrderShipment;
    @api refreshRecordEditForm = false;
    @track step1 = true;
    @track step2 = false;
    @track disabledBack = true;
    @track disabledNext = true;
    @api namespace;
    @api namespacePrefix;
    @api showAllProduct = false;
    @api prescriptionUnavailable = false;
    @track backbutton = backButtonLabel;
    @track nextbutton = nextButtonLabel;
    @track savebutton = saveButtonLabel;
    @track warningMessage = saveWarning;

    label = {
        OrderDetailsTile,
        ShippingDetailsTile,
};


    connectedCallback(){
        this.programId = (this.programId != undefined && this.programId != null) ? this.programId : ' ';
        var templateHost = this.template.host;
        var templateHostString = String(templateHost);
        var namespaceString = eval('(' + templateHostString.substr(templateHostString.indexOf("{"),templateHostString.lastIndexOf("}")) + ')');
        var namespaceJSON = JSON.parse(JSON.stringify(namespaceString))
        this.namespace = namespaceJSON.key.namespace;
        this.namespacePrefix =  (this.namespace != undefined && this.namespace != null && this.namespace != '' && this.namespace!='c') ?  this.namespace+'__' : '';        
        this.fsOrderDetails = (this.fsOrderDetails != undefined && this.fsOrderDetails != null && this.fsOrderDetails != '') ? this.fsOrderDetails : (this.namespacePrefix+'PC_OrderDetails');
        this.fsProduct = (this.fsProduct != undefined && this.fsProduct != null && this.fsProduct != '') ? this.fsProduct : (this.namespacePrefix+'PC_Product');
        this.fsOrderItem = (this.fsOrderItem != undefined && this.fsOrderItem != null && this.fsOrderItem != '') ? this.fsOrderItem : (this.namespacePrefix+'PC_OrderItems');
        this.fsOrderShipment = (this.fsOrderShipment != undefined && this.fsOrderShipment != null && this.fsOrderShipment != '') ? this.fsOrderShipment : (this.namespacePrefix+'PC_OrderShipment');
        if(this.recordId){
            if(this.currentStep == 1){
                this.disabledNext = false;
                this.disabledBack = true;
            }else if (this.currentStep == 2){
                this.disabledNext = true;
                this.disabledBack = false;
            }
        }
    }

    @api
    handleSelectedProgramCase(event) {
        const newRecordId = event.detail;
        //this.programId = newRecordId;
        this.template.querySelector('c-pc_-data-table').handleProgramRefresh(newRecordId);
    }

    @api
    handleSelectedPrescription(event) {
        const newRecordId = event.detail;
        //this.prescriptionId = newRecordId;
        this.template.querySelector('c-pc_-data-table').handlePrescriptionRefresh(newRecordId);
    }

    @api
    clearProductData(event) {
        this.template.querySelector('c-pc_-data-table').clearProductData();
    }

    @api
    clearPrescriptionData(event) {
        this.template.querySelector('c-pc_-data-table').clearPrescriptionData();
    }

    @api
    refreshLightningParent(event) {
        const refreshLightningParent = event.detail.refreshParent;
        this.recordId = event.detail.orderId;
        if(refreshLightningParent) {
            this.template.querySelector('c-pc_-record-edit-form').recordId = this.recordId;
            this.template.querySelector('c-pc_-record-edit-form').handleApexRefresh(event);
        }
    }

    @api
    handleBack(event) {
        this.currentStep = this.currentStep - 1;
        if(this.currentStep == 1){
            this.step1 = true;
            this.step2 = false;
            this.currentValue = 'step1';
            this.disabledNext = false;
            this.disabledBack = true;
        }else if (this.currentStep == 2){
            this.step1 = false;
            this.step2 = true;
            this.currentValue = 'step2';
            this.disabledNext = true;
            this.disabledBack = false;    
        }
    }

    showToast(title, variant, mode, errorMessage) {
        const event = new ShowToastEvent({
            title: title,
            message: String(errorMessage),
            variant : variant,
            mode : mode,
        });
        this.dispatchEvent(event);
    }

    @api
    stopSave(event){
        this.prescriptionUnavailable = event.detail;
        console.log('@@Stop Saving prescription Unavailbale' + this.prescriptionUnavailable);
    }

    @api
    handleOrderSave(event) {
        if(this.prescriptionUnavailable){
            this.showToast(toastErrorTitle, 'error', 'sticky', errorWrongPrescriptionProduct);
        }else{
            var stage = this.currentStep;
            this.template.querySelector('c-pc_-record-edit-form').callSubmit(event, stage);
        }
    }

    @api
    handleOrderItemCreation(event) {
        var orderCreatedId = event.detail.orderCreatedId;
        var orderCreatedNumber = event.detail.orderCreatedNumber;
        var close = true;
        const closeclickedevt = new CustomEvent('closeclicked', {
            detail: {
                    close: true,
                    orderIdCreated :orderCreatedId,
                    orderNumberCreated : orderCreatedNumber
            }
        });
         //Fire the custom event
        this.dispatchEvent(closeclickedevt);
        this.template.querySelector('c-pc_-data-table').handleSave(event); //Moved to event thrown by Order Save

        if(this.step1){
            this.disabledNext = false;
            this.disabledBack = true;    
        }else if(this.step2){
            this.disabledNext = true;
            this.disabledBack = false;
        }
    }
    

    @api
    handleNext(event) {
        //this.handleOrderSave(event);
        this.currentStep = this.currentStep + 1;
        if(this.currentStep == 1){
            this.step1 = true;
            this.step2 = false;
            this.currentValue = 'step1';
            this.disabledNext = false;
            this.disabledBack = true;
        }else if (this.currentStep == 2){
            this.step1 = false;
            this.step2 = true;
            this.currentValue = 'step2';
            this.disabledNext = true;
            this.disabledBack = false;    
        }
    }
}