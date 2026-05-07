({
    hidePopupHelper: function(component, componentId, className){
        var modal = component.find(componentId); 
        $A.util.addClass(modal, className+'hide'); 
        $A.util.removeClass(modal, className+'open'); 
    },
    showPopupHelper: function(component, componentId, className, helper){ 
        var modal = component.find(componentId); 
        $A.util.removeClass(modal, className+'hide'); 
        $A.util.addClass(modal, className+'open');
        helper.cardHolderInfoChange(component);
    },
    searchRecordHelper : function(component, searchString) {
        var fieldWrapper = component.get("v.fieldWrapper");
        var action = component.get("c.getPayer");
        action.setParams({
            "searchString": searchString
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                component.set("v.lstPayers", returnValue);
                var lstFinalPayers = returnValue;
                for (var i=0; i<lstFinalPayers.length; i++){
                    if ($A.util.isEmpty(lstFinalPayers[i].payerType) || lstFinalPayers[i].payerType == "__none") {
                        lstFinalPayers[i].payerTypeLabel = "";
                    } else {
                        for (var j=0; j<fieldWrapper.Account_Type.lstOptions.length; j++){
                            if (lstFinalPayers[i].payerType == fieldWrapper.Account_Type.lstOptions[j].value){
                                lstFinalPayers[i].payerTypeLabel = fieldWrapper.Account_Type.lstOptions[j].label;
                                break;
                            }
                        }
                    }
                }
                component.set("v.lstPayers", lstFinalPayers);
            } else {
                console.log("Failed with state: " + state);
            }
        });
        
        $A.enqueueAction(action);
    },
    getServerStateHelper : function(component, helper) {
        var existingHealthPlan = component.get("v.existingHealthPlan");
        var patientId = component.get("v.enrollmentCase.accountId");
        var lstHealthPlan = component.get("v.lstHealthPlan");
        var pageErrors = [];
        var pageWarnings = []; //[PC-1469] Converted 'healthplan modified error' to a warning

        component.set("v.showSpinner",true);
    	var action = component.get("c.getHealthPlan");
        action.setParams({
            "patientId": patientId,
            "fieldSetName" : component.get("v.fsName")
        });
        action.setCallback(this, function(response) {
            component.set("v.showSpinner",false);
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                var existingCount = 0;
                var serverDataChanged=false;
                if(lstHealthPlan.length == 0){
                    component.set("v.lstHealthPlan", returnValue);
                } else {
                    //Count existing healthplan records in the saved state
                    for (var k=0; k<lstHealthPlan.length; k++){
                        if (lstHealthPlan[k].source == component.get("v.sourceExistingRecord")){
                            existingCount = existingCount + 1;
                        }
                    }
                    //if the saved records donot match the returnvalue -- copy new server data.
                    if (existingCount != returnValue.length){
                        //error msg to set the server state change message
                        serverDataChanged = true;
                        component.set("v.existingHealthPlan", returnValue);
                        existingHealthPlan = component.get("v.existingHealthPlan"); 
                    } else {
                        //iterate through the persistent data to check if the existing records have changed.
                        for (var i=0; i<lstHealthPlan.length; i++){
                            if (lstHealthPlan[i].source == component.get("v.sourceExistingRecord")){
                                for (var j=0; j<returnValue.length; j++){
                                    //match the existing records based on id and check for lastModifiedDate.
                                    if (returnValue[j].healthPlanId == lstHealthPlan[i].healthPlanId){
                                        if(returnValue[j].lastModifiedDate != lstHealthPlan[i].lastModifiedDate){
                                            //error msg to set the server state change message
                                            serverDataChanged = true;
                                            existingHealthPlan.push(returnValue[j]);
                                        } else {
                                            //if server state is not changed then persist the user value from the persistent data list.
                                            existingHealthPlan.push(lstHealthPlan[i]);
                                        }
                                    } 
                                }       
                            }
                        }
                    }
                    if (serverDataChanged){
                        pageWarnings.push(helper.getPageError(component)); //[PC-1469] Converted 'healthplan modified error' to a warning
                        
                    }
                    for (var l=0; l<lstHealthPlan.length; l++){
                        if (lstHealthPlan[l].source == component.get("v.sourceManuallyEntered") || lstHealthPlan[l].source == component.get("v.sourceOnline")){
                            existingHealthPlan.push(lstHealthPlan[l]);
                        }
                    }
                    component.set("v.lstHealthPlan", existingHealthPlan);
                }
            } else {
                console.log("Failed with state: " + state);
            }
            if(pageErrors.length > 0){
                component.set("v.pageErrors", pageErrors);
            }
            
            if(pageWarnings.length > 0){
                component.set("v.pageWarnings",pageWarnings);
            }
            helper.incrementWorkerCount(component);
            var lstFinalHealthPlan = component.get("v.lstHealthPlan");
            for (var m=0; m<lstFinalHealthPlan.length; m++){
                helper.getLabelForValue(component, lstFinalHealthPlan[m]);
            }
            component.set("v.lstHealthPlan",lstFinalHealthPlan);
        });
        
        $A.enqueueAction(action);
    },
    //Modified: TEJAS PATEL; Feb-07-2017; Logic for Required Fields    
    validateRequiredFields : function(component, fieldArray, isOnlineApplicantContext) {
        var requiredFieldErrorMessage	= component.get("v.requiredFieldErrorMessage");
        var currentHealthPlan = component.get("v.newHealthPlan");

        for (var i = 0; i < fieldArray.length; i++){
            if(($A.util.isEmpty(component.find(fieldArray[i]).get("v.value")) || component.find(fieldArray[i]).get("v.value") === "__none")){
                var inputCmp = component.find(fieldArray[i]);
                if(isOnlineApplicantContext) {
                    currentHealthPlan.isValid = false;
                }
                else {
                    inputCmp.set("v.errors", [{message:requiredFieldErrorMessage}]);
                    component.set("v.errorCheck",false);
                    currentHealthPlan.isValid = false;
                }
            }
        }
        component.set("v.newHealthPlan", currentHealthPlan);
    },

    getLabelForValue : function (component, newHealthPlan){
        var fieldWrapper = component.get("v.fieldWrapper");

        if ($A.util.isEmpty(newHealthPlan.healthPlanType) || newHealthPlan.healthPlanType == "__none") {
            newHealthPlan.healthPlanTypeLabel = "";
        } else {
            for (var j=0; j<fieldWrapper.PC_Health_Plan__c_PC_Plan_Type__c.lstOptions.length; j++){
                if (newHealthPlan.healthPlanType == fieldWrapper.PC_Health_Plan__c_PC_Plan_Type__c.lstOptions[j].value){
                    newHealthPlan.healthPlanTypeLabel = fieldWrapper.PC_Health_Plan__c_PC_Plan_Type__c.lstOptions[j].label;
                    break;
                }
            }
        }

        if ($A.util.isEmpty(newHealthPlan.recordName) || newHealthPlan.recordName == "__none") {
            newHealthPlan.recordNameLabel = "";
        } else {
            for (var k=0; k<fieldWrapper.PC_Health_Plan__c_RecordTypeId.lstRecordTypeOptions.length; k++){
                if (newHealthPlan.recordName == fieldWrapper.PC_Health_Plan__c_RecordTypeId.lstRecordTypeOptions[k].value){
                    newHealthPlan.recordNameLabel = fieldWrapper.PC_Health_Plan__c_RecordTypeId.lstRecordTypeOptions[k].label;
                    break;
                }
            }
        }
    },
    
    //Modified: TEJAS PATEL; Feb-07-2017; Logic for Clearing Error Message
    clearErrorMessage : function (component, fieldArray){
        for (var i = 0; i < fieldArray.length; i++){
            var inputCmp = component.find(fieldArray[i]);
            inputCmp.set("v.errors", [{message:""}]);
        }
    },

    clearErrorMessageLightning : function (component, fieldArray){
            for (var i = 0; i < fieldArray.length; i++){
                var inputCmp = component.find(fieldArray[i]);
                //inputCmp.set("v.errors", [{message:""}]);
                inputCmp.setCustomValidity("");
                inputCmp.reportValidity();
            }
        },
    
    //Modified: TEJAS PATEL; Feb-07-2017; Logic for Expiration and Effective Dates
    validateExpirationDate : function (component, isOnlineApplicantContext){
        var healthPlanEffectiveDate 		= new Date(component.find ("healthPlanEffectiveDate").get("v.value"));
        var healthPlanExpirationDate 		= new Date(component.find ("healthPlanExpirationDate").get("v.value"));
        var effectiveDateFieldErrorMessage	= component.get("v.effectiveDateFieldErrorMessage");
        var expirationDateFieldErrorMessage	= component.get("v.expirationDateFieldErrorMessage");
        
        var currentHealthPlan = component.get("v.newHealthPlan");
       
        if(healthPlanEffectiveDate >= healthPlanExpirationDate){
            if(isOnlineApplicantContext) {
                currentHealthPlan.isValid = false;
            }
            else {
                var inputCmp = component.find("healthPlanEffectiveDate");
                //inputCmp.set("v.errors", [{message:effectiveDateFieldErrorMessage}]);
                inputCmp.setCustomValidity(effectiveDateFieldErrorMessage);
                inputCmp.reportValidity();
                
                var expirationDate = component.find("healthPlanExpirationDate");
                //inputCmp.set("v.errors", [{message:expirationDateFieldErrorMessage}]);
                expirationDate.setCustomValidity(expirationDateFieldErrorMessage);
                expirationDate.reportValidity();
                component.set("v.errorCheck",false);
                    
                currentHealthPlan.isValid = false;
            }
        }
    },
    
    //Modified: TEJAS PATEL; Feb-07-2017; Logic for checking if payer is validated
    checkValidate : function(component, isOnlineApplicantContext){
        var validatePayer	= component.get("v.validatePayerErrorMessage");
        var checkValidate = component.get("v.isValidated");
        
        var currentHealthPlan = component.get("v.newHealthPlan");
        if(checkValidate == false){
            if(isOnlineApplicantContext) {
                currentHealthPlan.isValid = false;
            }
            else {
                var inputCmp = component.find("tovalidatepayerName");
                inputCmp.set("v.errors", [{message:validatePayer}]);
                component.set("v.errorCheck",false);
                
                currentHealthPlan.isValid = false;
            }
        }
        component.set("v.newHealthPlan", currentHealthPlan);
    },
    
    //Modified: TEJAS PATEL; Feb-07-2017; Logic for DOB
    validateDOB : function (component, isOnlineApplicantContext){
        var cardholdersBirthDate 	= new Date(component.find ("cardholdersBirthDate").get("v.value"));
        var toadyDate			 	= new Date();
        var dobFieldErrorMessage	= component.get("v.dobFieldErrorMessage");
        
        var currentHealthPlan = component.get("v.newHealthPlan");
        
        if(cardholdersBirthDate > toadyDate){
            if(isOnlineApplicantContext) {
                currentHealthPlan.isValid = false;
            }
            else {
                var inputCmp = component.find("cardholdersBirthDate");
                //inputCmp.set("v.errors", [{message:dobFieldErrorMessage}]);
                inputCmp.setCustomValidity(dobFieldErrorMessage);
                inputCmp.reportValidity();
                component.set("v.errorCheck",false);
                currentHealthPlan.isValid = false;
            }
        }
        component.set("v.newHealthPlan", currentHealthPlan);
    },
    setFieldSetObject : function(cmp, event, helper) {
        if(cmp.get("v.fsName") != null) {
            cmp.set("v.showSpinner",true);
            var action = cmp.get('c.getFieldSetFields');
            action.setParams({
                fsName: cmp.get('v.fsName'),
                typeName: cmp.get('v.typeName')
            });
            action.setCallback(this, 
                               function(response) {
                                   cmp.set("v.showSpinner",false);
                                   console.log('FieldSetForm HealthPlan Helper -  getFields callback start');
                                   var fields = response.getReturnValue();
                                   var renamedFields = {};
                                   var obj = {};
                                   if(fields != null && fields.length > 0) {
                                       for (var key in fields) {
                                           if (fields.hasOwnProperty(key)) {
                                               obj[fields[key].fieldPath.replace('.','___')] = '';
                                               console.log(key + " -> " + fields[key].fieldPath.replace('.','___'));
                                               
                                           }
                                       }                                               
                                       console.log('FieldSetForm HealthPlan Helper -  ] getFields callback end');
                                       var hp = cmp.get("v.newHealthPlan");
                                       var oldHp = JSON.parse(JSON.stringify(hp));
                                       oldHp.fsFields = obj;
                                       cmp.set("v.newHealthPlan",oldHp);

                                       helper.createFieldSetCmp(cmp, event, helper, fields);
                                   }
                                   else {
                                       console.log('No fields found from fieldset');
                                   }
                               }
                              );
            $A.enqueueAction(action);
        }
        
        
    },
    setDefaultValueForFieldSetFields : function(cmp, event, helper, currentHealthPlan) { 
        var fsFields = cmp.get("v.healthPlanFieldSetFields");
        var currentHpFsFields = currentHealthPlan.fsFields;
        if(!$A.util.isEmpty(fsFields)) {
            var HpField = '';
            for(var i=0; i<fsFields.length; i++) {
                HpField = fsFields[i].fieldPath;
                if($A.util.isEmpty(currentHpFsFields[HpField])) {
                   currentHpFsFields[HpField] = "";
                }
            }
            currentHealthPlan.fsFields = currentHpFsFields;
        }
        
    },
    setBlankValueForFieldSetFields : function(cmp, event, helper, currentHealthPlan) { 
        var fsFields = cmp.get("v.healthPlanFieldSetFields");
        var currentHpFsFields = currentHealthPlan.fsFields;
        if(!$A.util.isEmpty(fsFields)) {
            var HpField = '';
            for(var i=0; i<fsFields.length; i++) {
                HpField = fsFields[i].fieldPath;
                
                currentHpFsFields[HpField] = null;
                
            }
            currentHealthPlan.fsFields = currentHpFsFields;
        }
        
    },
    createFieldSetCmp : function(cmp, event, helper, fields) {
        debugger;
        $A.createComponent(
            cmp.get("v.namespace") + ":PC_FieldSetForm",
            {
                "fsName": cmp.get("v.fsName"),
                "typeName": cmp.get("v.typeName"),
                "record": cmp.getReference("v.newHealthPlan.fsFields"),
                "isValid" : cmp.getReference("v.isFieldSetFormValid")
            },
            function(newCmp, status, errorMessage){
                if (status === "SUCCESS") {
                    var body = cmp.get("v.fieldSetFormBody");
                    body.pop(); // necessary to remove items added earlier
                    body.push(newCmp);
                    cmp.set("v.fieldSetFormBody", body);
                    var existingFields = cmp.get("v.healthPlanFieldSetFields");
                    if($A.util.isEmpty(existingFields)) {
                        cmp.set("v.healthPlanFieldSetFields",fields);
                    }
                }
                else if (status === "INCOMPLETE") {
                    console.log("No response from server or client is offline.")
                }
                    else if (status === "ERROR") {
                        console.log("Error: " + errorMessage);
                    }
            }
        );
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
    validateFieldSetForm :function(component,isOnlineApplicantContext) {
        
        if(component.get("v.fieldSetFormBody") != null && component.get("v.fieldSetFormBody").length > 0) {
            var fieldSetCmp = component.get("v.fieldSetFormBody")[0];
            fieldSetCmp.validate();
            
            var currentHealthPlan = component.get("v.newHealthPlan");
		    if(!component.get("v.isFieldSetFormValid")) {
                if(isOnlineApplicantContext) {
                   currentHealthPlan.isValid = false; 
                }
                else {
                	component.set("v.errorCheck",false);
                    currentHealthPlan.isValid = false;
                }
            }
            component.set("v.newHealthPlan", currentHealthPlan);
        }
    },
    setConfiguration : function(component) {
    	var config = component.get("v.config");
        if(config != null) {
            var parsedConfig = JSON.parse(config);
            component.set("v.metaDataConfig", parsedConfig);
            console.log("Config as in custom metadata...");
            console.log(parsedConfig);
            var fieldSetName = parsedConfig["AdditionalInfo"]["fieldSet"];
            var ignoreFields = parsedConfig["AdditionalInfo"]["ignoreFields"];
            var replaceTarget = parsedConfig["AdditionalInfo"]["replaceTarget"];
            var replaceText = parsedConfig["AdditionalInfo"]["replaceText"];
            /*
            if(component.get("v.metaDataConfig") != null && component.get("v.metaDataConfig")['fieldSet'] != null) {
                component.set("v.fsName", component.get("v.namespacePrefix") + component.get("v.metaDataConfig")['fieldSet']);
            }*/
            if (!$A.util.isUndefinedOrNull(fieldSetName)) {
                //component.set("v.fsName", component.get("v.namespacePrefix") + fieldSetName);
                component.set("v.fsName", fieldSetName);
            }
            if (!$A.util.isUndefinedOrNull(ignoreFields)) {
                var ignoreFields_WithNamespace = [];
                for(var i=0; i<ignoreFields.length; i++) {
                    //ignoreFields_WithNamespace.push(component.get("v.namespacePrefix") + ignoreFields[i]);
                    ignoreFields_WithNamespace.push(ignoreFields[i]);
                }
                component.set("v.ignoreFields", ignoreFields_WithNamespace);
            }
            if (!$A.util.isUndefinedOrNull(replaceTarget)) {
                component.set("v.replaceTarget", replaceTarget);
            }
            if (!$A.util.isUndefinedOrNull(replaceText)) {
                component.set("v.replaceText", replaceText);
            }
        }        
    },
    getPageError : function(component) {
        var pageError = component.get("v._pageError");
        var pageErrorReplacements = component.get("v._pageErrorReplacements");
        for(var replacement in pageErrorReplacements) {
            if(pageErrorReplacements.hasOwnProperty(replacement)) {
            	pageError = pageError.replace(replacement,pageErrorReplacements[replacement]);
            }
        }
        console.log(pageError);
        return pageError;
    },
    validateExistingData : function(component, event, helper, index) {
        var existingPlans = component.get("v.lstHealthPlan");
        var validatedExistingPlans = existingPlans;
        if(index == -1) {
            for(var i=0; i<existingPlans.length; i++) {
                existingPlans[i].isValid = true;
                component.set("v.newHealthPlan", existingPlans[i]);
                component.set("v.healthPlanIndex",i);
                    
                if(existingPlans[i].source == component.get("v.sourceOnline")){
                    helper.validateExistingDataHelper(component, event, helper, true);
                }
                
                validatedExistingPlans[i] = component.get("v.newHealthPlan");
            }
        }
        else {
            component.set("v.newHealthPlan", existingPlans[index]);
            component.set("v.healthPlanIndex",index);
            helper.validateExistingDataHelper(component, event, helper, false);
            validatedExistingPlans[i] = component.get("v.newHealthPlan");
        }
        component.set("v.lstHealthPlan", validatedExistingPlans);
    },
    validateExistingDataHelper: function(component, event, helper, isOnlineApplicantContext){
        if(isOnlineApplicantContext) {
         	if(component.get("v.newHealthPlan").isValid) helper.validatePayerInOnlineContext(component, event, helper);
            if(component.get("v.newHealthPlan").isValid) helper.validateRequiredFields(component, ['recordName'], isOnlineApplicantContext);
            if(component.get("v.newHealthPlan").isValid) helper.validateExpirationDate(component, isOnlineApplicantContext);
            if(component.get("v.newHealthPlan").isValid) helper.validateDOB(component, isOnlineApplicantContext);
            if(component.get("v.newHealthPlan").isValid) helper.validateFieldSetForm(component,isOnlineApplicantContext);
        }
        else {
            helper.validatePayerInOnlineContext(component, event, helper);
            helper.checkValidate(component,isOnlineApplicantContext);
            helper.validateRequiredFields(component, ['recordName'], isOnlineApplicantContext);
            helper.validateExpirationDate(component, isOnlineApplicantContext);
            helper.validateDOB(component, isOnlineApplicantContext);
            helper.validateFieldSetForm(component,isOnlineApplicantContext);
        }
    },
    validatePayerInOnlineContext : function(component, event, helper) {
       	var currentHealthPlan = component.get("v.newHealthPlan");
        var payerName = currentHealthPlan.payerName;
        var payerRefId = currentHealthPlan.payerRef;
        if(component.get("v.isEdit")){
            if(payerRefId == null || payerRefId == undefined || payerRefId.trim() == '') {
                    currentHealthPlan.isValid = false;
                    if(payerName != null && payerName != undefined && payerName.trim()!= '') {  
                        component.set("v.searchString", payerName);
                        component.set("v.isValidated", false);
                    }
            }
        }
        else {
            if(payerRefId == null || payerRefId == undefined || payerRefId.trim() == '') {
                    currentHealthPlan.isValid = false;
            }
        }
        component.set("v.newHealthPlan", currentHealthPlan);
        
    },
    handleOnlineForm : function(component, enrollmentCaseId, helper) {
        component.set("v.showSpinner",true);
        var action = component.get("c.getApplicantHealthPlans");
        action.setParams({
                "enrollmentCaseId"	: enrollmentCaseId,
                "activeApplicantId"	: component.get("v.enrollmentCase.applicantId"), //[PC-1379] Handles multiple applicants on enrollment case
            	"fieldSetName" : component.get("v.fsName"),
                "ignoreFields": component.get("v.ignoreFields"),
                "replaceTarget":component.get("v.replaceTarget"),
                "replaceText": component.get("v.replaceText")
        });
        
        action.setCallback(this, function(a) {
            component.set("v.showSpinner",false);
            if(a.getState() ==="SUCCESS") {
                var returnValue = a.getReturnValue();
                component.set("v.onlineApplicantHealthPlans",returnValue);
                var lstFinalApplicantHealthPlan = component.get("v.onlineApplicantHealthPlans");
                for (var i=0; i<lstFinalApplicantHealthPlan.length; i++){
                    helper.getLabelForValue(component, lstFinalApplicantHealthPlan[i]);
                }
                component.set("v.onlineApplicantHealthPlans",lstFinalApplicantHealthPlan);
                var onlineApplicantHealthPlans = component.get("v.onlineApplicantHealthPlans");
				var showRefTable;
                if($A.util.isUndefinedOrNull(onlineApplicantHealthPlans) || onlineApplicantHealthPlans =='') {
                    console.log("OnlineApplicantHealthPlans on online form not found");
                    showRefTable = false; 
                }else{
                    showRefTable = true;
                }
                
                component.set("v.showRefTable", showRefTable);
		   } else if (a.getState() ==="ERROR") {
                var errors = a.getError();
                console.log(JSON.stringify(errors));
                var errText = component.get("v.ErrorText");
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log(errText);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
            helper.incrementWorkerCount(component);
        });
        $A.enqueueAction(action);
     
    },
    incrementWorkerCount : function(component) {
        var i = component.get("v.numWorkers");
        i++;
        component.set("v.numWorkers", i);
    },
    updateActionIndicators : function(component) {
        var onlineApplicantHealthPlans = component.get("v.onlineApplicantHealthPlans");
        var lstHealthPlan = component.get("v.lstHealthPlan");
        for(var i=0; i<onlineApplicantHealthPlans.length; i++) {
            for(var j=0; j<lstHealthPlan.length; j++) {
                if(lstHealthPlan[j].applicantSourceId == onlineApplicantHealthPlans[i].applicantSourceId) {
                    onlineApplicantHealthPlans[i].isApplicantSelected = true;
                    lstHealthPlan[j].isApplicantSelected = true;
                    break;
                }
            }
        }
        component.set("v.onlineApplicantHealthPlans", onlineApplicantHealthPlans);
        component.set("v.lstHealthPlan",lstHealthPlan);
    },
    
    cardHolderInfoChange : function(component) {
        var cardholderRelationshipToPatient 		= component.find("cardholderRelationshipToPatient");
        var cardholderRelationshipToPatientValue 	= cardholderRelationshipToPatient.get("v.value");
        
        var cardholderName 				= component.find("cardholderName");
        var cardholdersBirthDate 		= component.find("cardholdersBirthDate");
        if(cardholderRelationshipToPatientValue == "Self"){
            $A.util.addClass(cardholderName, 'selfCardHolder'); 
        	$A.util.addClass(cardholdersBirthDate, 'selfCardHolder');
            cardholderName.set("v.disabled",true);
            cardholdersBirthDate.set("v.disabled",true);
        }else{
            $A.util.removeClass(cardholderName, 'selfCardHolder');  
        	$A.util.removeClass(cardholdersBirthDate, 'selfCardHolder');
            cardholderName.set("v.disabled",false);
            cardholdersBirthDate.set("v.disabled",false);
        }
    }
})