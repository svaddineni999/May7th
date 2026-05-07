import { LightningElement, api, track } from 'lwc';
import { normalizeString, normalizeRecordId, deepCopy, densityValues } from 'c/pcUtils';
import {
    getFieldsForLayout,
    getCompoundFields,
    compoundFieldIsUpdateable,
    compoundFieldIsCreateable,
    isCompoundField,
    extractLayoutFromLayouts,
    isPersonAccount,
    UNSUPPORTED_REFERENCE_FIELDS
} from 'c/pcUtils';
import LOADING from '@salesforce/label/c.PC_Loading';
import SAVE from '@salesforce/label/c.PC_Save';
import CANCEL from '@salesforce/label/c.PC_Button_Label_Cancel';

const EDIT_MODE = 'edit';
const VIEW_MODE = 'view';
const READ_ONLY_MODE = 'readonly';
//const MASTER_RECORD_TYPE_ID = '012000000000000AAA';

function isUnsupportedReferenceField(name) {
    return UNSUPPORTED_REFERENCE_FIELDS.indexOf(name) !== -1;
}

export default class PC_RecordForm extends LightningElement {
    @track readOnly = false;
    @track _recordId;
    @track _objectApiName;
    @track _fields = [];
    @track _editMode = false;
    @track cols = 1;
    @track _loading = true;
    @track fieldsReady = false;
    @track _recordTypeId;
    @track _layoutData;

    _record;
    _firstLoad = true;
    _loadError = false;
    _layout;
    _defaultFieldValues = {};
    _dupMapper = {};
    _mode;
    _labelSave = SAVE;
    _labelCancel = CANCEL;
    _labelLoading = LOADING;
    _loadedPending = false;
    _fieldsHandled = false;
    _rawFields;
    _isPersonAccount = false;
    @track _density = densityValues.AUTO;

    set mode(val) {
        val = val.toLowerCase();
        this._mode = val;
        switch (val) {
            case EDIT_MODE:
                this.readOnly = false;
                this._editMode = true;
                break;
            case VIEW_MODE:
                this.readOnly = false;
                this._editMode = false;
                break;
            case READ_ONLY_MODE:
                this.readOnly = true;
                this._editMode = false;
                break;
            default:
                this.readOnly = false;
                if (!this._recordId) {
                    this._editMode = true;
                } else {
                    this._editMode = false;
                }
        }
    }

    @api get mode() {
        return this._mode;
    }

    set layoutType(val) {
        if (val.match(/Full|Compact/)) {
            this._layout = val;
        } else {
            throw new Error(
                `Invalid layout "${val}". Layout must be "Full" or "Compact"`
            );
        }
    }

