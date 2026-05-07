/**
 * Created by peharitha on 10/26/2018.
 */
({

    fetchInitData :function(component ,event ,helper){
        var action =  component.get("c.getData");
        action.setParams({
            aeId: component.get("v.aeId")
        });
        action.setCallback(this, function(response){
            var state= response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                component.set("v.type",returnValue.type);
                component.set("v.fieldLabels" , returnValue.fieldLabels);
                component.set("v.currentType", returnValue.typeSelectedVal);
            }
            else{
                var error;
                var errors = response.getError();
                if(errors != null && errors.length > 0 && !$A.util.isEmpty(errors[0]['message'])) {
                error = errors[0]['message'];
                }
                component.set("v.errors", [error]);
            }
        })
        $A.enqueueAction(action);
    },
    validate: function(component, event, helper) {
        component.set('v.errors',[]);
        var isPatientInfoValid = true;
        var isSuspectProductInfoValid = true;
        var isAdditionalInfoValid = true;
        var patientInfoComp = component.find("patientInfoComp");
        if(!$A.util.isEmpty(patientInfoComp)){
            isPatientInfoValid = patientInfoComp.validate();
            if(!isPatientInfoValid) {
                helper.addErrorMessage(component, helper, component.get("v.patientInformation") + ' : ' + component.get("v.reviewErrors"));
            }
        }
        var suspectProductComp = component.find("suspectProductComp");
        if(!$A.util.isEmpty(suspectProductComp)){
            isSuspectProductInfoValid = suspectProductComp.validate();
            if(!isSuspectProductInfoValid) {
                helper.addErrorMessage(component, helper, component.get("v.suspectProducts") + ' : ' + component.get("v.reviewErrors"));
            }
        }
        var hideAdditionalInfoTab = component.get("v.adverseEventMenuCmpAttributes.hideAdditionalInfoTab");
        if((hideAdditionalInfoTab == false || hideAdditionalInfoTab =='false')){
            var additionalInfoTab = component.find("additionalInfoTab");
            if(!$A.util.isEmpty(additionalInfoTab)){
                isAdditionalInfoValid = additionalInfoTab.validate();
            }
            if(!isAdditionalInfoValid) {
                helper.addErrorMessage(component, helper, component.get("v.additionalInformation") + ' : ' + component.get("v.reviewErrors"));
            }
        }
        if(!isPatientInfoValid || !isSuspectProductInfoValid || !isAdditionalInfoValid){
            return false;
        }else{
            return true;
        }
    },

	addErrorMessage: function (component, helper, errorMessage){
        var errorList = component.get("v.errors");
        errorList.push(errorMessage);
        component.set("v.errors", errorList);
    },
	switchTabs: function (component, event, helper){
        var currentTab = component.get("v.selTabId");
        component.set("v.previousTabId" , currentTab);
    },
    
    createAERec: function (component, event, helper){
        component.set('v.disableSaveButton',true);
        if(helper.validate(component, event, helper)) {
            console.log('i m in create');
            var action =  component.get("c.createAdverseEvent");
            var aeWrapperVal = component.get("v.aeWrapper");
            var aeInfoMap = {'type' : component.get("v.currentType")};
            aeWrapperVal['aeInfo']=aeInfoMap;
            action.setParams({
                aeId: component.get("v.aeId"),
                caseId: component.get("v.caseId"),
                aeWrapper: aeWrapperVal,
                visitedTab: component.get("v.visitedTab"),
                adverseEventMenuCmpAttributes : component.get("v.adverseEventMenuCmpAttributes")

            });
            action.setCallback(this, function(response){
                var state= response.getState();
                if (state == "SUCCESS"){
                    var returnValue =response.getReturnValue();
                    helper.showToast(component, event, helper,returnValue);
                    component.find("overlayLib").notifyClose();
                    $A.get('e.force:refreshView').fire();
                }
                else{
                    //helper.handleErrors(component, response.getError());
                    var error;
                    var errors = response.getError();
                    if(errors != null && errors.length > 0 && !$A.util.isEmpty(errors[0]['message'])) {
                        error = errors[0]['message'];
                        
                    }
                    component.set("v.errors", [error]);
                }
                component.set('v.disableSaveButton',false);
    
            });
    
            $A.enqueueAction(action);
        }
        else {
            component.set('v.disableSaveButton',false);
        }
    },

    showToast : function(component, event, helper,response) {
        var toastEvent = $A.get("e.force:showToast");
                var msg = response[0] + ' ' +component.get("v.saveSuccessMessage");
                var title = component.get("v.toastSuccessTitle");
                toastEvent.setParams({
                    "title": title,
                    "message": msg,
                     "messageTemplate": '{0} - ' + component.get("v.saveSuccessMessage"),
                     "messageTemplateData": [ {
                        url: window.location.protocol+'//'+window.location.host + '/lightning/r/'+response[2]+'/'+response[1]+'/view' ,
                        label: response[0], },
                      ],
                    "type": "success",
                    "duration":5000
                });
                toastEvent.fire();
    },
    handleErrors : function(component, errors) {
        // Configure error toast
        console.error('Errors:');
        console.error(errors);
        let toastParams = {
            title: "Error",
            message: component.get("v.errorDescription"), // Default error message
            type: "error"
        };
        // Pass the error message if any
        if (errors && Array.isArray(errors) && errors.length > 0) {
            toastParams.message = errors[0].message;
        }
        // Fire error toast
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams(toastParams);
        toastEvent.fire();
        $A.get('e.force:refreshView').fire();
    },
    clearErrors : function(component) {
        component.set("v.errors", []);
    }
})