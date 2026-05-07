({
    hideModal : function(component, event, helper) {
        helper.hidePopupHelper(component, 'modaldialog', 'slds-fade-in-');
        helper.hidePopupHelper(component, 'backdrop', 'slds-backdrop--');
        event.preventDefault();
        return false;
    },
    
    hidePopupHelper: function(component, componentId, className){ 
        var modal = component.find(componentId); 
        $A.util.addClass(modal, className+'hide'); 
        $A.util.removeClass(modal, className+'open'); 
    },
    
    showPopupHelper: function(component, componentId, className){ 
        var modal = component.find(componentId); 
        $A.util.removeClass(modal, className+'hide'); 
        $A.util.addClass(modal, className+'open'); 
    },

    goToCase : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        var caseId = component.get("v.reqCaseId");
        //CH_PC_Util.openRecordInNewTab(workspaceAPI,caseId);
        var device = $A.get("$Browser.formFactor");
        if(device != 'DESKTOP'){
            var navService = component.find("navService");
            // Uses the pageReference definition in the init handler
            var pageReference = {
                "type": "standard__recordPage",
                "attributes": {
                   "recordId": caseId,
                   "actionName": "view"
               }
            };
            event.preventDefault();
            navService.navigate(pageReference);
        }else{
            var isCustomApp = component.get("v.isCustomApp");
            if(isCustomApp){
                var url = '/one/one.app#/sObject/' + caseId + '/view';
                window.open(url,'_blank');
            }else{
                CH_PC_Util.openRecordInNewTabAlways(workspaceAPI,caseId, true);
            }
        }
    },
    
    fireToastMessage : function(component, event, helper) {
        var successMessage = component.get("v.toastSuccessMessage");
        var isCustomApp = component.get("v.isCustomApp");
        if(!isCustomApp){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Success!",
                "type": "success",
                "message": successMessage
            });
            toastEvent.fire();
        }else{
            var appEvents = 'e.' + component.get("v.namespace") + ':PC_ToastEvent';
            var appEvent = $A.get(appEvents);
            appEvent.setParams({
                "message" : successMessage,
                "toastType": 'success'
            });
            appEvent.fire();
            return false;
        }
    },
    
    fireCloseParent : function(component, event, helper) {
        var appEventns = 'e.' + component.get("v.namespace") + ':PC_CloseCmp';
        var appEvent = $A.get(appEventns);
        appEvent.setParams({
            "message" : 'Parent Window Closed'
        });
        appEvent.fire();
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

    getCustomcomp : function(component, event, helper) {
        var isDocId = component.get("v.docId");
        if(isDocId) {
            component.set("v.showLinkButton", true);
        }
        var action = component.get("c.CheckMetadata");
        action.setParams({
            "reqCaseId"		: component.get("v.reqCaseId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                if(returnValue != null ){
                    if(!$A.util.isEmpty(returnValue.componentName)){
                        component.set("v.compDetails",returnValue);
                        component.set("v.NameComponent",returnValue.componentName);
                        var custLabel = $A.get("$Label.c."+returnValue.buttonName);
                        component.set("v.buttonlabel",custLabel);
                    }
                    if(!$A.util.isEmpty(returnValue.caseDetails)){
                        component.set("v.caseDetails",returnValue.caseDetails);
                    }
                    if(!$A.util.isEmpty(returnValue.fsDetails)){
                        helper.setFieldSetObject(component, event, helper, returnValue.fsDetails);
                    }
                    helper.showPopupHelper(component, 'modaldialog', 'slds-fade-in-');
                    helper.showPopupHelper(component, 'backdrop', 'slds-backdrop--');
                } else if (returnValue == null){
                    helper.showPopupHelper(component, 'modaldialog', 'slds-fade-in-');
                    helper.showPopupHelper(component, 'backdrop', 'slds-backdrop--');
                }
            } else if (state === "ERROR") {
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
            } else {
                console.log("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);   
     },

    setFieldSetObject : function(component, event, helper, fsDetails) {
        component.set('v.fieldSetName', fsDetails.fieldSetName);
        var fields = fsDetails.listFieldSetMembers;

        var renamedFields = {};
        var obj = {};

        if(fields != null && fields.length > 0){
            for (var key in fields) {
                if (fields.hasOwnProperty(key)) {
                    obj[fields[key].fieldPath.replace('.','___')] = '';
                }
            }
        }
        else {
            console.log('No fields found from fieldset');
        }
        console.log('FieldSetForm HealthPlan Helper -  ] getFields callback end');
        helper.createFieldSetCmp(component, event, helper, fields);
    },

    createFieldSetCmp : function(cmp, event, helper, fields) {
         $A.createComponent(
             cmp.get("v.namespace") + ":PC_FieldSetForm",
             {
                 "fsName": cmp.get("v.fieldSetName"),
                 "typeName": cmp.get("v.typeName"),
                 "record": cmp.get("v.fsFieldValues"),
                 "isValid" : cmp.getReference("v.isFieldSetFormValid"),
                 "disableFlag" : true
             },
             function(newCmp, status, errorMessage){
                 //Add the new button to the body array
                 if (status === "SUCCESS") {
                     var body = cmp.get("v.fieldSetFormBody");
                     body.push(newCmp);
                     cmp.set("v.fieldSetFormBody", body);
                     cmp.set("v.fieldSetFields", fields);
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

    validateFieldSetForm :function(component) {
         console.log(component.get("v.fieldSetFormBody"));
         component.set("v.isFieldSetFormValid",true);
         if (component.get("v.fieldSetFormBody") != null && component.get("v.fieldSetFormBody").length > 0) {
             console.log('In here');
             var fieldSetCmp = component.get("v.fieldSetFormBody")[0];
             fieldSetCmp.validate(); // this sets v.isFieldSetFormValid.
         }
         return component.get("v.isFieldSetFormValid");
    },

    setDefaultValueForFieldSetFields : function(cmp, event, helper, fsFields) {
         debugger;
         var persistentAccount = cmp.get("v.searchPatient");
         var currentAccFsFields = persistentAccount.fsFields;

         if($A.util.isEmpty(fsFields) || $A.util.isUndefined(fsFields)) {
            // do nothing
         }
         else {
             var HpField = '';
             for(var i=0; i<fsFields.length; i++) {
                 HpField = fsFields[i].fieldPath;

                 if($A.util.isEmpty(currentAccFsFields[HpField])) {
                    currentAccFsFields[HpField] = '';
                 }
             }
             persistentAccount.fsFields = JSON.parse(JSON.stringify(currentAccFsFields));

             cmp.set("v.searchPatient",persistentAccount);
         }

    },
})