    @api get layoutType() {
        return this._layout;
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

    set recordTypeId(val) {
        this._recordTypeId = val;
        this._fieldsHandled = false;
    }

    @api get recordTypeId() {
        return this._recordTypeId;
    }

    @api get defaultFieldValues() {
        return this._defaultFieldValues;
    }

    set defaultFieldValues(val) {
        if(val == null){
            val = {}
        }
        this._defaultFieldValues = val;
    }

    set recordId(val) {
        if (!val && !this._mode) {
            this._editMode = true;
        }

        this._recordId = normalizeRecordId(val);

        this._fieldsHandled = false;
    }

    @api get recordId() {
        return this._recordId;
    }

    set objectApiName(val) {
        this._objectApiName = val;
    }

    @api get objectApiName() {
        return this._objectApiName;
    }

    set columns(val) {
        this.cols = parseInt(val, 10);
        if (isNaN(this.cols) || this.cols < 1) {
            this.cols = 1;
        }
    }

    @api get columns() {
        return this.cols;
    }

    @api
    submit() {
        if (!this.validateForm()) {
            return;
        }
        var formFieldValues = this.getAllFormValues();
        this.template.querySelector('lightning-record-edit-form').submit(formFieldValues);
    }

    @track errors = new Map();
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

    getInputFieldComponents() {
        return [...this.template.querySelectorAll('lightning-input-field')];
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

    addField(val) {
        const fieldName = val.fieldApiName ? val.fieldApiName : val;
        if (!this._dupMapper[fieldName]) {
            this._fields.push(fieldName);
            this._dupMapper[fieldName] = true;
        }
    }

    connectedCallback() {
        if (!this._recordId && !this._mode) {
            this._editMode = true;
        }
    }

    set fields(val) {
        this.fieldsReady = true;
        this._fields = [];
        this._dupMapper = {};
        if (Array.isArray(val)) {
            for (let i = 0; i < val.length; i++) {
                this.addField(val[i]);
            }
        } else {
            this.addField(val);
        }
    }

    @api get fields() {
        return this._rawFields;
    }

    get _editable() {
        return !this._loading && !this.readOnly && !this._loadError;
    }

    get _viewMode() {
        return !this._editMode;
    }

    set _viewMode(val) {
        this._editMode = !val;
    }

    get _sections() {
        const out = [];

        if (!this._layoutData) {
            return out;
        }
        let sections = this._layoutData.sections.length ? this._layoutData.sections : [];
        sections = deepCopy(sections);

        let sectionKey = 0;
        let rowkey = 0;
        let thisSection = { rows: [], isCustom: false, heading: '', key: sectionKey, id: ''};
        let thisRow = { fields: [], key: rowkey };
        console.log('Fields'+this.fields);
        const processedFieldNames = {};
        sections.forEach((section) => {
            section.layoutRows.forEach((row)=>{
                row.layoutItems.forEach((item) => {
                    const required = item.required;
                    item.layoutComponents.forEach((component)=> {
                        let field = component.apiName;
                        let componentType = component.componentType;
                        if (this._objectInfo.fields && this._objectInfo.fields[field] && componentType!="EmptySpace") {
                            const getFieldsFromLayoutComponent = () => {
                                const fieldInfo = this._objectInfo.fields[field];
                        
                                if (fieldInfo && fieldInfo.compoundFieldName) {
                                    field = fieldInfo.compoundFieldName;
                                }
                                if (fieldInfo && !processedFieldNames[field]) {
                                    processedFieldNames[field] = true;
                                    return field;
                                }
                                return "";
                            };

                            if(getFieldsFromLayoutComponent()){
                                const compound = isCompoundField(
                                    field,
                                    this._objectInfo,
                                    this._isPersonAccount
                                );
            
                                let compoundFields = [];
                                if (compound) {
                                    compoundFields = getCompoundFields(
                                        field,
                                        this._record,
                                        this._objectInfo
                                    );
                                }
            
                                const hasFields =
                                    this._objectInfo && this._objectInfo.fields;
            
                                const fieldUpdateable = compound
                                    ? compoundFieldIsUpdateable(
                                          compoundFields, // eslint-disable-line indent
                                          this._record, // eslint-disable-line indent
                                          this._objectInfo // eslint-disable-line indent
                                      ) // eslint-disable-line indent
                                    : hasFields &&
                                      this._objectInfo.fields[field].updateable;
                                const fieldCreateable = compound
                                    ? compoundFieldIsCreateable(
                                          compoundFields, // eslint-disable-line indent
                                          this._record, // eslint-disable-line indent
                                          this._objectInfo // eslint-disable-line indent
                                      ) // eslint-disable-line indent
                                    : hasFields &&
                                      this._objectInfo.fields[field].createable;
                                const shouldShowAsInputInEditMode =
                                    fieldUpdateable || (!this._recordId && fieldCreateable);
                                let updateable =
                                    !isUnsupportedReferenceField(field) && this._objectInfo
                                        ? shouldShowAsInputInEditMode
                                        : false;
                                let editable =
                                    !isUnsupportedReferenceField(field) &&
                                    this._editable &&
                                    (hasFields && this._objectInfo.fields[field]
                                        ? fieldUpdateable
                                        : false);
                                //const defaultValue = !this.recordId ? (this._defaultFieldValues[field] ? this._defaultFieldValues[field] : '') : '';
                                if(field == 'RecordTypeId'){
                                    editable = false;
                                    updateable = false;
                                }
                                thisRow.fields.push({
                                    field,
                                    editable,
                                    updateable,
                                    required,
                                    //defaultValue,
                                    'isBlankSpaceItem' : false
                                });
                            }
                        } else {
                            thisRow.fields.push({
                                'field': 'section'+sectionKey+'_row'+rowkey,
                                'isBlankSpaceItem' : true
                            });
                        }
                    });
                });
                thisSection.rows.push(thisRow);
                thisRow = { fields: [], key: ++rowkey };
            });
            thisSection.heading = section.heading;
            out.push(thisSection);
            thisSection = { rows: [], heading: '', key: ++sectionKey, id: section.id };
        });
        console.log('sections out'+JSON.stringify(out));
        return out;
    }

    get computedOutputClass() {
        const classnames = classSet(
            'slds-form-element_small slds-form-element_edit slds-hint-parent'
        );
    }

    toggleEdit(e) {
        if (e) {
            e.stopPropagation();
        }
        this._editMode = !this._editMode;
    }

    /*get _sectionsWithKey() {
        const out = [];
        let sectionsWithKey = [];

        if (!this._layoutData) {
            return out;
        }
        let sections = this._layoutData.sections.length ? this._layoutData.sections : [];
        sections = deepCopy(sections);
        sectionsWithKey = sections.map(section => { return { ...section, layoutRows: (section.layoutRows).map((row, rowIndex) => {return { ...row, key: section.id+rowIndex}; })}});
        console.log('sectionsWithKey'+JSON.stringify(sectionsWithKey));
        return sectionsWithKey;
    }*/

    handleLoad(e) {
        e.stopPropagation();
        const apiName = this._objectApiName.objectApiName
            ? this._objectApiName.objectApiName
            : this._objectApiName;

        if (!this._fieldsHandled && this._layout && e.detail.objectInfos) {
            const layoutFields = getFieldsForLayout(
                e.detail,
                apiName,
                this._layout
            );

            this.fields = Object.keys(layoutFields);
            this._fieldsHandled = true;

            let layoutData = e.detail.layout;
            if (e.detail.layouts) {
                layoutData = extractLayoutFromLayouts(
                    e.detail.layouts,
                    apiName,
                    this._layout || 'Full'
                );
            }   
            this._layoutData = layoutData;
        }

        const record = e.detail.records
            ? e.detail.records[this._recordId]
            : e.detail.record;
        this._record = record;

        this._isPersonAccount = record ? isPersonAccount(record) : false;

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
        this._objectInfo = deepCopy(e.detail.objectInfos[apiName]);

        /*const viewData = {
                    record,
                    objectInfo: this._objectInfo
                };
        this._recordTypeId = this.getRecordTypeId(viewData);*/

        const cmps = this.getInputFieldComponents();
        if(!this.recordId){
            this.setDefaultFieldValues(cmps);
        }

        this.dispatchEvent(
            new CustomEvent('load', {
                detail: e.detail
            })
        );
    }

    /*getRecordTypeId(recordUi) {
        const record = recordUi.record;
        const objectInfo = recordUi.objectInfo;

        const defaultRecordTypeId =
            objectInfo.defaultRecordTypeId || MASTER_RECORD_TYPE_ID;

        if (!record.id) {
            return defaultRecordTypeId;
        }

        return record.recordTypeId || defaultRecordTypeId;
    }*/

    setDefaultFieldValues(inputFields){
        inputFields.forEach((field) => {
            if(field.dataset.id) {
                var targetId = field.dataset.id;
                this.template.querySelector(`[data-id="${targetId}"]`).value = this._defaultFieldValues[targetId];
            }
        });
    }

    handleError(e) {
        e.stopPropagation();
        this._loading = false;
        if (this._firstLoad) {
            this._loadError = true;
        }
        this.dispatchEvent(
            new CustomEvent('error', {
                detail: e.detail
            })
        );
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            this.template.querySelector('lightning-messages').scrollIntoView({behavior: "smooth",block: "nearest",inline: "nearest"});
        }, 0);
    }

    @api
    submitProgrammatically(){
        const submitBtn = this.template.querySelector( ".submitProgrammatic" );
        if(submitBtn){
            submitBtn.click();
        }
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

    handleSubmit(event) {
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            this._loading = !event.defaultPrevented;
        }, 0);
    }

    clearForm() {
        const inputFields = this.template.querySelectorAll(
            'lightning-input-field'
        );

        if (inputFields) {
            inputFields.forEach((field) => {
                field.reset();
            });
        }
    }

    handleCancel(e) {
        if (this._recordId) {
            this.toggleEdit(e);
        } else {
            this.clearForm();
        }

        this.template.querySelector('lightning-messages').setError(null);
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    handleSuccess(e) {
        e.stopPropagation();
        this._loadedPending = false;
        this._loading = false;
        this._editMode = true;
        this.recordId = e.detail.id;
        //this._loadedPending = true;
        //this._editMode = false;
        //this.recordId = e.detail.id;
        this.dispatchEvent(
            new CustomEvent('success', {
                detail: e.detail
            })
        );
    }
}