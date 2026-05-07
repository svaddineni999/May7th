({	
    linkDocumentToCase : function (component, event, helper) { 
        console.log('linkDocumentToCase');
        var enrollcaseId = component.get("v.caseId");
        var docId = component.get("v.docId");
        var action = component.get("c.linkDocToCase");
        action.setParams({
            "enrollmentCaseId": enrollcaseId,
            "documentId": docId 
        });
        action.setCallback(this, function(a) {
            var state = a.getState();
            //if server side call successful, create entries in document log and document modification log
            if (state === "SUCCESS") {
                console.log("Document linking sucessful");
            } else if (state ==="ERROR") { //if server side call fails, log error in console
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
        });
        $A.enqueueAction(action);
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

    setFieldSetObject : function(cmp, event, helper) {

             if (cmp.get("v.fieldSetName") != null) {
                 var action = cmp.get("c.getFieldSetFields");
                 action.setParams({
                     typeName: cmp.get('v.typeName'),
                     engagementProgramCode : cmp.get('v.newApplicant.engagementProgramCode')
                 });
                 action.setCallback(this,
                        function(response) {
                            debugger;
                            console.log('FieldSetForm HealthPlan Helper -  getFields callback start');
                            var state=response.getState();
                            console.log('state-->' +state);
                            if(state=='SUCCESS'){
                                var returnValue=response.getReturnValue();

                                cmp.set('v.fieldSetName', returnValue.fieldSetName);
                                var fields = returnValue.listFieldSetMembers;

                                var renamedFields = {};
                                var obj = {};

                                if(fields != null && fields.length > 0){

                                    //helper.setDefaultValueForFieldSetFields(cmp, event, helper, fields);

                                    for (var key in fields) {
                                        if (fields.hasOwnProperty(key)) {
                                            obj[fields[key].fieldPath.replace('.','___')] = '';
                                            console.log(key + " -> " + fields[key].fieldPath.replace('.','___'));
                                        }
                                    }
                                }
                                else {
                                   console.log('No fields found from fieldset');

                                }
                                console.log('FieldSetForm HealthPlan Helper -  ] getFields callback end');
                                helper.createFieldSetCmp(cmp, event, helper, fields);
                            }
                            else{
                                  var error = cmp.get("v.lightingErrorMessage");
                                  var errors = response.getError();
                                  if(!$A.util.isEmpty(errors) && errors.length > 0 && !$A.util.isEmpty(errors[0]['message'])) {
                                  error = errors[0]['message'];
                                  console.log('Error Message-->' +error);
                                  }
                                  cmp.set("v.errors", [error]);
                                console.log('State is failed');
                            }
                        }
                       );
                 $A.enqueueAction(action);
             }
        },

    createFieldSetCmp : function(cmp, event, helper, fields) {
         $A.createComponent(
             cmp.get("v.namespace") + ":PC_FieldSetForm",
             {
                 "fsName": cmp.get("v.fieldSetName"),
                 "typeName": cmp.get("v.typeName"),
                 "record": cmp.getReference("v.fsFieldValues"),
                 "isValid" : cmp.getReference("v.isFieldSetFormValid"),
                 "autofocusFirstField" : true,
                 "noOfItemsInARow" : 3
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
})