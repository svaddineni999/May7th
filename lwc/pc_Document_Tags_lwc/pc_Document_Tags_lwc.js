/*
Created by Xiukai Ning on 12/20/2019  [PC-5802]
*/

/* eslint-disable no-console */
/* eslint-disable no-debugger */
import { LightningElement, api, wire, track } from 'lwc';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import PC_DOCUMENT_RECORD from '@salesforce/schema/PC_Document__c';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import CAT_FIELD from '@salesforce/schema/PC_Document__c.PC_Document_Category__c';
import RTI_FIELD from '@salesforce/schema/PC_Document__c.RecordTypeId';
import EPC_FIELD from '@salesforce/schema/PC_Document__c.PC_EngagementProgramCode__c';
import ID_FIELD from '@salesforce/schema/PC_Document__c.Id';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent } from 'c/pubsub';
import tagsLabel from '@salesforce/label/c.PC_Document_Tags';

const FIELDS = [CAT_FIELD, RTI_FIELD, EPC_FIELD];

export default class WireGetPicklistValuesByRecordType extends LightningElement {

    @api recordId;
    @track error;
    @track controllingValues = [];
    @track dependentValues = [];
    @track categoryValues;
    @track recordTypeIdValue;
    @track engagementProgramCodeValue
    @track cssClass = 'slds-show rtc-div';
    @track iconName = 'utility:chevrondown';
    controlValues;
    totalDependentValues  = [];
    //Accordion expanded by default
    accordionExpand = true;

    label = {
        tagsLabel
    };

    //Wired to leverage pubsub
    @wire(CurrentPageReference) pageRef;

    //Get current Document record
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredDocument({ error, data }) {
        if (data){
            this.categoryValues = getFieldValue(data, CAT_FIELD)==null? [] : getFieldValue(data, CAT_FIELD).split(";");
            this.recordTypeIdValue = getFieldValue(data, RTI_FIELD);
            this.engagementProgramCodeValue = getFieldValue(data, EPC_FIELD)==null? 'None' : getFieldValue(data, EPC_FIELD);
        } else if(error){
            let message = 'Unknown error';
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error loading Document record',
                    message,
                    variant: 'error',
                }),
            );
        }
    }

    //Get picklist metadata
    @wire(getPicklistValuesByRecordType, {
        objectApiName: PC_DOCUMENT_RECORD,
        recordTypeId: '$recordTypeIdValue'
    })
    wiredValues({ error, data }) {
        if (data) {
            this.dependentValues = this.buildPicklistDependency(data.picklistFieldValues);
            this.error = undefined;
        } else if(error){
            this.error = error;
            this.dependentValues = undefined;
            let message = 'Unknown error';
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error loading Document picklists',
                    message,
                    variant: 'error',
                }),
            );
        }
    }

    //Associate controlling field with dependent picklist
    buildPicklistDependency(picklistValues) {
        let engagementProgram = [];
        picklistValues[CAT_FIELD.fieldApiName].values.forEach(key => {
            engagementProgram.push({
                label : key.label,
                value: key.value
            })
        });
        this.controllingValues = engagementProgram;

        this.controlValues = picklistValues[CAT_FIELD.fieldApiName].controllerValues;
        console.log(JSON.stringify(this.controlValues));

        this.totalDependentValues = picklistValues[CAT_FIELD.fieldApiName].values;
        //PC-6584: Commented as this is not being used anywhere
        /*let category =[];
        this.totalDependentValues.forEach(key => {
            category.push({
                label : key.label,
                value: key.value,
                isSelected: false
            })
        });*/

        console.log(JSON.stringify(this.totalDependentValues));
        let dependValues = [];
        this.totalDependentValues.forEach(conValues => {
            if(conValues.validFor.includes(this.controlValues[this.engagementProgramCodeValue])) {
                dependValues.push({
                    label: conValues.label,
                    value: conValues.value,
                    isSelected: false
                })
            }
        })

        dependValues.forEach(objectEle =>{
            if (this.categoryValues.includes(objectEle.value)){
                objectEle.isSelected = true;
            }
            else{
                objectEle.isSelected = false;
            }
        })

        return dependValues;
    }

    handleBadgeClick(event) {
        let categoryToSave =[];
        let targetTag;
        let targetTagStatus;
        this.dependentValues.forEach(objectEle =>{
            if (objectEle.value ===  event.target.dataset.id){
                objectEle.isSelected = !objectEle.isSelected;
                targetTag = event.target.dataset.id;
                targetTagStatus =  objectEle.isSelected;
            }
        })

        this.dependentValues.forEach(objectEle =>{
            if (objectEle.isSelected===true){
                    categoryToSave.push(objectEle.value);
            }
        })

        let categoryString = categoryToSave.join(';');
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[CAT_FIELD.fieldApiName] = categoryString;
        const record = { fields };

        updateRecord(record)
        .then(() => {
            if (targetTag){
                fireEvent(this.pageRef, 'documenttagupdateevent', 
                {detail:{'documentId': this.recordId,
                "selectedCategory": targetTag,
                "selectedCategoryStatus" : targetTagStatus }});
            }
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error on saving tags',
                    message: error,
                    variant: 'error',
                }),
            );
        });
    }

    showAccordion(){
        this.accordionExpand = !this.accordionExpand;
        this.cssClass =this.accordionExpand ? 'slds-show rtc-div' : 'slds-hide';
        this.iconName = this.accordionExpand ? 'utility:chevrondown' : 'utility:chevronright';
    }
}