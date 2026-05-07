/**
 * Created by havalakki on 2/5/2018.
 */
({
    doneRendering: function(component, event, helper) {
            	helper.doneRendering(component, event);
            },
        doInit : function(component, event, helper) {
                component.set("v.errors", []);
                helper.setNamespace(component);
                //helper.getSubComponentList(component, event, helper);
                helper.getInit(component, event, helper);
                //helper.getLogs(component);
            },
        hideModalBox : function(component, event, helper) {
                helper.hideModal(component, event, helper);
            },
        onSelectChange : function(component, event, helper) {
            	component.set("v.recordType",component.find("selectAccountRt").get("v.value"));
            },
        searchPatient : function(component, event, helper) {
            component.set("v.isInValidInput", false);
            helper.getPatientInfo(component,event,helper);
        },

        showSpinner : function (component, event, helper) {
            var saveButtonId = component.find('saveButtonId');
            if(!$A.util.isUndefinedOrNull(saveButtonId)){
                saveButtonId.set("v.disabled",true);
            }
            var spinner = component.find('spinner');
            var evt = spinner.get("e.toggle");
            evt.setParams({ isVisible : true });
            evt.fire();
        },

        hideSpinner : function (component, event, helper) {
           var saveButtonId = component.find('saveButtonId');
           if(!$A.util.isUndefinedOrNull(saveButtonId)){
               saveButtonId.set("v.disabled",false);
           }
           var spinner = component.find('spinner');
           var evt = spinner.get("e.toggle");
           evt.setParams({ isVisible : false });
           evt.fire();
        },

        setPatientInformation : function(component, event, helper) {
                var elem = event.getSource().get("v.text");
                component.set("v.patiendId", elem);
            },
        goToSelectedLink : function(component, event, helper) {
                var objectId = event.currentTarget.id;
               window.open('/one/one.app#/sObject/' + objectId + '/view', '_blank', "toolbar=yes,scrollbars=yes,resizable=yes,left=1050,top=100,width=800,height=800");
            },

        linkCheck : function(component, event, helper) {
                var accountId = component.get("v.patiendId");
                if(accountId) {
                    var action = component.get("c.getRecordTypeForAccount");
                    action.setParams({
                        accountId	: accountId
                    });
                    action.setCallback(this, function(a) {
                        var state = a.getState();
                        if (state === "SUCCESS") {
                            var returnValue = a.getReturnValue();
                            if(undefined!=returnValue && null!=returnValue){
                                component.set("v.accountRecordType",returnValue);
                                helper.refreshCmp(component, event, helper);
        						var doclogcmp = component.find("documentLogLinkId");
                                $A.util.removeClass(doclogcmp, 'hideComponent');
                                $A.util.addClass(doclogcmp, 'showComponent');

                                var docmgmcmp = component.find("documentLinkId");
                                $A.util.removeClass(docmgmcmp, 'showComponent');
                                $A.util.addClass(docmgmcmp, 'hideComponent');
                                component.set("v.showBackToSearch",true);
                                }
                            
                        } else if (a.getState() ==="ERROR"){
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
                }
                else{
                     var error = component.get("v.selectAccountErrorText");
                     component.set("v.errors", [error]);
                }
            },

         handleBackToSearch : function(component, event, helper) {
                var doclogcmp = component.find("documentLogLinkId");
                $A.util.removeClass(doclogcmp, 'showComponent');
                $A.util.addClass(doclogcmp, 'hideComponent');

                var docmgmcmp = component.find("documentLinkId");
                $A.util.removeClass(docmgmcmp, 'hideComponent');
                $A.util.addClass(docmgmcmp, 'showComponent');
               	component.set("v.displayPatientsTable", false);
                component.set("v.searchString", "");
                component.set("v.showBackToSearch",false);
                helper.setNamespace(component);
                helper.getInit(component, event, helper);
            },

        saveDocumentLogs : function(component, event, helper){
            var documentLinkDetailsComponent=component.find('documentLinkDetailsId');
            documentLinkDetailsComponent.saveUpdateDocumentLogs();
        },

        handleChildCmpEvent : function(component, event, helper){

            var resultString=event.getParam('resultString');
            var errors = event.getParam('errors');

            if(resultString=='SUCCESS'){
                helper.hideModal(component, event, helper);
                helper.showToastMessage('SUCCESS!','Success',component.get('v.docLinkingSuccessText'));
                $A.get('e.force:refreshView').fire();
            }
            else if(resultString=='ERROR'){
                CH_PC_Util.showAllErrors(component.get("v.errorDocStatus"),errors);
            }
            else if(resultString=='WARNING'){
               helper.showToastMessage('WARNING!','Warning',component.get('v.docLinkingWarningText'));
             }
        },

        checkEnter: function(component,event,helper){
            component.set("v.isInValidInput", false);
             if(event.keyCode==13){
                helper.getPatientInfo(component,event,helper);
             }
        }
})