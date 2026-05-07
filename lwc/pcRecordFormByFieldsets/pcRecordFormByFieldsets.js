import { LightningElement, api, track } from 'lwc';
import { normalizeString, normalizeRecordId, densityValues } from 'c/pcUtils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

/* Custom Labels */
import LOADING from '@salesforce/label/c.PC_Loading';
import SAVE from '@salesforce/label/c.PC_Save';
import CANCEL from '@salesforce/label/c.PC_Button_Label_Cancel';
import TOAST_TITLE_SUCCESS from '@salesforce/label/c.PC_Toast_Title_Success';
import TOAST_TITLE_ERROR from '@salesforce/label/c.PC_Toast_Title_Error';
import SAVE_TOAST_MSG from '@salesforce/label/c.PC_Save_Toast';

/* Apex Class */
import getFields from '@salesforce/apex/PC_FieldSetFormController.getFields';

export default class PC_RecordFormByFieldsets extends LightningElement {
    @api objectApiName;
    @api recordTypeId;
    @api lastModifiedDateRequired = false;
    @track showSaveButton;

    @track _recordId;
    @track _fieldSetNames;
    @track _loading = true;
    @track cols = 2;
    @track fieldSetsData;
    @track _density = densityValues.AUTO;
    @track errors = new Map();


    _labelLoading = LOADING;
    _labelSave = SAVE;
    _labelCancel = CANCEL;
    _labelError = TOAST_TITLE_ERROR;
    _firstLoad = true;
    _loadedPending = false;
    _defaultFieldValues = {};
    columnProperty;


    connectedCallback(){
        getFields({sObjectName: this.objectApiName, fieldSetNames: this._fieldSetNames })
            .then(result => {
                this.fieldSetsData = result;
                this.metadataError = undefined;
            }).catch(error => {
                this.template.querySelector('lightning-messages').setError(error);
                this._loading = false;
                this.showSaveButton = false;
                this.fieldSetsData = undefined;
        });
        this.columnProperty = "slds-p-horizontal_small slds-size_1-of-1 slds-medium-size_1-of-"+ this.columns +" slds-large-size_1-of-" + this.columns;
    }

    set recordId(val) {
        this._recordId = normalizeRecordId(val);
    }

    @api get recordId() {
        return this._recordId;
    }

    addFieldSet(val) {
        const fieldSetName = val;
        if (!this._dupMapper[fieldSetName]) {
            this._fieldSetNames.push(fieldSetName);
            this._dupMapper[fieldSetName] = true;
        }
    }

    set fieldSetNames(val) {
        this._fieldSetNames = [];
        this._dupMapper = {};
        if(!!val) {
            if (Array.isArray(val)) {
                for (let i = 0; i < val.length; i++) {
                    this.addFieldSet(val[i]);
                }
            } else if(val.split(',').length){
                var fieldSetNamesTemp = val.split(',').map((fld) => fld.trim());
                fieldSetNamesTemp.forEach((fieldSetName) => {
                    this.addFieldSet(fieldSetName);
                });
            } else {
                this.addFieldSet(val);
            }
        }
    }

    @api
    get fieldSetNames() {
        return this._fieldSetNames;
    }

    set columns(val) {
        this.cols = parseInt(val, 10);
        if (isNaN(this.cols) || this.cols < 1) {
            this.cols = 1;
        }
        this.cols = (this.cols > 8) ? 2 : this.cols;
    }

    @api get columns() {
        return this.cols;
    }

    get computedInputClass() {
        if (this.cols === 1) {
            return 'slds-form-element_1-col';
        }
        return '';
    }

    @api get density() {
        return this._density;
    }

    set density(val) {
        this._density = normalizeString(val, {
            fallbackValue: densityValues.AUTO,
            validValues: [
                densityValues.AUTO,
                densityValues.COMPACT,
                densityValues.COMFY
            ]
        });
    }

    @api get defaultFieldValues() {
        return this._defaultFieldValues;
    }

    set defaultFieldValues(val) {
        if(val == null){
            val = {}
        }
        this._defaultFieldValues = val;
        if(!this.recordId && Object.keys(this._defaultFieldValues).length){
            const cmps = this.getInputFieldComponents();
            this.setDefaultFieldValues(cmps);
        }
    }

