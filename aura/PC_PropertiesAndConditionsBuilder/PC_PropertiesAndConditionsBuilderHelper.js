/**
 * Created by kkanteti on 9/14/2020.
 */
({
    initializeComponent : function(component, event, helper){
        helper.getObjectFields(component, event, helper);
    },
    setNamespace : function(component) {
        var component_to_string = component.toString();
        var markupTagLoc = component_to_string.indexOf('markup://');
        var endOfNamespaceLoc = component_to_string.indexOf(':',markupTagLoc+9);
        var ns = component_to_string.substring(markupTagLoc+9,endOfNamespaceLoc);
        var namespacePrefix = (ns == "c" || ns == "C") ?  "" :  ns + "__";
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", namespacePrefix);
    },
    showSpinner: function(component,event,helper){
        var spinner = component.find("builderSpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },
    hideSpinner: function(component,event,helper){
        var spinner = component.find("builderSpinner");
        $A.util.addClass(spinner, "slds-hide");
    },
    createNewRow:function(component,event,helper){
        var rows = component.get("v.allConditionsOrProperties");
        var newRow = {
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
        rows.push(newRow);
        component.set("v.allConditionsOrProperties",rows);
        helper.hideSpinner(component,event,helper);
    },
    getOperatorList : function(component, event, helper){
        var action = component.get("c.getFieldDropdownValues");
        var options = [];
        action.setParams({
            "recType"         : component.get("v.namespacePrefix")+'PC_SupportPlanActivity__c',
            "fieldApiName"    : component.get("v.namespacePrefix")+'PC_Operators__c'
        });
        action.setCallback(this,function(response){
            var state=response.getState();
            if('SUCCESS'==state){
                var operatorsList = response.getReturnValue();
                if(!$A.util.isEmpty(operatorsList)){
                    helper.initializeAttributes(component, event, helper, operatorsList);
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

    initializeAttributes : function(component, event, helper, operatorList){
        var builderContext = component.get("v.builderContext");
        if(builderContext != 'ConditionalBuilder'){
            component.set("v.showOperator",false);
        }

        //Operator Options 1 is for field types - Textarea, Reference, Formula, Checkbox etc.
        //Excluded field types - Date, Datetime, Percent, Double, Currency
        var constants = component.get("v.operatorConstants");
        var operatorOptions1 = []; //Equals, Does not Equals, Is Null, Is Not Null, Has not changed, Has changed, Contains, Does not contains
        var fieldTypeOperatorsMap = new Map();
        for (var index=0;index < operatorList.length;index++){
            var opt = operatorList[index];
            if(component.get("v.isSupportPlanTriggerEventConditions")){
               if(opt.value == constants.condOperatorEquals || opt.value == constants.condOperatorDoesNotEquals ||
                  opt.value == constants.condOperatorIsNotNull || opt.value == constants.condOperatorIsNull ||
                  opt.value == constants.condOperatorhasNotChanged || opt.value == constants.condOperatorhasChanged ||
                  opt.value == constants.condOperatorContains || opt.value == constants.condOperatorDoesNotContains){
                  operatorOptions1.push(opt);
               }
            }else {
                if(opt.value == constants.condOperatorEquals || opt.value == constants.condOperatorDoesNotEquals ||
                    opt.value == constants.condOperatorIsNull || opt.value == constants.condOperatorIsNotNull ||
                    opt.value == constants.condOperatorContains || opt.value == constants.condOperatorDoesNotContains){
                    operatorOptions1.push(opt);
                }
            }
        }

        fieldTypeOperatorsMap.set("MULTIPICKLIST",operatorOptions1);
        fieldTypeOperatorsMap.set("STRING",operatorOptions1);
        fieldTypeOperatorsMap.set("URL",operatorOptions1);
        fieldTypeOperatorsMap.set("EMAIL",operatorOptions1);
        fieldTypeOperatorsMap.set("PHONE",operatorOptions1);
        fieldTypeOperatorsMap.set("LONG TEXT AREA",operatorOptions1);
        fieldTypeOperatorsMap.set("RICH TEXT AREA",operatorOptions1);
        fieldTypeOperatorsMap.set("TEXTAREA",operatorOptions1);
        fieldTypeOperatorsMap.set("ENCRYPTEDSTRING",operatorOptions1);
        fieldTypeOperatorsMap.set("FORMULA",operatorOptions1);

        var operatorOptions3 = [];
        for (var index=0;index < operatorList.length;index++){
            var opt = operatorList[index];
            if(component.get("v.isSupportPlanTriggerEventConditions")){
               if(opt.value == constants.condOperatorEquals || opt.value == constants.condOperatorDoesNotEquals ||
                  opt.value == constants.condOperatorIsNotNull || opt.value == constants.condOperatorIsNull ||
                  opt.value == constants.condOperatorhasNotChanged || opt.value == constants.condOperatorhasChanged){
                  operatorOptions3.push(opt);
               }
            }else {
                if(opt.value == constants.condOperatorEquals || opt.value == constants.condOperatorDoesNotEquals ||
                    opt.value == constants.condOperatorIsNull || opt.value == constants.condOperatorIsNotNull){
                    operatorOptions3.push(opt);
                }
            }
        }
        //Equals, Does not Equals, Is Null, Is Not Null,
        //Has not changed, Has changed included for SP Trigger event conditions only
        fieldTypeOperatorsMap.set("PICKLIST",operatorOptions3);
        fieldTypeOperatorsMap.set("TIME",operatorOptions3);
        fieldTypeOperatorsMap.set("BOOLEAN",operatorOptions3);
        fieldTypeOperatorsMap.set("REFERENCE",operatorOptions3);
        fieldTypeOperatorsMap.set("COMBOBOX",operatorOptions3);
        component.set("v.defaultOperators",operatorOptions3);

        //Operator options 2 is for field types - Date, Datetime, Percent, Double, Currency
        var operatorOptions2 = operatorList;
        var options = [];
        if(!component.get("v.isSupportPlanTriggerEventConditions")){
            for(var s=0;s< operatorOptions2.length ; s++){
                var operator2 = operatorOptions2[s];
                if(operator2.value != constants.condOperatorContains && operator2.value != constants.condOperatorDoesNotContains &&
                operator2.value != constants.condOperatorhasNotChanged && operator2.value != constants.condOperatorhasChanged){
                    options.push(operator2);
                }
            }
        }else{
            for(var t=0;t< operatorOptions2.length ; t++){
                if(operatorOptions2[t].value != constants.condOperatorContains && operatorOptions2[t].value != constants.condOperatorDoesNotContains){
                    options.push(operatorOptions2[t]);
                }
            }
        }
        //Equals, Does not Equals, Is Null, Is Not Null, Has not changed, Has changed, Greater than or equal, Greater than
        //Less than or equal, Less than
        fieldTypeOperatorsMap.set("DATE",options);
        fieldTypeOperatorsMap.set("DATETIME",options);
        fieldTypeOperatorsMap.set("CURRENCY",options);
        fieldTypeOperatorsMap.set("DOUBLE",options);
        fieldTypeOperatorsMap.set("PERCENT",options);
        component.set("v.fieldTypeOperatorsMap", fieldTypeOperatorsMap);

        //Boolean options
        options = [];
        var valueOptions =  [
            {'label': $A.get("$Label.c.PC_True"), 'value': 'True'},
            {'label': $A.get("$Label.c.PC_False"), 'value': 'False'},
        ];
        for(var valueOption of valueOptions){
            var option = {
                'label' : valueOption.label,
                'value' : valueOption.value,
            };
            options.push(option);
        }
        component.set('v.booleanValues', options);

        //Condition Options
        var conditionOptions =   [
           {'label': $A.get("$Label.c.PC_Cond_Condition_AND"), 'value': 'AND'},
           {'label': $A.get("$Label.c.PC_Cond_Condition_OR"), 'value': 'OR'},
           {'label': $A.get("$Label.c.PC_Condition_CustomLogic"), 'value': 'PC_CustomLogic'},
        ];
        component.set('v.conditionOptions', conditionOptions);


        if(component.get("v.fetchedConditionsOrProperties")!= '' && !$A.util.isEmpty(component.get("v.fetchedConditionsOrProperties"))){
            if(component.get("v.showOperator")){
                var fetchedConditionsOrProperties = component.get("v.fetchedConditionsOrProperties");
                var ListConditionsPerObject = fetchedConditionsOrProperties;
                component.set("v.objectName",ListConditionsPerObject[0].ObjectType);
                component.set("v.fetchedConditionsOrProperties",ListConditionsPerObject[0].Conditions);
                var logic = ListConditionsPerObject[0].Logic;
                if((logic.includes('AND') && logic.includes('OR')) || logic.includes('(')){
                    component.set("v.conditionValue",'PC_CustomLogic');
                    component.set("v.conditionsCustomLogic",logic);
                    component.set("v.serverSideCustomLogicValid",true);
                }else if(logic.includes('AND')){
                    component.set("v.conditionValue", 'AND');
                }else if(logic.includes('OR')){
                    component.set("v.conditionValue", 'OR');
                }
            }
            helper.populateAllRows(component, event, helper);
        }else{
            if(!component.get("v.isSupportPlanTriggerEventConditions")){
                component.set("v.allConditionsOrProperties",[]);
                helper.createNewRow(component,event,helper);
            }
        }
    },

    validateData : function(component, event, helper){
        var isRowValid = true;
        var finalValidation = true;
        if(component.get("v.conditionsRequired")){
            var allRows = component.get("v.allConditionsOrProperties");
            var eachRowComponent;
            for(var g=0;g < allRows.length;g++){
                if(allRows.length == 1){
                    eachRowComponent = component.find('eachRowComponent')[0];
                    if(typeof eachRowComponent == 'undefined'){
                        eachRowComponent = component.find('eachRowComponent');
                    }
                }else{
                    eachRowComponent = component.find('eachRowComponent')[g];
                }
                isRowValid = eachRowComponent.validateRowData();
                if(!isRowValid){
                    finalValidation = false;
                }
            }
        }
        if(component.get("v.conditionValue") == 'PC_CustomLogic'){
            var logic = component.get("v.conditionsCustomLogic");
            if(logic == ""){
                var logicComponent = component.find("customLogic");
                $A.util.addClass(logicComponent,'slds-has-error');
                finalValidation = false;
            }else{
                $A.util.removeClass(logicComponent,'slds-has-error');
            }
        }
        return finalValidation;
    },
    validateServerSideLogic : function(component,event,helper){
        if(component.get("v.isCustomLogicValid")){
            var logicEvaluation = component.get("c.getLogicEvaluationResult");
            var logic = component.get("v.conditionsCustomLogic");
            var allRowNumbersInLogic =  logic.match(/\d+/g);
            for(var q = 0; q < allRowNumbersInLogic.length;q++){
                logic = logic.replace(allRowNumbersInLogic[q], 'TRUE');
            }
            logicEvaluation.setParams({
                "logic" : logic
            });
            logicEvaluation.setCallback(this,function(response){
                var state = response.getState();
                if(state == "SUCCESS"){
                    component.set("v.serverSideCustomLogicValid",true);
                }else if(state == "ERROR"){
                    var errors = response.getError();
                    var logicField = component.find('customLogic');
                    logicField.setCustomValidity(errors[0].message);
                    logicField.reportValidity();
                    component.set("v.serverSideCustomLogicValid",false);
                }
            });
            $A.enqueueAction(logicEvaluation);
        }else{
            helper.validateConditionLogic(component,event,helper);
        }
    },
    validateConditionLogic : function(component,event,helper){
        var allRows = component.get("v.allConditionsOrProperties");
        try{
            var logicWithSpaces = component.get("v.conditionsCustomLogic");
            var logic = logicWithSpaces.replace(/ /g,'');
            var logicField = component.find('customLogic');
            if(!$A.util.isEmpty(logic) && typeof logicField != 'undefined'){
                logicField.setCustomValidity("");
                var allRowNumbersInLogic =  logicWithSpaces.match(/\d+/g);
                component.set("v.serverSideCustomLogicValid",false);
                var i=0;
                var count = 0;
                var character='';
                var previousCharacter = '';
                if(allRowNumbersInLogic != null){
                    for(var rowNumber =1;rowNumber <= allRows.length;rowNumber++){
                        if(!allRowNumbersInLogic.includes(rowNumber.toString())){
                            logicField.setCustomValidity(component.get("v.allConditionsNotCovered"));//"All conditions are not covered in logic."
                        }
                    }
                    for(var eachNumber = 1; eachNumber <= allRowNumbersInLogic.length ; eachNumber++){
                        if(allRowNumbersInLogic[eachNumber] > allRows.length){
                            logicField.setCustomValidity(component.get("v.conditionNotFound"));//"Condition number not found."
                        }
                    }
                }
                while (i < logic.length){
                    character = logic.charAt(i);
                    if(i>0){
                        previousCharacter = logic.charAt(i-1);
                    }
                    if (!isNaN(character * 1)){

                    }else{
                        if (character == character.toLowerCase() && character != ')' && character != '('){
                            logicField.setCustomValidity(component.get("v.unexpectedIdentifier"));//"Unexpected Identifier"
                        }
                        if(previousCharacter != ''){
                            if(previousCharacter == 'R' && character == 'A'){
                                logicField.setCustomValidity(component.get("v.conditionBetweenOrAnd")); //"Include condition number between 'OR' and 'AND'."
                                break;
                            }
                            if(previousCharacter == 'D' && character == 'O'){
                                logicField.setCustomValidity(component.get("v.conditionBetweenAndOr"));//"Include condition number between 'AND' and 'OR'."
                                break;
                            }
                        }
                    }
                    i++;
                }
                if(logicField.checkValidity()){
                    var expression = logicWithSpaces;
                    for(var p = 0; p < allRowNumbersInLogic.length;p++){
                      	expression = expression.replace(allRowNumbersInLogic[p], false);
                    }
                    expression = expression.replaceAll('AND', '&&');
                    expression = expression.replaceAll('OR', '||');
                    expression = expression.replaceAll('NOT', '!');
                    var result = eval(expression);

                    var emptyExpression = expression.replaceAll(false,'');
                    emptyExpression = emptyExpression.replaceAll('&&','');
                    emptyExpression = emptyExpression.replaceAll('||','');
                    emptyExpression = emptyExpression.replaceAll('!','');
                    emptyExpression = emptyExpression.replaceAll(' ','');
                    emptyExpression = emptyExpression.replaceAll('(','');
                    emptyExpression = emptyExpression.replaceAll(')','');
                    if(emptyExpression != ''){
                        logicField.setCustomValidity(component.get("v.unexpectedIdentifier"));//"Unexpected Identifiers"
                    }
                }
                if(logicField.checkValidity()){
                    var useOrAndCondition = component.get("v.useOrAndCondition");
                    if(!logic.includes('AND') && !logic.includes('NOT')){
                        useOrAndCondition = useOrAndCondition.replace('{0}','OR');
                        logicField.setCustomValidity(useOrAndCondition);
                    }else if(!logic.includes('OR') && !logic.includes('NOT')){
                        useOrAndCondition = useOrAndCondition.replace('{0}','AND');
                        logicField.setCustomValidity(useOrAndCondition); //Please use AND condition instead of custom logic.
                    }
                }
            }
        }catch(error){
            if(typeof logicField != 'undefined'){
                logicField.setCustomValidity(error.message);
                var errorMessage = error.message;
                if(errorMessage.includes('true') || errorMessage.includes('false') || errorMessage.includes('&&') || errorMessage.includes('||') || errorMessage.includes('!')){
                    logicField.setCustomValidity(component.get("v.customLogicErrorMessage"));//"Unable to evaluate the condition logic. Please correct the syntax."
                }
            }
        }
        if(typeof logicField != 'undefined'){
            logicField.reportValidity();
            component.set("v.isCustomLogicValid",logicField.checkValidity());
        }
        if(allRows.length < 2){
            component.set("v.isCustomLogicValid",true);
            component.set("v.serverSideCustomLogicValid",true);
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
    populateAllRows : function(component, event, helper){
        var allConditionsOrProperties = component.get("v.fetchedConditionsOrProperties");
        var fetchedRow = '';
        var rowWithAllParameters ='';
        var fromValue = '';
        var toValue = '';
        var fieldType = '';
        var fieldApiName = '';
        var fieldLabel = '';
        var operator = '';
        var getDropdownValues;
        for(var row=0;row<allConditionsOrProperties.length;row++){
            getDropdownValues = true;
            rowWithAllParameters = {
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
                   'formulaValue' : {'isFormula':false,
                       'referenceFieldApiName': '',
                       'referenceFieldType': '',
                       'operation': '',
                       'offsetType': '',
                       'offsetValue': 0,
                       'offsetTypeOptions' : [],
                       'operationOptions' : []
                   },
                   'todayCheckboxValue' : false,
                   'nowCheckboxValue' : false,
                   'showToValueColumn' : false,
                   'fromAnyCheckboxValue' : false,
                   'toAnyCheckboxValue' : false,
                   'showLookUpHelpText' :  false,
                   'showNoOptionsError' : false
            };
            fetchedRow = allConditionsOrProperties[row];
            if(component.get("v.showOperator")){
                operator = fetchedRow.Operator;
                rowWithAllParameters.selectedField.operator = operator;
                if(operator ==  'Is null' || operator == 'Is not null' ||
                    operator == 'Has not changed'){
                    rowWithAllParameters.valueNeeded = false;
                }
                if(operator == 'Has changed'){
                    rowWithAllParameters.showToValueColumn = true;
                    toValue = fetchedRow.changeToValue;
                    if(row == 0){
                        component.set("v.showValueChangeToColumn",true);
                    }
                }
                fromValue = fetchedRow.Value;
                fieldType = fetchedRow.Type.toUpperCase();
                fieldApiName = fetchedRow.FieldApiName;
                fieldLabel = fetchedRow.FieldName;
                rowWithAllParameters.operatorOptions = helper.getOperatorOptions(component,event,helper,fieldType);
            }else{
                fromValue = fetchedRow.value;
                fieldType = fetchedRow.type.toUpperCase();
                fieldApiName = fetchedRow.apiName;
                fieldLabel = fetchedRow.label;
                //remove below if condition after release is around 20
                //Had to do this for backward compatibility as isDeleteAllowed is always stored as false for clients who are using SP
                if(component.get("v.objectName") == 'Task'){
                    rowWithAllParameters.isDeleteAllowed = fetchedRow.isDeleteAllowed;
                }
            }
            if(!component.get("v.showOperator") && fieldType == "PICKLIST"){
                if(fetchedRow.isBoundValue){
                    rowWithAllParameters.picklistBoundCheckboxValue = true;
                    rowWithAllParameters.selectedField.isBoundValue = fetchedRow.isBoundValue;
                    helper.showSpinner(component,event,helper);
                    helper.getFieldDropdownValues(component,event,helper,fieldApiName,row,fromValue,'',fieldType);
                    getDropdownValues = false;
                }
            }
            if(component.get("v.objectType") == 'Platform Event Object' && (fieldType == "TEXTAREA" || fieldType == "STRING")){
                if(fetchedRow.isBoundValue){
                    rowWithAllParameters.assignIdInPlatformEvent = true;
                    rowWithAllParameters.selectedField.isBoundValue = fetchedRow.isBoundValue;
                    helper.showSpinner(component,event,helper);
                    helper.getTriggerObjectLookupFields(component,event,helper,fieldApiName,row,fromValue);
                    getDropdownValues = false;
                }
            }
            if((fieldType == "PICKLIST" || fieldType == "MULTIPICKLIST") && getDropdownValues){
                helper.getFieldDropdownValues(component,event,helper,fieldApiName,row,fromValue,toValue,fieldType);
            }
            if(fieldType == "REFERENCE"){
                helper.getTriggerObjectLookupFields(component,event,helper,fieldApiName,row,fromValue);
            }
            if(fromValue == '--PC_Any--'){
                rowWithAllParameters.fromAnyCheckboxValue = true;
                fromValue = '';
            }else if(fromValue == '--PC_Today--'){
                rowWithAllParameters.todayCheckboxValue = true;
                fromValue = '';
            }else if(fromValue == '--PC_Now--'){
                rowWithAllParameters.nowCheckboxValue = true;
                fromValue = '';
            }else if(fromValue == '--PC_Formula--'){
                rowWithAllParameters.formulaValue.isFormula = true;
                rowWithAllParameters.selectedField.isBoundValue = fetchedRow.isBoundValue;
                rowWithAllParameters.formulaValue.referenceFieldType = fetchedRow.formulaValue.referenceFieldType;
                rowWithAllParameters.formulaValue.offsetType = fetchedRow.formulaValue.offsetType;
                rowWithAllParameters.formulaValue.offsetValue = fetchedRow.formulaValue.offsetValue;
                rowWithAllParameters.formulaValue.operation = fetchedRow.formulaValue.operation;
                fromValue = fetchedRow.formulaValue.referenceFieldApiName;
                helper.getDateReferenceOptions(component,event,helper,row);
            }
            if(toValue == '--PC_Any--'){
                rowWithAllParameters.toAnyCheckboxValue = true;
                toValue = '';
            }
            rowWithAllParameters.selectedField.label = fieldLabel;
            rowWithAllParameters.selectedField.apiName = fieldApiName;
            rowWithAllParameters.selectedField.type = fieldType.charAt(0).toUpperCase() + fieldType.slice(1).toLowerCase();
            rowWithAllParameters.selectedField.value = fromValue;
            rowWithAllParameters.selectedField.toValue = toValue;
            rowWithAllParameters.selectedField.operator = operator;
            allConditionsOrProperties.splice(row,1,rowWithAllParameters);
        }
        component.set("v.allConditionsOrProperties",allConditionsOrProperties);
        component.set("v.fetchedConditionsOrProperties",'');
    },
    getDateReferenceOptions : function(component,event,helper,row){
        var action = component.get("c.getAllFormulaOptions");
        action.setParams({
            "triggerEventObjectApiName" : component.get("v.triggerObjectName")
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state == "SUCCESS"){
                var dropdownValues = response.getReturnValue();
                var allRows = component.get("v.allConditionsOrProperties");
                allRows[row].selectedFieldDropdownValues = dropdownValues.dateAndDatetimeFields;
                allRows[row].formulaValue.offsetTypeOptions = dropdownValues.offsetTypeOptions;
                allRows[row].formulaValue.operationOptions = dropdownValues.operationOptions;
                component.set("v.allConditionsOrProperties",allRows);
            }else if(state == "ERROR"){
                var errors = response.getError();
                CH_PC_Util.showAllErrors(component.get("v.errorStatus"),errors);
            }else{
                console.log("unknown error");
            }
            helper.hideSpinner(component,event,helper);
        });
        $A.enqueueAction(action);
    },
    getObjectFields : function(component, event, helper){
        var action = component.get('c.getObjectFields');
        var includeRecordTypeId = false;
        if(component.get("v.triggerObjectName") == component.get("v.objectName")){
            includeRecordTypeId = true;
        }
        var ObjectFieldsRequests = [{
                "objectName"                    :   component.get("v.objectName"),
                "builderContext"                :   component.get("v.builderContext"),
                "includeRecordTypeId"           :   includeRecordTypeId,
        }];
        action.setParams({
            "ObjectFieldsRequests" : ObjectFieldsRequests
        });
        action.setCallback(this,function(response){
            var state=response.getState();
            if('SUCCESS'==state){
                var objectFields = response.getReturnValue();
                if(!$A.util.isEmpty(objectFields)){
                    component.set("v.objectFields", objectFields);
                    helper.getOperatorList(component, event, helper);
                    helper.setFieldsInFieldSelector(component,event,helper);
                }
            }else if (state === "ERROR") {
                  var errors = response.getError();
                  CH_PC_Util.showAllErrors(component.get("v.errorStatus"),errors);
                  helper.hideSpinner(component,event,helper);
            }else {
                console.log("Unknown error");
                helper.hideSpinner(component,event,helper);
            }
            if(component.get("v.isSupportPlanTriggerEventConditions")){
                helper.hideSpinner(component,event,helper);
            }
        });
        $A.enqueueAction(action);
    },

    setFieldsInFieldSelector : function(component, event, helper){
        var objectName = component.get("v.objectName");
        var allObjectFields = component.get("v.objectFields");
        var fieldsList = [];
        if(objectName != 'None'){
            if(allObjectFields==null){
                return;
            }
            for(var x=0;x<allObjectFields.length;x++){
               if(allObjectFields[x].objectName == objectName){
                   component.set("v.objectLabel",allObjectFields[x].objectLabel);
                   fieldsList = allObjectFields[x].fields;
               };
            }
            component.set("v.allFieldsList", fieldsList);
        }
    },
    getFieldDropdownValues : function(component, event, helper,fieldApiName,rowIndex,savedFromValue,savedToValue,fieldType){
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
                    var allRows = component.get("v.allConditionsOrProperties");
                    allRows[rowIndex].selectedFieldDropdownValues =  fieldDropdownValues;
                    allRows[rowIndex].multiSelectToDropdownValues =  JSON.parse(JSON.stringify(fieldDropdownValues));
                    allRows[rowIndex].selectedField.value =  fieldDropdownValues[0].value;
                    allRows[rowIndex].selectedField.toValue = fieldDropdownValues[0].value;
                    if(savedFromValue != '' && savedFromValue != '--PC_Any--'){
                        allRows[rowIndex].selectedField.value =  savedFromValue;
                    }
                    if(savedToValue != '' && savedToValue != '--PC_Any--'){
                        allRows[rowIndex].selectedField.toValue = savedToValue;
                    }
                    var rowComponent;
                    if(fieldType == 'MULTIPICKLIST'){
                        if(savedFromValue != '' && savedFromValue != '--PC_Any--'){
                            allRows[rowIndex].multiSelectFromValues = savedFromValue.split(';');
                        }
                        if(savedToValue != '' && savedToValue != '--PC_Any--'){
                            allRows[rowIndex].multiSelectToValues   = savedToValue.split(';');
                        }
                        if(allRows.length == 1){
                            rowComponent = component.find('eachRowComponent')[0];
                            if(typeof rowComponent == 'undefined'){
                                rowComponent = component.find('eachRowComponent');
                            }
                        }else{
                            rowComponent = component.find('eachRowComponent')[rowIndex];
                        }
                    }
                    component.set("v.allConditionsOrProperties",allRows);
                    if(fieldType == 'MULTIPICKLIST'){
                        if(!$A.util.isUndefinedOrNull(rowComponent)){
                            rowComponent.initiateMultiSelectCombobox();
                        }
                    }
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
    getLookupObjectName : function(component, event, helper){
        var objectName = component.get('v.objectName');
        var action = component.get('c.getLookupFieldObjectInfo');
        action.setParams({
            "selectedObject" : objectName,
            "lookupField" :component.get('v.fieldApiName')
        });
        action.setCallback(this,function(response){
            var state=response.getState();
            if('SUCCESS'==state){
                var lookupsObjectAPIName = response.getReturnValue();
                component.set('v.lookupObjectApiName',lookupsObjectAPIName);
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

    getTriggerObjectLookupFields : function(component, event, helper,fieldApiName,rowIndex,savedValue){
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
                    var allRows = component.get("v.allConditionsOrProperties");
                    if(!$A.util.isEmpty(fieldDropdownValues)){
                        var options = [];
                        if(component.get("v.builderContext") == 'PropertyBuilderInUpdate'){
                            var nullValue = {
                                "label" : $A.get("$Label.c.PC_Null"),
                                "value" : "NULL",
                            };
                            fieldDropdownValues.unshift(nullValue);
                        }
                        allRows[rowIndex].selectedFieldDropdownValues =  fieldDropdownValues;
                        allRows[rowIndex].selectedField.value =  fieldDropdownValues[0].value;
                        if(savedValue != ''){
                            allRows[rowIndex].selectedField.value = savedValue;
                        }
                        allRows[rowIndex].showLookUpHelpText =  true;
                        allRows[rowIndex].showNoOptionsError =  false;
                    }else{
                        allRows[rowIndex].showLookUpHelpText =  false;
                        allRows[rowIndex].showNoOptionsError =  true;
                    }
                    component.set("v.allConditionsOrProperties",allRows);
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
    getBuilderJSONToSave : function(component,event,helper){
        var isValid = helper.validateData(component,event,helper);
        if(!isValid || !component.get("v.isCustomLogicValid") || !component.get("v.serverSideCustomLogicValid")){
            return [false,''];
        }else{
            var allConditionsOrProperties = component.get("v.allConditionsOrProperties");
            var allRows =[];
            var builderContext = component.get("v.builderContext");
            var conditionsLogic = '';
            if(builderContext ==  'ConditionalBuilder' && allConditionsOrProperties.length >1){
                conditionsLogic = helper.getLogic(component,event,helper);
            }
            for(var index = 0; index < allConditionsOrProperties.length;index ++){
                var eachRow;
                if(allConditionsOrProperties.length ==1){
                    var eachRowComponent = component.find('eachRowComponent')[0];  //Had to write this logic as if the row is only sometimes cmp.find is returning array.
                    if(typeof eachRowComponent == 'undefined'){
                        eachRowComponent = component.find('eachRowComponent');
                    }
                    eachRow = eachRowComponent.get("v.row");
                }else{
                    eachRow = component.find('eachRowComponent')[index].get("v.row");
                }
                var  apiName = eachRow.selectedField.apiName;
                if(apiName == ""){
                    continue;
                }
                var value = eachRow.selectedField.value;
                var formulaValue = {};
                var toValue = eachRow.selectedField.toValue;
                if(eachRow.formulaValue.isFormula){
                    value = '--PC_Formula--';
                    eachRow.selectedField.isBoundValue = true;
                    formulaValue = {
                       "referenceFieldApiName": eachRow.selectedField.value,
                       "referenceFieldType": eachRow.formulaValue.referenceFieldType,
                       "operation": eachRow.formulaValue.operation,
                       "offsetType": eachRow.formulaValue.offsetType,
                       "offsetValue": parseInt(eachRow.formulaValue.offsetValue)
                    };
                }else if(eachRow.selectedField.type.toUpperCase() == 'MULTIPICKLIST' && !eachRow.fromAnyCheckboxValue){
                    value =  eachRow.multiSelectFromValues.toString().replaceAll(',',';');
                }else if(eachRow.todayCheckboxValue){
                    value = '--PC_Today--';
                }else if(eachRow.nowCheckboxValue){
                    value = '--PC_Now--';
                }else if(eachRow.fromAnyCheckboxValue){
                    value = '--PC_Any--';
                }
                if(eachRow.toAnyCheckboxValue){
                    toValue = '--PC_Any--';
                }else if(eachRow.selectedField.type.toUpperCase() == 'MULTIPICKLIST' && !eachRow.toAnyCheckboxValue &&
                        eachRow.selectedField.operator == 'Has changed'){
                    toValue = eachRow.multiSelectToValues.toString().replaceAll(',',';');
                }
                if(!eachRow.valueNeeded){
                    value = '';
                }
                if(builderContext == 'ConditionalBuilder'){
                    var eachCondition ;
                    if(component.get("v.isSupportPlanTriggerEventConditions")){
                        if(eachRow.selectedField.operator == 'Has changed'){
                            eachCondition = {
                                "ConditionNo" : index+1,
                                "FieldName" : eachRow.selectedField.label,
                                "FieldApiName" : eachRow.selectedField.apiName,
                                "Operator" : eachRow.selectedField.operator,
                                "Type" : eachRow.selectedField.type,
                                "Value" : value,
                                "changeToValue" : toValue
                            };
                        }else{
                            eachCondition = {
                                "ConditionNo" : index+1,
                                "FieldName" : eachRow.selectedField.label,
                                "FieldApiName" : eachRow.selectedField.apiName,
                                "Operator" : eachRow.selectedField.operator,
                                "Type" : eachRow.selectedField.type,
                                "Value" : value
                            };
                        }
                    }else{
                        eachCondition = {
                            "ConditionNo" : index+1,
                            "FieldName" : eachRow.selectedField.label,
                            "FieldApiName" : eachRow.selectedField.apiName,
                            "Operator" : eachRow.selectedField.operator,
                            "Type" : eachRow.selectedField.type,
                            "Value" : value
                        };
                    }
                    allRows.push(eachCondition);
                }else if(builderContext == 'PropertyBuilder' || builderContext == 'PropertyBuilderInUpdate'){
                    var eachProperty = {
                        "label" : eachRow.selectedField.label,
                        "apiName" : eachRow.selectedField.apiName,
                        "isDeleteAllowed" : eachRow.isDeleteAllowed,
                        "type" : eachRow.selectedField.type,
                        "value" : value,
                        "formulaValue": formulaValue,
                        "isBoundValue" : eachRow.selectedField.isBoundValue
                    };
                    allRows.push(eachProperty);
                }
            }//end of for loop

            if(builderContext == 'ConditionalBuilder'){
                var recordConditionsList = [];
                var recordConditions = {
                     "ObjectType" : component.get('v.objectName'),
                     "RecordValue": component.get('v.recordValue'),
                     "Conditions" : allRows,
                     "Logic" : conditionsLogic
                };
                recordConditionsList.push(recordConditions);
                var activityConditions = {
                    "LstConditionsPerObject" : recordConditionsList
                };
                return [true ,activityConditions];
            }else if(builderContext ==  'PropertyBuilder' || builderContext == 'PropertyBuilderInUpdate'){
                return [true,allRows];
            }
        }
    },
    getLogic : function(component,event,helper){
        var conditionOperator = '';
        var conditionLogic = '';
        var conditionValue = component.get("v.conditionValue");
        var allConditions = component.get("v.allConditionsOrProperties");
        if(conditionValue == 'PC_CustomLogic'){
            return component.get("v.conditionsCustomLogic");
        }else if(conditionValue == 'AND'){
            conditionOperator  = 'AND';
        }else if(conditionValue == 'OR'){
            conditionOperator = 'OR';
        }
        if(component.get("v.isSupportPlanTriggerEventConditions")){
            for(var i=1;i <= allConditions.length;i++){
                var eachRow = component.find('eachRowComponent')[i-1].get("v.row");
                var apiName = eachRow.selectedField.apiName;
                if(!$A.util.isEmpty(apiName)){
                    if(i==1){
                        conditionLogic= i;
                    }else{
                        conditionLogic = conditionLogic + ' '+ conditionOperator + ' ' + i;
                    }
                }
            }
        }else{
            for(var l =1; l<=allConditions.length;l++){
                if(l==allConditions.length){
                    conditionLogic = conditionLogic + l;
                }else{
                    conditionLogic = conditionLogic + l + ' '+ conditionOperator + ' ';
                }
            }
        }
        return conditionLogic;
    },
    handleComponentEvent : function(component,event,helper){
        component.set("v.showValueChangeToColumn",event.getParam("showToValueColumn"));
    },
    removeRow : function(component, event, helper){
        var allRows = component.get("v.allConditionsOrProperties");
        var index = event.getSource().get("v.value");
        var eachRow;
        var allConditionsOrProperties = [];
        for(var h=0;h<allRows.length;h++){
            if(h == index){
                continue;
            }
            eachRow = component.find("eachRowComponent")[h].get("v.row");
            allConditionsOrProperties.push(eachRow);
            if(component.get("v.isSupportPlanTriggerEventConditions")){
                var firstRowOperator = allConditionsOrProperties[0].selectedField.operator;
                if(firstRowOperator != 'Has changed'){
                    component.set("v.showValueChangeToColumn",false);
                }
            }
        }
        component.set("v.allConditionsOrProperties",allConditionsOrProperties);
    }
})