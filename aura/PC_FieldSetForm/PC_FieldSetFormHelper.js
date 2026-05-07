({
    /*
     *  Map the Schema.FieldSetMember to the desired component config, including specific attribute values
     *  Source: https://www.salesforce.com/us/developer/docs/apexcode/index_Left.htm#CSHID=apex_class_Schema_FieldSetMember.htm|StartTopic=Content%2Fapex_class_Schema_FieldSetMember.htm|SkinName=webhelp
     *
     *  Change the componentDef and attributes as needed for other components
     */
    configHtmlMap : {
        'text': { attributes: {'valueAttr' : 'value'} },
        'textarea': { attributes: {'valueAttr' : 'value'} },
        'checkbox1': { attributes: {'valueAttr' : 'checked'} },
        'checkbox': { attributes: {'valueAttr' : 'value'} },
        'date': { attributes: {'valueAttr' : 'value'} },
        'datetime-local': { attributes: {'valueAttr' : 'value'} },
        'picklist': { attributes: {'valueAttr' : 'value'} },
        'select': { attributes: {'valueAttr' : 'value'} },
        'email': { attributes: {'valueAttr' : 'value'} },
        'number': { attributes: {'valueAttr' : 'value'} },
        'tel': { attributes: {'valueAttr' : 'value'} }        
    },
    configLightningMap: {
        'anytype': { componentDef: '', attributes: {} },
        'base64': { componentDef: '', attributes: {} },
        
        'boolean1': {componentDef: 'lightning:input',
            attributes: {
                'type': 'checkbox'
            } },
        'boolean': {componentDef: 'ui:inputCheckbox',
            attributes: {
                
            } },
        'combobox': { componentDef: '', attributes: {} },
        'currency': { componentDef: '', attributes: {} },
        'datacategorygroupreference': { componentDef: '', attributes: {} },
        'date': {
            componentDef: 'lightning:input',
            attributes: {
                'type': 'date',
                'dateStyle': 'short'
            }
        },
        'date1': {
            componentDef: 'ui:inputDate',
            attributes: {
                'displayDatePicker':'true',
                'format':'yyyy-MM-dd',
                'class' : 'slds-input' ,
                'labelClass' : 'slds-form-element__label uiInputDateLabel',
                'requiredIndicatorClass': 'slds-required'
            }
        },
        'datetime': {
            componentDef: 'lightning:input', attributes: {
                'type': 'datetime-local',
                'dateStyle': 'short'
            } 
        },
        'datetime1': {
            componentDef: 'ui:inputDateTime', attributes: {
                'displayDatePicker':'true',
                'format':"yyyy-MM-dd HH:mm",
                'class' : 'slds-input uiInputDateTimeClass' ,
                'labelClass' : 'slds-form-element__label uiInputDateTimeLabelClass',
                'requiredIndicatorClass': 'slds-required'
            } 
        },
        'double1': { componentDef: 'lightning:input', 
                   attributes: {
                       'type': 'number',
                       'min':'-99999999999999',
                       'max':'99999999999999',
                       'step': 1} },
        'double': { componentDef: 'markup://ui:inputNumber', 
                   attributes: {
                       'class': 'slds-input',
                       'labelClass' : 'slds-form-element__label uiInputNumberLabel',
                       'requiredIndicatorClass': 'slds-required'
                   } },
        'email': {
            componentDef: 'lightning:input',
            attributes: {
                'type': 'email'
            }
        },
        'encryptedstring': { componentDef: '', attributes: {} },
        'id': { componentDef: '', attributes: {} },
        'integer1': { componentDef: 'lightning:input', attributes: {'type': 'number'} },
        'integer': { componentDef: 'markup://ui:inputNumber', 
                   attributes: {
                       'class': 'slds-input',
                       'labelClass' : 'slds-form-element__label uiInputNumberLabel',
                       'requiredIndicatorClass': 'slds-required'
                   } },
        'multipicklist': { componentDef: 'markup://ui:inputSelect', 
                     attributes: {
                         'class' : 'slds-select multiple' ,
                         'labelClass' : 'slds-form-element__label uiInputSelectLabel',
                         'requiredIndicatorClass': 'slds-required',
                         'multiple' : 'true'
        	} },
        'percent': { componentDef: '', attributes: {} },
        'phone': { componentDef: 'lightning:input',
            attributes: {
                'type': 'tel'
            } },
        'picklist': { componentDef: 'markup://ui:inputSelect', 
                     attributes: {
                         'class' : 'slds-select single' ,
                         'labelClass' : 'slds-form-element__label uiInputSelectLabel',
                         'requiredIndicatorClass': 'slds-required'
        	} },
        'picklist1': { componentDef: 'lightning:select', 
                     attributes: {
                        
        	} },
        'reference': { componentDef: '', attributes: {} },
        'string': { componentDef: 'lightning:input', attributes: {'valueAttr' : 'value'} },
        'textarea': { componentDef: 'lightning:textarea', attributes: {} },
        'time': { componentDef: '', attributes: {} },
        'url': { componentDef: '', attributes: {} }
    },
    
    createLightningForm: function(cmp,event, helper) {
        console.log('FieldSetFormHelper.createForm');
        var fields = cmp.get('v.fields');
        var inputDesc = [];
        var fieldPaths = [];
        for (var i = 0; i < fields.length; i++) {
            //var field = fields[i];
            //var config = this.configLightningMap[field.type.toLowerCase()];
            var field = JSON.parse(JSON.stringify(fields[i]));
            var config = JSON.parse(JSON.stringify(this.configLightningMap[field.type.toLowerCase()]));
            if (config) {
                console.log('----------------- ');
                console.log(field);
                console.log('label - ' + field.label);
                console.log('type  - ' + field.type.toLowerCase());                
                console.log('required ' + field.required);
                console.log('fieldPath ' + field.fieldPath);
               	console.log('selectOptions ' + field.selectOptions);
                //config.attributes.type = field.type.toLowerCase();

                config.attributes.disabled = cmp.get("v.disableFlag");
                if(i == 0) {
                    if($A.util.isEmpty(config.attributes.class)) {
                        config.attributes.class = ' firstElement';
                    }
                    else {
                        config.attributes.class += ' firstElement';
                    }
                }

                if(field.type.toLowerCase() == 'datetime') {
                	config.attributes.label = field.label + ' (GMT) ';
                }
                else {
                    config.attributes.label = field.label;
                }
                
                
                if(field.type.toLowerCase() == 'picklist' || 
                   field.type.toLowerCase() == 'multipicklist') 
                {
                    // nothing to do.
                }
                else {
                    config.attributes.name = field.label.replace(/ /g,'');
                }
                
                config.attributes.required = field.required;
                //config.attributes.value = obj[field.fieldPath];
                //config.attributes.fieldPath = field.fieldPath;
                
                if(field.type.toLowerCase() == 'picklist' || field.type.toLowerCase() == 'multipicklist') {
                    config.attributes.options = field.selectOptions;
                }
                inputDesc.push([
                    config.componentDef,
                    config.attributes
                ]);
                fieldPaths.push(field.fieldPath.replace('.','___'));
                
            } else {
                console.log('type ' + field.type.toLowerCase() + ' not supported');
            }
        }
        
        $A.createComponents(inputDesc, function(cmps, status, errorMessage) {
            var v;
            var configHtmlMap = cmp.get("v.configHtmlMap");
            if (status === "SUCCESS") {
                console.log('createComponents');
                var inputToField = {};
                var valueAttr;
                for (var i = 0; i < fieldPaths.length; i++) {
                    valueAttr  = 'value';
                    v = cmp.getReference("v.record." + fieldPaths[i]);
                    if(cmps[i].toString().toLowerCase().indexOf("lightning:input") != -1) {
                        if(cmps[i].get("v.type") == 'checkbox') {
                            valueAttr = configHtmlMap[cmps[i].get("v.type").toLowerCase()].attributes.valueAttr;
                        }                        
                    }
                    //cmps[i].addHandler('change', cmp, 'c.handleValueChange');
                    inputToField[cmps[i].getGlobalId()] = fieldPaths[i];
                    console.log("value = " + v);
                    cmps[i].set("v." + valueAttr,v);
                }
                cmp.set('v.lightningForm', cmps);
                cmp.set('v.inputToField', inputToField);
                
                cmp.set("v.lightningForm_noOfRows", Math.ceil(cmps.length/cmp.get("v.noOfItemsInARow")));
                
                var rows = [];
                for(var l=0; l< cmp.get("v.lightningForm_noOfRows"); l++) {
                    rows.push(l);
                }
                cmp.set("v.lightningForm_Rows",rows);
                
                var columns = [];
                for(var m=0; m< cmp.get("v.noOfItemsInARow"); m++) {
                    columns.push(m);
                }
                cmp.set("v.lightningForm_Columns",columns);
                
                console.log(cmp.get("v.lightningForm_Rows"));
                console.log(cmp.get("v.lightningForm_Columns"));
                
                // convert to map
                var formMap = {};
                var cmpIndex = 0;
                for(var k=0; k<rows.length; k++) {
                    for(var j=0; j<columns.length; j++) {
                        if(cmpIndex < cmps.length) {
                        	formMap[k + '' + j] = cmps[cmpIndex];
                        }
                        cmpIndex++;
                    }
                }
                cmp.set("v.lightningFormMap",formMap);
                console.log(cmp.get("v.lightningFormMap"));
                
                cmp.set("v.showForm",true);
            }
            else if (status === "INCOMPLETE") {
                console.log("No response from server or client is offline.")
                // Show offline error
            }
                else if (status === "ERROR") {
                    console.log("Error: " + errorMessage);
                    // Show error message
                }
            
            
        });
    },
    
    validate : function(cmp, event, helper) {
        
        var validSoFar = true;
        var allValid = cmp.get('v.lightningForm').reduce(function (validSoFar, inputCmp) {
            if(inputCmp.toString().toLowerCase().indexOf("ui:inputselect") != -1) {
                return validSoFar && helper.validateUIInputSelect(cmp, inputCmp);
            }
            else if(inputCmp.toString().toLowerCase().indexOf("ui:inputdate") != -1 ||
                    inputCmp.toString().toLowerCase().indexOf("ui:inputdatetime") != -1) {
                return validSoFar && helper.validateUIDateTime(cmp, inputCmp);
            }
            else if(inputCmp.toString().toLowerCase().indexOf("ui:inputnumber") != -1) {
                return validSoFar && helper.validateUIInputNumber(cmp, inputCmp);
            }
            else if(inputCmp.toString().toLowerCase().indexOf("ui:inputcheckbox") != -1) {
                return validSoFar && helper.validateUIInputNumber(cmp, inputCmp);
            }
            inputCmp.showHelpMessageIfInvalid();
            return validSoFar && inputCmp.get('v.validity').valid;
         }, true);
        cmp.set("v.isValid",allValid)   ;
    },  
    validateUIInputNumber: function(cmp, selectCmp) {
        var requiredErrorMessage = cmp.get("v.requiedErrorMessage");
        if(selectCmp.get("v.required"))  {
            if($A.util.isEmpty(selectCmp.get("v.value"))) {
             	selectCmp.set("v.errors",[{message:requiredErrorMessage}]);
                return false;  
            }
        }
        return true;
    },
    validateUIInputSelect: function(cmp, selectCmp) {
        var requiredErrorMessage = cmp.get("v.requiedErrorMessage");
        if(selectCmp.get("v.required"))  {
            if($A.util.isEmpty(selectCmp.get("v.value"))) {
             	selectCmp.set("v.errors",[{message:requiredErrorMessage}]);
                return false;  
            }
        }
        return true;
    },
    validateUIDateTime: function(cmp, selectCmp) {
        var requiredErrorMessage = cmp.get("v.requiedErrorMessage");
        if(selectCmp.get("v.required"))  {
            if($A.util.isEmpty(selectCmp.get("v.value"))) {
             	selectCmp.set("v.errors",[{message:requiredErrorMessage}]);
                return false;  
            }
        }
       	
        return true;
    },
    handlePress : function(cmp) {
        console.log("button pressed");
    },
    setFocus : function(cmp) {
        var fieldSetFormCmp = cmp.find("fieldSetForm");
        if(cmp.get("v.autofocusFirstField") && fieldSetFormCmp != null && !cmp.get("v.isAutoFocusSet")) {
            var form = fieldSetFormCmp.getElement();
            var inputs = form.querySelector(".firstElement");
            if(inputs != undefined && inputs != null) {
                inputs.setAttribute("autofocus","true");
                inputs.focus();
                cmp.set("v.isAutoFocusSet", true);
            }
        }
    },
    clearAttributes : function(cmp) {
        cmp.set("v.isAutoFocusSet", false);
    }
})