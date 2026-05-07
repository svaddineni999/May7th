({

    doInit : function (component, event, helper){
        helper.setNamespace(component);
        helper.setConfiguration(component);
        var nhp = {};
        nhp.fsFields = {};
        component.set("v.newHealthPlan",nhp);

        component.set("v.showSpinner",true);
        var action = component.get("c.getFieldLabel");
        action.setCallback(this, function(response) {
            component.set("v.showSpinner",false);
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                component.set("v.fieldWrapper", returnValue);
                console.log(returnValue);
            } else {
                console.log("Failed with state: " + state);
            }
        });
        
        $A.enqueueAction(action);
        
        helper.getServerStateHelper(component, helper);
        helper.setFieldSetObject(component, event, helper);
        
        if(component.get("v.enrollmentCase.isOnlineApplicant")) {
            var enrollmentCaseId = component.get("v.enrollmentCase.enrollmentId");
            helper.handleOnlineForm(component, enrollmentCaseId, helper);
        }
   },
    

    dontModalBox : function(component, event, helper) {
        helper.hidePopupHelper(component, 'modaldialog', 'slds-fade-in-');
        helper.hidePopupHelper(component, 'backdrop', 'slds-backdrop--');
        component.set("v.isSearchPayer",false);
        component.set("v.isValidated",false);
        component.set("v.addHealthPlan",true);
        component.set("v.addHealthPlanButton",true);
        component.set("v.editHealthPlan",false);
        component.set("v.isEdit",false);
        
        var newHealthPlan = {};
        newHealthPlan = {
            healthPlanId : "",
            groupNo : "",
            policyNo : "",
            cardholderName : "",
            cardholderEmployer : "",
            cardholderRelationshipToPatient : "",
            cardholdersBirthDate : "",
            healthPlanEffectiveDate : "",
            healthPlanExpirationDate : "",
            payerRef : "",
            payerName : "",
            healthPlanClaimCardNo : "",
            healthPlanStatus : "",
            healthPlanType : "",
            healthPlanTypeLabel : "",
            planRxBin : "",
            planRxGrp : "",
            planRxPCN : "",
            recordName : "",
            recordNameLabel : "",
            source : component.get("v.sourceManuallyEntered"),
            fsFields : new Object(),
            isValid : true,
            applicantSourceId: "",
            isApplicantSelected: false
        };
        helper.setDefaultValueForFieldSetFields(component, event, helper, newHealthPlan);
        component.set("v.newHealthPlan",newHealthPlan);
        
        event.preventDefault();
        return false;
    },
    
    addNewPlan : function(component, event, helper) {
        debugger;
        setTimeout(function(){
            component.find("tovalidatepayerName").getElement().focus();
        }, 100);
        component.set("v.searchString","");
        //Modified: TEJAS PATEL; Feb-07-2017; Call method to clear error messages on New Modal Box Open
        helper.clearErrorMessage(component , ['recordName', 'tovalidatepayerName']);
        helper.clearErrorMessageLightning(component , ['healthPlanExpirationDate', 'healthPlanEffectiveDate', 'cardholdersBirthDate']);
        
        //var newHealthPlan = component.get("v.newHealthPlan");        
        var newHealthPlan = {};
        newHealthPlan = {
            healthPlanId : "",
            groupNo : "",
            policyNo : "",
            cardholderName : "",
            cardholderEmployer : "",
            cardholderRelationshipToPatient : "",
            cardholdersBirthDate : "",
            healthPlanEffectiveDate : "",
            healthPlanExpirationDate : "",
            payerRef : "",
            payerName : "",
            healthPlanClaimCardNo : "",
            healthPlanStatus : "",
            healthPlanType : "",
            healthPlanTypeLabel : "",
            planRxBin : "",
            planRxGrp : "",
            planRxPCN : "",
            recordName : "",
            recordNameLabel : "",
            source : component.get("v.sourceManuallyEntered"),
            fsFields : new Object(),
            isValid : true,
            applicantSourceId: "",
            isApplicantSelected: false
        };
        helper.setDefaultValueForFieldSetFields(component, event, helper, newHealthPlan);
        component.set("v.newHealthPlan",newHealthPlan);
        
        helper.showPopupHelper(component, 'modaldialog', 'slds-fade-in-', helper);
        helper.showPopupHelper(component,'backdrop','slds-backdrop--', helper);

        helper.createFieldSetCmp(component, event, helper, Object.keys(newHealthPlan.fsFields));
    },
    
    addNewPlanViaApplicant : function(component, event, helper) {
        component.set("v.searchString","");
        var onlineApplicantHealthPlans = component.get("v.onlineApplicantHealthPlans");
        var selectedTargetNode = event.currentTarget;
        var selectedTargetNodeIndex = selectedTargetNode.dataset.text;
        var selectedHealthPlan = JSON.parse(JSON.stringify(onlineApplicantHealthPlans[selectedTargetNodeIndex]));
        //var selectedHealthPlan = onlineApplicantHealthPlans[selectedTargetNodeIndex];
        
        helper.clearErrorMessage(component , ['recordName', 'tovalidatepayerName']);
        helper.clearErrorMessageLightning(component , ['healthPlanExpirationDate', 'healthPlanEffectiveDate', 'cardholdersBirthDate']);
        
        //var newHealthPlan = component.get("v.newHealthPlan");        
        var newHealthPlan = {
            healthPlanId : "",
            groupNo : selectedHealthPlan.groupNo,
            policyNo : selectedHealthPlan.policyNo,
            cardholderName : selectedHealthPlan.cardholderName,
            cardholderEmployer : selectedHealthPlan.cardholderEmployer,
            cardholderRelationshipToPatient : selectedHealthPlan.cardholderRelationshipToPatient,
            cardholdersBirthDate : selectedHealthPlan.cardholdersBirthDate,
            healthPlanEffectiveDate : selectedHealthPlan.healthPlanEffectiveDate,
            healthPlanExpirationDate : selectedHealthPlan.healthPlanExpirationDate,
            healthPlanClaimCardNo : selectedHealthPlan.healthPlanClaimCardNo,
            healthPlanStatus : selectedHealthPlan.healthPlanStatus,
            healthPlanType : selectedHealthPlan.healthPlanType,
            healthPlanTypeLabel : selectedHealthPlan.healthPlanTypeLabel,
            planRxBin : selectedHealthPlan.planRxBin,
            planRxGrp : selectedHealthPlan.planRxGrp,
            planRxPCN : selectedHealthPlan.planRxPCN,
            recordName : selectedHealthPlan.recordName,
            recordNameLabel : selectedHealthPlan.recordNameLabel,
            source : component.get("v.sourceOnline"),
            fsFields : selectedHealthPlan.fsFields,
            isValid : true,
            applicantSourceId: selectedHealthPlan.applicantSourceId,
            isApplicantSelected: false
        };
        helper.setDefaultValueForFieldSetFields(component, event, helper, newHealthPlan);
        console.log('called when adding from online applicant');
        helper.getLabelForValue(component, newHealthPlan);
		component.set("v.searchString", selectedHealthPlan.payerName);
		component.set("v.isValidated", false);
        component.set("v.newHealthPlan",newHealthPlan);
        helper.showPopupHelper(component, 'modaldialog', 'slds-fade-in-', helper);
        helper.showPopupHelper(component,'backdrop','slds-backdrop--', helper);
        helper.createFieldSetCmp(component, event, helper, Object.keys(newHealthPlan.fsFields));
    },
    
    searchRecord : function(component, event, helper) {
        component.set("v.lstPayers",[]);
        var inputCmp = component.find("searchPayerName");
        inputCmp.set("v.errors", [{message:""}]);
        var searchString = component.get("v.searchString");
        var searchStringErrorMessage = component.get("v.searchStringErrorMessage");
        if(searchString != "" && searchString.trim().length >= 2) {
        	helper.searchRecordHelper(component, searchString);
        }
        else {
                inputCmp.set("v.errors", [{message:searchStringErrorMessage}]);
        }

        event.preventDefault();
        return false;
    },
    
    openSearch : function(component, event, helper){
        debugger;
        component.set("v.lstPayers",[]);
        component.set("v.isSearchPayer",true);
        component.set("v.isValidated",true);
        component.set("v.addHealthPlan",false);
        component.set("v.addHealthPlanButton",false);
        component.set("v.editHealthPlan",false);
        component.find('searchPayerName').getElement().focus();

        var validatePayerName = component.get("v.searchString");
        helper.searchRecordHelper(component, validatePayerName);
        event.preventDefault();
        return false;
    },
    
    onSelect : function(component, event, helper) {
        var index = event.getSource().get("v.text");
        var lstPayers = component.get("v.lstPayers");
        lstPayers[index]['isSelected'] = "true";
        component.set("v.selectedPayer",lstPayers[index]);
        var payerName = component.get("v.selectedPayer.payerName")
        component.set("v.newHealthPlan.payerName",payerName);
        var payerRef = component.get("v.selectedPayer.payerId")
        component.set("v.newHealthPlan.payerRef",payerRef);
                
        component.set("v.isSearchPayer",false);
        component.set("v.isValidated",true);
        component.set("v.addHealthPlan",true);
        
        var editPlan = component.get("v.isEdit");
        if (editPlan == true){
            component.set("v.addHealthPlanButton",false);
            component.set("v.editHealthPlan",true);
        } else {
            component.set("v.addHealthPlanButton",true);
            component.set("v.editHealthPlan",false);
        }
        
    },
    
    editHealthPlan : function(component, event, helper){
        var index = event.currentTarget.dataset.text; //[PC-1464] Replaced 'Remove' text with icon
        var lstHealthPlan = component.get("v.lstHealthPlan");
        var currentHealthPlan = JSON.parse(JSON.stringify(lstHealthPlan[index]));
        helper.setDefaultValueForFieldSetFields(component, event, helper, currentHealthPlan);
        component.set("v.newHealthPlan",currentHealthPlan);
        component.set("v.healthPlanIndex",index);
        
        helper.showPopupHelper(component, 'modaldialog', 'slds-fade-in-', helper);
        helper.showPopupHelper(component,'backdrop','slds-backdrop--', helper);
        component.set("v.isSearchPayer",false);
        component.set("v.isValidated",true);
        component.set("v.addHealthPlan",true);
        component.set("v.addHealthPlanButton",false);
        component.set("v.editHealthPlan",true);
        component.set("v.isEdit",true);
        
        //helper.validateExistingData(component, event, helper, index);

        helper.createFieldSetCmp(component, event, helper, Object.keys(currentHealthPlan.fsFields));
    },
    
    removeHealthPlan : function(component, event, helper){
		var index = event.currentTarget.dataset.text; // [PC-1464] Replaced 'Remove' text with icon
        var lstHealthPlan = component.get("v.lstHealthPlan");
        if(!$A.util.isEmpty(lstHealthPlan[index].applicantSourceId)) {
            var onlineApplicantHealthPlans = component.get("v.onlineApplicantHealthPlans");
            for(var i=0; i<onlineApplicantHealthPlans.length; i++) {
                if(onlineApplicantHealthPlans[i].applicantSourceId == lstHealthPlan[index].applicantSourceId) {
                    onlineApplicantHealthPlans[i].isApplicantSelected = false;
                    break;
                }
            }
            component.set("v.onlineApplicantHealthPlans", onlineApplicantHealthPlans);
        }
        lstHealthPlan.splice(index,1);
        component.set("v.healthPlanIndex",index);
        component.set("v.lstHealthPlan", lstHealthPlan);
    },
    
    updateHealthPlan :function(component, event, helper){
        //Modified: TEJAS PATEL; Feb-07-2017; Caputure Error Flag; Call method to clear error messages before Re-Validation; Call Validation Methods
        component.set("v.errorCheck",true);
        helper.clearErrorMessage(component, ['recordName', 'tovalidatepayerName']);
        helper.clearErrorMessageLightning(component , ['healthPlanExpirationDate', 'healthPlanEffectiveDate', 'cardholdersBirthDate']);
        var index = component.get("v.healthPlanIndex");
        var newHealthPlan = component.get("v.newHealthPlan");
        var lstHealthPlan = component.get("v.lstHealthPlan");
        
        newHealthPlan.isValid = true;
        helper.getLabelForValue(component, newHealthPlan);

        component.set("v.newHealthPlan", newHealthPlan);
        
        helper.checkValidate(component,false);
        helper.validateRequiredFields(component, ['recordName'], false);
        helper.validateExpirationDate(component,false);
        helper.validateDOB(component, false);
        helper.validateFieldSetForm(component, false);
        
        newHealthPlan = component.get("v.newHealthPlan");
        
        if(component.get("v.errorCheck") === true){
        
            lstHealthPlan[index] = newHealthPlan;
        component.set("v.lstHealthPlan", lstHealthPlan);
        
        helper.hidePopupHelper(component, 'modaldialog', 'slds-fade-in-');
        helper.hidePopupHelper(component, 'backdrop', 'slds-backdrop--');
        component.set("v.isSearchPayer",false);
        component.set("v.isValidated",false);
        component.set("v.addHealthPlan",true);
        component.set("v.addHealthPlanButton",true);
        component.set("v.editHealthPlan",false);
        component.set("v.isEdit",false);
        } else {
            helper.showPopupHelper(component, 'modaldialog', 'slds-fade-in-', helper);
            helper.showPopupHelper(component,'backdrop','slds-backdrop--', helper);
        } 
        
        event.preventDefault();
    },
    
    addHealthPlan : function(component, event, helper) {
        //Modified: TEJAS PATEL; Feb-07-2017; Caputure Error Flag: Call method to clear error messages before Re-Validation; Call Validation Methods
        component.set("v.errorCheck",true);
        helper.clearErrorMessage(component, ['recordName', 'tovalidatepayerName']);
        helper.clearErrorMessageLightning(component , ['healthPlanExpirationDate', 'healthPlanEffectiveDate', 'cardholdersBirthDate']);
        var newHealthPlan = component.get("v.newHealthPlan");
        var lstHealthPlan = component.get("v.lstHealthPlan");

        helper.getLabelForValue(component, newHealthPlan);
        helper.checkValidate(component, false); 
        helper.validateRequiredFields(component, ['recordName'], false);
        helper.validateExpirationDate(component, false);
        helper.validateDOB(component, false);
        helper.validateFieldSetForm(component, false);
        if(component.get("v.errorCheck") === true){
            if(!$A.util.isEmpty(newHealthPlan.applicantSourceId)) {
            	newHealthPlan.isApplicantSelected = true;
                var onlineApplicantHealthPlans = component.get("v.onlineApplicantHealthPlans");
                for(var i=0; i<onlineApplicantHealthPlans.length; i++) {
                    if(onlineApplicantHealthPlans[i].applicantSourceId == newHealthPlan.applicantSourceId) {
                        onlineApplicantHealthPlans[i].isApplicantSelected = true;
                        break;
                    }
                }
                component.set("v.onlineApplicantHealthPlans", onlineApplicantHealthPlans);
            }
            lstHealthPlan.push(newHealthPlan);
            component.set("v.lstHealthPlan", lstHealthPlan);
            
            helper.hidePopupHelper(component, 'modaldialog', 'slds-fade-in-');
            helper.hidePopupHelper(component, 'backdrop', 'slds-backdrop--');
            component.set("v.isEdit",false);
            component.set("v.isSearchPayer",false);
            component.set("v.isValidated",false);
            component.set("v.addHealthPlan",true);
            component.set("v.addHealthPlanButton",true);
            component.set("v.editHealthPlan",false);
        } else {
            helper.showPopupHelper(component, 'modaldialog', 'slds-fade-in-', helper);
            helper.showPopupHelper(component,'backdrop','slds-backdrop--', helper); 
        }  
        
        event.preventDefault();
    },
    numWorkersChanged : function(component, event, helper) {
        if(component.get("v.numWorkers") == 2) {
            helper.updateActionIndicators(component);
        }
    },
    
    cardHolderInfoChange : function(component, event, helper) {
        helper.cardHolderInfoChange (component);        
    }
})