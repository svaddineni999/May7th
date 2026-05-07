import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getFields from '@salesforce/apex/PC_DataTable.getFields';
import errorMissingProgramCase from '@salesforce/label/c.PC_MissingProgramCase';
import successSave from '@salesforce/label/c.PC_Save_Toast';
import { refreshApex } from '@salesforce/apex';
import toastSuccessTitle from '@salesforce/label/c.PC_Toast_Title_Success';
import toastErrorTitle from '@salesforce/label/c.PC_Toast_Title_Error';

export default class PC_RecordForm extends NavigationMixin(LightningElement) {
    @api recordId;
    @api childProgramId;
    @api namespacePrefix;
    @api objectName = this.namespacePrefix+'PC_Order__c';
    @api layoutType = 'Full';
    @api viewMode = 'view';
    @api fieldSet;
    @api newResultSet;
    @api fieldList = [];
    @api fieldListMap = [];
    @track fieldMapWithIndex = [];
    @track lightningForm_Rows;
    @track lightningForm_Columns;
    @track noOfItemsInARow = 2;
    @api columnValue = [1,2,3];
    @api shipTo;
    @api shipToValue;
    @api programCaseId;
    @api associationMap;
    @api associationValue;
    @api existingShipToValue;
    @api customError;
    @api currentStage;
    @api tileLabel;

    @api
    handleApexRefresh(event){
        refreshApex(this.newResultSet);
    }


    connectedCallback(){        
        if(this.fieldSet === undefined ){
                this.fieldSet = this.namespacePrefix+'PC_OrderDetails';
        }
            this.objectName = this.namespacePrefix+'PC_Order__c';
    }

    selectionChangeHandler(event){
        this.shipToValue =  event.target.value;
        if(this.associationMap[this.shipToValue]){
            this.associationValue = this.associationMap[this.shipToValue];
        }else{
            this.associationValue = '';
        }

    }

    showToast(title, variant, mode, errorMessage) {
        const event = new ShowToastEvent({
            title: title,
            message: errorMessage,
            variant : variant,
            mode : mode,
        });
        this.dispatchEvent(event);
    }

    handleChange(event){
        var eventFieldValue = event.detail.value;
        var presciptionFieldValue;
        var caseFieldValue;
        var prescriptionFieldSetField;
        var programCaseFieldSetField;

        prescriptionFieldSetField = this.namespacePrefix+'PC_Prescription__c';
        programCaseFieldSetField = this.namespacePrefix+'PC_ProgramCase__c';

        if(this.template.querySelector('[data-id="'+prescriptionFieldSetField+'"]')){
            presciptionFieldValue = this.template.querySelector('[data-id="'+prescriptionFieldSetField+'"]').value;
        }

        if(this.template.querySelector('[data-id="'+programCaseFieldSetField+'"]')){
            caseFieldValue = this.template.querySelector('[data-id="'+programCaseFieldSetField+'"]').value;
        }

        if(presciptionFieldValue){
            if(eventFieldValue == presciptionFieldValue){
                this.dispatchEvent(new CustomEvent('selectedprscription', { detail: presciptionFieldValue }));
            }
        }

        if(caseFieldValue){
           if(eventFieldValue == caseFieldValue){
            this.dispatchEvent(new CustomEvent('selectedprogramcase', { detail: caseFieldValue }));
           }
        }

        if(caseFieldValue == ''){
            this.dispatchEvent(new CustomEvent('selectedprogramcase', { detail: caseFieldValue }));
            this.dispatchEvent(new CustomEvent('clearproductdata'));
        }

        if(presciptionFieldValue == ''){
            this.dispatchEvent(new CustomEvent('selectedprscription', { detail: presciptionFieldValue }));
            this.dispatchEvent(new CustomEvent('clearprescriptiondata'));
        }
    }