    get _sections() {
        const out = [];

        if (!this.fieldSetsData) {
            return out;
        }
        let sectionKey = 0;
        let sections = this.fieldSetsData.length ? this.fieldSetsData : [];
        let thisSection = { fields: [], heading: '', key: sectionKey };
        sections.forEach((section) => {
            thisSection.heading = section.fieldSetLabel;
            section.fieldSetFields.forEach((fieldSetField) => {
                const required = fieldSetField.required;
                const fieldApiName = fieldSetField.apiName;
                const updateable = fieldSetField.isUpdateable;
                //const defaultValue = ''; !this.recordId ? (this._defaultFieldValues[fieldSetField.apiName] ? this._defaultFieldValues[fieldSetField.apiName] : '') : '';
                thisSection.fields.push({
                                    fieldApiName,
                                    required,
                                    updateable,
                                    //defaultValue
                                });
            });
            out.push(thisSection);
            thisSection = { fields: [], heading: '', key: ++sectionKey };
        });
        return out;
    }

    handleLoad(e) {
        e.stopPropagation();
        if (this._firstLoad) {
            this._loading = false;
            this._firstLoad = false;
        }
        if (this._loadedPending) {
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => {
                this._loading = false;
                this._loadedPending = false;
            }, 0);
        }
        const cmps = this.getInputFieldComponents();
        if(!this.recordId && Object.keys(this._defaultFieldValues).length){
            this.setDefaultFieldValues(cmps);
        }
    }

    handleSubmit(event) {
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            this._loading = !event.defaultPrevented;
        }, 0);
    }

    handleSuccess(e) {
        e.stopPropagation();
        this.recordId = e.detail.id;
        this._loading = false;
        this._loadedPending = true;
        this.showToastEvent( TOAST_TITLE_SUCCESS, SAVE_TOAST_MSG , 'success');
        this.dispatchEvent(
            new CustomEvent('success', {
                detail: e.detail
            })
        );
    }

    handleError(e) {
        e.stopPropagation();
        this._loading = false;
        this.dispatchEvent(
            new CustomEvent('error', {
                detail: e.detail
            })
        );
    }

    @api
    submit(fields) {
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    clearForm() {
        const inputFields = this.template.querySelectorAll('lightning-input-field');
        if (inputFields) {
            inputFields.forEach((field) => {
                field.reset();
            });
        }
    }

    handleCancel(e) {
        this.clearForm();
        this.template.querySelector('lightning-messages').setError(null);
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    setDefaultFieldValues(inputFields){
        inputFields.forEach((field) => {
            if(field.dataset.id) {
                var targetId = field.dataset.id;
                this.template.querySelector(`[data-id="${targetId}"]`).value = this._defaultFieldValues[targetId];
            }
        });
    }

    @api
    setErrors(fieldName, errorMessage){
        let error = {body:{output:{ fieldErrors: {[fieldName] : [{message:errorMessage}]}}}};
        this.errors.set(fieldName,error);
    }

    @api
    validateForm() {
        const cmps = this.getInputFieldComponents();
        return this.validateFormFields(cmps);
    }
    handleChange(event){
        const value = this.getAllFormValues();
        const valueChangeEvent = new CustomEvent("valuechange", {
            detail : {value}
        });
        // Fire the custom event
        this.dispatchEvent(valueChangeEvent);
    }
    getInputFieldComponents() {
        return  [...this.template.querySelectorAll('lightning-input-field')];
    }

    validateFormFields(inputFields) {
        let isValid = true;
        var inputCmp;
        inputFields.forEach((cmp) => {
            if (cmp.tagName === 'LIGHTNING-OUTPUT-FIELD' || !cmp.reportValidity) {
                return;
            }
            if (!cmp.reportValidity()) {
                isValid = false;
            }
            inputCmp = cmp;
            if(this.errors.has(inputCmp.fieldName)) {
                var errors = this.errors.get(inputCmp.fieldName);
                inputCmp.setErrors(errors);
                inputCmp.reportValidity();
            }
        });
        return isValid;
    }

    @api
    getAllFormValues(){
        const fields = JSON.parse(JSON.stringify(this.getFormValues(this.getInputFieldComponents())));
        return fields;
    }

    getFormValues(inputFields) {
        const values = {};
        inputFields.forEach((field) => {
            if (field.readOnly) {
                return;
            }

            if (field.value && typeof field.value === 'object') {
                if (field.value.longitude) {
                    const prefix = field.fieldName.slice(
                        0,
                        field.fieldName.indexOf('__c')
                    );

                    values[prefix + '__Longitude__s'] = field.value.longitude;

                    values[prefix + '__Latitude__s'] = field.value.latitude;
                } else {
                    Object.assign(values, field.value);
                }
            } else {
                values[field.fieldName] = field.value;
            }
        });
        return values;
    }

    // Show a UI Message
    showToastEvent(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(event);
    }
}