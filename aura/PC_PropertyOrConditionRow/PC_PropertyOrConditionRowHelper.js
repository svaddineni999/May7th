/**
 * Created by kkanteti on 9/24/2020.
 */
({
    showSpinner: function(component,event,helper){
        var spinner = component.find("rowSpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },
    hideSpinner: function(component,event,helper){
        var spinner = component.find("rowSpinner");
        $A.util.addClass(spinner, "slds-hide");
    },
    onOperatorChange : function(component, event, helper){
        $A.util.removeClass(component.find('stringFromField'),'slds-has-error');
        $A.util.removeClass(component.find('dateFromField'),'slds-has-error');
        $A.util.removeClass(component.find('dateTimeFromField'),'slds-has-error');
        var row = component.get("v.row");
        var rowIndex = component.get("v.rowIndex");
        var selectedOperator = row.selectedField.operator;
        row.fromAnyCheckboxValue = false;
        row.toAnyCheckboxValue = false;
        if(selectedOperator == 'Has not changed' || selectedOperator == 'Is not null' || selectedOperator == 'Is null'){
            if(rowIndex == 0){
                var cmpEvent = component.getEvent("propertyOrConditionRow");
                cmpEvent.setParams({
                    "showToValueColumn" : false
                });
                cmpEvent.fire();
            }
            row.valueNeeded = false;
            row.showToValueColumn = false;
            row.selectedField.value = "";
        }else{
            row.valueNeeded =  true;
            var booleanOptions = component.get("v.booleanValues");
            if(selectedOperator == 'Has changed'){
                row.showToValueColumn = true;
                if(row.selectedField.type.toUpperCase() == "BOOLEAN"){
                    row.selectedField.toValue = booleanOptions[0].value;
                }
                if(rowIndex ==0){
                    var componentEvent = component.getEvent("propertyOrConditionRow");
                    componentEvent.setParams({
                        "showToValueColumn" : true
                    });
                    componentEvent.fire();
                }
            }else{
                row.showToValueColumn = false;
                if(row.selectedField.type.toUpperCase() == "BOOLEAN"){
                    row.selectedField.value = booleanOptions[0].value;
                }
                if(rowIndex == 0){
                    var rowCmpEvent = component.getEvent("propertyOrConditionRow");
                    rowCmpEvent.setParams({
                        "showToValueColumn" : false
                    });
                    rowCmpEvent.fire();
                }
            }
        }
        component.set("v.row",row);
    },
    onField : function(component, event, helper){
        if(!component.get('v.isDisabled')){
            helper.resetRow(component, event, helper);
            helper.onFieldChangeInFieldSelector(component,event,helper);
            helper.showFieldSelector(component,event,helper);
        }
    },
    valueChange : function(component,event,helper){
        if(component.get("v.row.formulaValue.isFormula")){
            var fieldValue = component.get("v.row.selectedField.value");
            var allFields = component.get("v.row.selectedFieldDropdownValues");
            for(var t=0;t<allFields.length;t++){
                if(allFields[t].value == fieldValue){
                    component.set("v.row.formulaValue.referenceFieldType",allFields[t].type);
                }
            }
        }
    },
    onDateReferenceChange : function(component,event,helper){
        if(component.get("v.row.formulaValue.isFormula") && component.get("v.row.selectedFieldDropdownValues").length < 1){
            helper.showSpinner(component,event,helper);
            var action = component.get("c.getAllFormulaOptions");
            action.setParams({
                "triggerEventObjectApiName" : component.get("v.triggerObjectName")
            });
            action.setCallback(this, function(response){
                var state = response.getState();
                if(state == "SUCCESS"){
                    var dropdownValues = response.getReturnValue();
                    component.set("v.row.selectedField.value",dropdownValues.dateAndDatetimeFields[0].value);
                    component.set("v.row.formulaValue.referenceFieldType",dropdownValues.dateAndDatetimeFields[0].type);
                    component.set("v.row.selectedFieldDropdownValues",dropdownValues.dateAndDatetimeFields);
                    component.set("v.row.formulaValue.offsetTypeOptions",dropdownValues.offsetTypeOptions);
                    component.set("v.row.formulaValue.offsetType",dropdownValues.offsetTypeOptions[0].value);
                    component.set("v.row.formulaValue.operationOptions",dropdownValues.operationOptions);
                    component.set("v.row.formulaValue.operation",dropdownValues.operationOptions[0].value);
                }else if(state == "ERROR"){
                    var errors = response.getError();
                    CH_PC_Util.showAllErrors(component.get("v.errorStatus"),errors);
                }else{
                    var error = {"message" : 'Unknown error'};
                    errors.push(error);
                    CH_PC_Util.showAllErrors(component.get('v.errorStatus'),errors);
                }
                helper.hideSpinner(component,event,helper);
            });
            $A.enqueueAction(action);
        }else{
            component.set("v.row.selectedField.value",'');
        }
    },
    onTodayChange : function(component,event,helper){
        var dateField = component.find("dateFromField");
        if(dateField.checkValidity()){
            var row = component.get("v.row");
            if(row.todayCheckboxValue){
                dateField.setCustomValidity("");
                dateField.reportValidity();
            }
        }
    },
    onNowChange : function(component,event,helper){
        var dateTimeField = component.find("dateTimeFromField");
        if(dateTimeField.checkValidity()){
            var row = component.get("v.row");
            if(row.nowCheckboxValue){
                dateTimeField.setCustomValidity("");
                dateTimeField.reportValidity();
            }
        }
    },
    onChangeToAssignId : function(component,event,helper){
        var row = component.get("v.row");
        if(row.assignIdInPlatformEvent){
            row.selectedField.isBoundValue = true;
            var fieldApiName = row.selectedField.apiName;
            helper.showSpinner(component,event,helper);
            helper.getTriggerObjectLookupFields(component,event,helper,fieldApiName,'');
        }else{
            row.selectedField.value = "";
            row.selectedField.isBoundValue = false;
        }
        component.set("v.row",row);
    },
    onChangeToBoundPicklist : function(component,event,helper){
        var row = component.get("v.row");
        var boundValue = row.picklistBoundCheckboxValue;
        row.selectedField.isBoundValue = boundValue;
        var fieldValue = '';
        if(boundValue){
            fieldValue = row.selectedField.apiName;
        }else{
            fieldValue = row.selectedFieldDropdownValues[0].value;
        }
        row.selectedField.value = fieldValue;
        component.set("v.row",row);
    },
    resetRow : function(component, event, helper,rowIndex){
        var resetRow = {
               'selectedField' :  {'label' :'','apiName' :'','type':'','operator':'','value':'','toValue':'','isBoundValue':false},
               'selectedFieldDropdownValues' : [] ,
               'multiSelectToDropdownValues' : [] ,
               'multiSelectToValues' : [] ,
               'multiSelectFromValues' : [] ,
               'operatorOptions' : [],
               'valueNeeded' : true,
               'isDeleteAllowed':true,
               'assignIdInPlatformEvent' : false,
               'picklistBoundCheckboxValue' : false,
               'todayCheckboxValue' : false,
               'nowCheckboxValue' : false,
               'formulaValue' : {'isFormula':false,
                                            'referenceFieldApiName': '',
                                            'referenceFieldType': '',
                                            'operation': '',
                                            'offsetType': '',
                                            'offsetValue': 0,
                                            'offsetTypeOptions' : [],
                                            'operationOptions' : []
                                            },
               'showToValueColumn' : false,
               'fromAnyCheckboxValue' : false,
               'toAnyCheckboxValue' : false,
               'showLookUpHelpText' :  false,
               'showNoOptionsError' : false
        };
        component.set("v.row",resetRow);
    },
    onFieldChangeInFieldSelector : function(component, event, helper){
        var selectedFieldApiName = event.getSource().get("v.value");
        var allFieldsList = component.get("v.allFieldsList");
        if(!$A.util.isEmpty(allFieldsList)){
            if($A.util.isEmpty(component.get("v.selectedFieldInPopup"))){
                var selectedField = {
                    'fieldLabel' : allFieldsList[0].label,
                    'fieldApiName':allFieldsList[0].apiName,
                    'fieldType': allFieldsList[0].type.charAt(0).toUpperCase() + allFieldsList[0].type.slice(1).toLowerCase()
                }
                component.set("v.selectedFieldInPopup",selectedField);
            }else{
                for(var u=0;u<allFieldsList.length;u++){
                    if(allFieldsList[u].apiName == selectedFieldApiName){
                        var selectedFieldInPopup = {
                            'fieldLabel' : allFieldsList[u].label,
                            'fieldApiName':allFieldsList[u].apiName,
                            'fieldType':allFieldsList[u].type.charAt(0).toUpperCase() + allFieldsList[u].type.slice(1).toLowerCase()
                        }
                        component.set("v.selectedFieldInPopup",selectedFieldInPopup);
                    }
                }
            }
        }
    },
    getOperatorOptions : function(component,event,helper,fieldType){
        if(component.get("v.showOperator")){
            var options = [];
            var fieldTypeOperatorsMap = component.get("v.fieldTypeOperatorsMap");
            if(fieldTypeOperatorsMap.has(fieldType)){
                options = fieldTypeOperatorsMap.get(fieldType);
            }else{
                options = component.get('v.defaultOperators');
            }
            return options;
        }
    },
    onSelectInFieldSelector : function(component, event, helper){
        var selectedFieldInPopup = component.get("v.selectedFieldInPopup");
        var fieldType = selectedFieldInPopup.fieldType.toUpperCase();
        var fieldApiName = selectedFieldInPopup.fieldApiName;
        var selectedRow = component.get("v.row");
        var fieldValue = '';
        var boundValue = false;
        var operatorValue = "";
        if(component.get("v.showOperator")){
            var options = helper.getOperatorOptions(component,event,helper,fieldType);
            selectedRow.operatorOptions= options;
            operatorValue = options[0].value;
            selectedRow.showToValueColumn = false;
            if(component.get("v.isSupportPlanTriggerEventConditions")){
                var rowIndex = component.get("v.rowIndex");
                if(rowIndex == 0){
                    var cmpEvent = component.getEvent("propertyOrConditionRow");
                    cmpEvent.setParams({
                        "showToValueColumn" : false
                    });
                    cmpEvent.fire();
                }
            }
        }
        if(operatorValue != "" &&(operatorValue ==  'Is null' || operatorValue == 'Is not null' || operatorValue == 'Has not changed')){
            selectedRow.valueNeeded = false;
        }
        if(fieldType == "PICKLIST" || fieldType == "COMBOBOX" || fieldType == "MULTIPICKLIST"){
            helper.showSpinner(component,event,helper);
            helper.getDropdownValues(component, event, helper,fieldApiName,'','');
        }else if(fieldType =="REFERENCE"){
             boundValue = true;
             helper.showSpinner(component,event,helper);
             helper.getTriggerObjectLookupFields(component,event,helper,fieldApiName,'');
        }else if(fieldType =="BOOLEAN"){
            var booleanValues = component.get("v.booleanValues");
            fieldValue = booleanValues[0].value;
        }
        var selectedFieldProperties = {
            'label' : selectedFieldInPopup.fieldLabel,
            'apiName' :fieldApiName,
            'type': fieldType.charAt(0).toUpperCase() + fieldType.slice(1).toLowerCase(),
            'operator' : operatorValue,
            'value': fieldValue,
            'toValue':'',
            'isBoundValue': boundValue
        };
        selectedRow.selectedField = selectedFieldProperties;
        component.set("v.row",selectedRow);
        component.set("v.selectedFieldInPopup",null);
        helper.hideFieldSelector(component, event, helper);
    },
    getDropdownValues : function(component, event, helper,fieldApiName,savedFromValue,savedToValue){
        var objectName = component.get('v.objectName');
        var action  = component.get('c.getFieldDropdownValues');
        action.setParams({
              "recType" : objectName,
              "fieldApiName" : fieldApiName
        });
        action.setCallback(this,function(response){
            var state=response.getState();
            if('SUCCESS'==state){
                var fieldDropdownValues = response.getReturnValue();
                if(!$A.util.isEmpty(fieldDropdownValues)){
                    var row = component.get("v.row");
                    row.selectedFieldDropdownValues =  JSON.parse(JSON.stringify(fieldDropdownValues));
                    row.multiSelectToDropdownValues =  JSON.parse(JSON.stringify(fieldDropdownValues));
                    row.selectedField.value =  fieldDropdownValues[0].value;
                    row.selectedField.toValue = fieldDropdownValues[0].value;
                    if(savedFromValue != ''){
                        row.selectedField.value =  savedFromValue;
                    }
                    if(savedToValue != ''){
                        row.selectedField.toValue = savedToValue;
                    }
                    component.set("v.row",row);
                }
            }else if (state === "ERROR") {
                  var errors = response.getError();
                  CH_PC_Util.showAllErrors(component.get("v.errorStatus"),errors);
            }else {
                console.log("Unknown error");
            }
            helper.hideSpinner(component,event,helper);
        });
        $A.enqueueAction(action);
    },
    getTriggerObjectLookupFields : function(component, event, helper,fieldApiName,savedValue){
        var triggerEventObjectName = component.get("v.triggerObjectName");
        if(triggerEventObjectName != ""){
            var action = component.get('c.getTriggerObjectLookupFields');
            action.setParams({
                "triggerEventObjectName" : triggerEventObjectName,
                "triggerEventObjectType" : component.get("v.objectType"),
                "recordObjectName": component.get("v.objectName"),
                "recordFieldApiName": fieldApiName
            });
            action.setCallback(this,function(response){
                var state=response.getState();
                if('SUCCESS'==state){
                    var fieldDropdownValues = response.getReturnValue();
                    var row = component.get("v.row");
                    if(!$A.util.isEmpty(fieldDropdownValues)){
                        if(component.get("v.builderContext") == 'PropertyBuilderInUpdate'){
                            var nullValue = {
                                "label" : $A.get("$Label.c.PC_Null"),
                                "value" : "NULL",
                            };
                            fieldDropdownValues.unshift(nullValue);
                        }
                        for(var d=0; d<fieldDropdownValues.length; d++){
                            if(fieldApiName == fieldDropdownValues[d].value &&
                                        component.get("v.updateContext") == 'updateTriggerRecord'){
                                fieldDropdownValues.splice(d,1);
                            }
                        }
                        row.selectedFieldDropdownValues =  fieldDropdownValues;
                        row.selectedField.value =  fieldDropdownValues[0].value;
                        if(savedValue != ''){
                            row.selectedField.value = savedValue;
                        }
                        row.showLookUpHelpText =  true;
                        row.showNoOptionsError =  false;
                    }else{
                        row.showLookUpHelpText =  false;
                        row.showNoOptionsError =  true;
                    }
                    component.set("v.row",row);
                }else if (state === "ERROR") {
                      var errors = response.getError();
                      CH_PC_Util.showAllErrors(component.get("v.errorStatus"),errors);
                }else {
                    console.log("Unknown error");
                }
                helper.hideSpinner(component,event,helper);
            });
            $A.enqueueAction(action);
        }
    },
    onCancelInFieldSelector : function(component, event, helper){
        if(component.get("v.isSupportPlanTriggerEventConditions")){
            var rowIndex = component.get("v.rowIndex");
            if(rowIndex == 0){
                var cmpEvent = component.getEvent("propertyOrConditionRow");
                cmpEvent.setParams({
                    "showToValueColumn" : false
                });
                cmpEvent.fire();
            }
        }
        helper.hideFieldSelector(component, event, helper);
    },
    showFieldSelector : function(component,event,helper){
        var modalBox = component.find("aura_linkSectionId");
        $A.util.removeClass(modalBox,'slds-hide');
        $A.util.addClass(modalBox,'slds-show');
        var backgroundSection = component.find("aura_backGroundSectionId");
        $A.util.removeClass(backgroundSection,'slds-hide');
        $A.util.addClass(backgroundSection,'slds-show');
    },
    hideFieldSelector : function(component, event, helper){
        var modalBox = component.find("aura_linkSectionId");
        $A.util.removeClass(modalBox,'slds-show');
        $A.util.addClass(modalBox,'slds-hide');
        var backgroundSection = component.find("aura_backGroundSectionId");
        $A.util.removeClass(backgroundSection,'slds-show');
        $A.util.addClass(backgroundSection,'slds-hide');
    },
    initiateMultiSelectCombobox : function(component,event,helper){
        var multiSelectFromComponent =  component.find('multiSelectFromCombobox');
        if(typeof multiSelectFromComponent != 'undefined'){
            multiSelectFromComponent.initiateCombobox();
        }
        if(component.get("v.row.selectedField.operator") == 'Has changed'){
            var multiSelectToComponent =  component.find('multiSelectToCombobox');
            if(typeof multiSelectToComponent != 'undefined'){
                multiSelectToComponent.initiateCombobox();
            }
        }
    },
    validateRowData : function(component,event,helper){
        var isValid = true;
        var fieldType = component.get("v.row.selectedField.type").toUpperCase();
        var fieldValue='';

        //Search field values validating
        var searchField = component.find('searchInputField');
        var searchFieldValue = searchField.get("v.value");
        if(searchFieldValue === ""){
            $A.util.addClass(searchField,'slds-has-error');
            isValid = false;
        }else{
            $A.util.removeClass(searchField,'slds-has-error');
        }

        //Field value check
        if(component.get("v.row.formulaValue.isFormula")){
            var offsetValue = component.get("v.row.formulaValue.offsetValue");
            if($A.util.isEmpty(offsetValue) || offsetValue % 1 != 0){
                isValid = false;
            }
        }

        if(fieldType != "" && component.get("v.row.valueNeeded")){
            if(fieldType == 'DATE'){
                var dateField = component.find('dateFromField');
                if(!component.get("v.row.todayCheckboxValue") && !component.get("v.row.formulaValue.isFormula") && !component.get("v.row.fromAnyCheckboxValue")){
                    var dateValue = dateField.get("v.value");
                    if(dateValue === ""){
                        $A.util.addClass(dateField,'slds-has-error');
                        isValid = false;
                    }else{
                        $A.util.removeClass(dateField,'slds-has-error');
                    }
                }
            }else if(fieldType == 'DATETIME'){
                var dateTimeField = component.find('dateTimeFromField');
                if(!component.get("v.row.nowCheckboxValue") && !component.get("v.row.formulaValue.isFormula") && !component.get("v.row.fromAnyCheckboxValue")){
                    var dateTimeValue = dateTimeField.get("v.value");
                    if(dateTimeValue === ""){
                        $A.util.addClass(dateTimeField,'slds-has-error');
                        isValid = false;
                    }else{
                        $A.util.removeClass(dateTimeField,'slds-has-error');
                    }
                }
            }else if(fieldType == 'MULTIPICKLIST' && !component.get("v.row.fromAnyCheckboxValue")){
                var multiSelectValues = component.get("v.row.multiSelectFromValues");
                if($A.util.isEmpty(multiSelectValues)){
                    component.set("v.multiSelectErrorMessage",component.get("v.requiredFieldError"));
                    isValid = false;
                }else{
                    component.set("v.multiSelectErrorMessage",'');
                }
                if(isValid){
                    var fieldDropdownValues = component.get("v.row.selectedFieldDropdownValues");
                    var fromDropdownValues = [];
                    for(var key in fieldDropdownValues){
                        fromDropdownValues.push(fieldDropdownValues[key].value);
                    }
                    multiSelectValues.forEach(function(element, index){
                        if(!fromDropdownValues.includes(element)){
                            component.set("v.multiSelectErrorMessage",component.get("v.incorrectValuesError"));
                            isValid = false;
                        }else{
                            if(isValid){
                                component.set("v.multiSelectErrorMessage",'');
                            }
                        }
                    });
                }
            }else if(fieldType != 'PICKLIST' && fieldType != 'REFERENCE' && fieldType != 'BOOLEAN' && !component.get("v.row.assignIdInPlatformEvent") && !component.get("v.row.fromAnyCheckboxValue")){
                var stringField = component.find('stringFromField');
                if(component.get("v.row.valueNeeded")){
                    var stringValue = stringField.get("v.value");
                    if(stringValue === ""){
                        $A.util.addClass(stringField,'slds-has-error');
                        isValid = false;
                    }else{
                        $A.util.removeClass(stringField,'slds-has-error');
                    }
                }
            }
        }

        if(component.get("v.row.showToValueColumn")){
            if(fieldType != ""){
                if(fieldType == 'DATE'){
                    var dateToField = component.find('dateToField');
                    if(!component.get("v.row.toAnyCheckboxValue")){
                        var dateToValue = dateToField.get("v.value");
                        if(dateToValue === ""){
                            $A.util.addClass(dateToField,'slds-has-error');
                            isValid = false;
                        }else{
                            $A.util.removeClass(dateToField,'slds-has-error');
                        }
                    }
                }else if(fieldType == 'DATETIME'){
                    var dateTimeToField = component.find('dateTimeToField');
                    if(!component.get("v.row.toAnyCheckboxValue")){
                        var dateTimeToValue = dateTimeToField.get("v.value");
                        if(dateTimeToValue === ""){
                            $A.util.addClass(dateTimeToField,'slds-has-error');
                            isValid = false;
                        }else{
                            $A.util.removeClass(dateTimeToField,'slds-has-error');
                        }
                    }
                }else if(fieldType == 'MULTIPICKLIST' && !component.get("v.row.toAnyCheckboxValue")){
                    var multiSelectToValues = component.get("v.row.multiSelectToValues");
                    if($A.util.isEmpty(multiSelectToValues)){
                        component.set("v.multiSelectToErrorMessage",component.get("v.requiredFieldError"));
                        isValid = false;
                    }else{
                        component.set("v.multiSelectToErrorMessage",'');
                    }
                    if(isValid){
                        var fieldToDropdownValues = component.get("v.row.multiSelectToDropdownValues");
                        var toDropdownValues = [];
                        for(var key in fieldToDropdownValues){
                            toDropdownValues.push(fieldToDropdownValues[key].value);
                        }
                        multiSelectToValues.forEach(function(element, index){
                            if(!toDropdownValues.includes(element)){
                                component.set("v.multiSelectToErrorMessage",component.get("v.incorrectValuesError"));
                                isValid = false;
                            }else{
                                if(isValid){
                                    component.set("v.multiSelectToErrorMessage",'');
                                }
                            }
                        });
                    }
                }else if(fieldType != 'PICKLIST' && fieldType != 'BOOLEAN' && !component.get("v.row.toAnyCheckboxValue")){
                    var stringToField = component.find('stringToField');
                    var stringToValue = (!$A.util.isUndefinedOrNull(stringToField)) ? stringToField.get("v.value") : "";
                    if(stringToValue === ""){
                        $A.util.addClass(stringToField,'slds-has-error');
                        isValid = false;
                    }else{
                        $A.util.removeClass(stringToField,'slds-has-error');
                    }
                }
            }
        }
        return isValid;
    }
})