    @wire(getFields, { fsname: '$fieldSet', recordIdString:'$recordId'})
    wiredGetFieldList(value) {
        this.newResultSet = value;
        const { data, error } = value;
        if (data) {
            this.fieldList = this.newResultSet.data.fieldList;
            this.shipTo = this.newResultSet.data.shipToValues;
            this.associationMap = this.newResultSet.data.associationMap;
            this.existingShipToValue = this.newResultSet.data.existingShipToValue;
            this.createFieldListMap();
            if(this.childProgramId != 'undefined' && this.childProgramId != null && this.childProgramId != '')
                this.programCaseId = this.childProgramId;
            if(this.newResultSet.data.existingProgramCaseValue != 'undefined' && this.newResultSet.data.existingProgramCaseValue != null && this.newResultSet.data.existingProgramCaseValue != '')
                this.programCaseId = this.newResultSet.data.existingProgramCaseValue;
        }
        else if (error) {
             console.log('Error'+JSON.stringify(error));
             // UI API read operations return an array of objects
            if (Array.isArray(error.body)) {
                this.customError = error.body.map(e => e.message).join(', ');
            }
            // UI API write operations, Apex read and write operations
            // and network errors return a single object
            else if (typeof error.body.message === 'string') {
                this.customError = error.body.message;
            }
             this.showToast(toastErrorTitle, 'error', 'sticky', this.customError);
            }
    }

    createFieldListMap(){
        var fList = this.fieldList;
        var temp = [];
    
        fList.forEach(f =>{            
            if(f.fieldName == this.namespacePrefix+'PC_ProgramCase__c'){
                temp.push({field : f.fieldName, showProgramCase : true, show1 : false, show2 : false, show3 : false, fieldLabel : f.label});
            }else if(f.fieldName == this.namespacePrefix+'PC_ShipTo2__c'){
                temp.push({field : f.fieldName, showProgramCase : false, show1 : true, show2 : false, show3 : false, fieldLabel : f.label});
            }else if(f.fieldName == this.namespacePrefix+'PC_ShipTo__c'){
                temp.push({field : f.fieldName , showProgramCase : false, show1 : false, show2 : true, show3 : false, fieldLabel : f.label});
            }else{
                temp.push({field : f.fieldName , showProgramCase : false, show1 : false, show2 : false, show3 : true, fieldLabel : f.label});
            }

        })
        this.fieldListMap = temp;
    }

    navToRecordPage(recordCreated){
        this.orderHomePageRef = {
            type: 'standard__recordPage',
            attributes: {
                recordId: recordCreated,
                actionName: 'view'
            }
        };
        this[NavigationMixin.Navigate](this.orderHomePageRef)
    }

    @api
    callSubmit(event, stage){
        this.currentStage = stage;
        var programCaseFieldSetField;
        
        programCaseFieldSetField = this.namespacePrefix+'PC_ProgramCase__c';
        
        if(stage == 1){
            if(this.template.querySelector('[data-id="'+programCaseFieldSetField+'"]')){
                if((this.template.querySelector('[data-id="'+programCaseFieldSetField+'"]').value)){
                    event.preventDefault();
                    this.template.querySelector('lightning-record-edit-form').submit();
                }else{
                    this.showToast(toastErrorTitle, 'error', 'sticky',errorMissingProgramCase);
                }
            }else{
                this.showToast(toastErrorTitle, 'error', 'sticky','Add Program field to field set');
            }
        }else if(stage == 2){
            event.preventDefault();
            this.template.querySelector('lightning-record-edit-form').submit();
            //this.handleApexRefresh(event);

        }

        var cmp = this.template.querySelector('lightning-record-edit-form');
    }

    handleSubmit(event){
        event.preventDefault();
        const fields = event.detail.fields;
    }


    handleSuccess(event){
        this.showToast(toastSuccessTitle, 'success', 'dismissable', successSave);
        this.handleApexRefresh(event);
        if(this.currentStage == 1){
            var orderCreatedId = event.detail.id;
            var orderCreatedNumber = event.detail.fields.Name.value;
            //this.navToRecordPage(orderCreatedId);
            this.dispatchEvent(new CustomEvent('ordercreated', { detail: {orderCreatedId : orderCreatedId, orderCreatedNumber: orderCreatedNumber}}));
        }else if(this.currentStage == 2){
        }
 
    }    
}