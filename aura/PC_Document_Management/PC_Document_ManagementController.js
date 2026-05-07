({
	doneRendering: function(component, event, helper) {
    	helper.doneRendering(component, event);
    },
    
    showSpinner : function (component, event, helper) {
		var spinner = component.find('spinner');
        var evt = spinner.get("e.toggle");
        evt.setParams({ isVisible : true });
        evt.fire();
    },
    
    hideSpinner : function (component, event, helper) {
       var spinner = component.find('spinner');
       var evt = spinner.get("e.toggle");
       evt.setParams({ isVisible : false });
       evt.fire();   
    },
    
    doInit : function(component, event, helper) {
        helper.setNamespace(component);
        helper.getSubComponentList(component, event, helper);
        helper.getInit(component, event, helper);
        helper.getLogs(component);        
    },
    
    handleBackToSearch : function(component, event, helper) {
        var doclogcmp = component.find("documentLogLinkId");
        $A.util.removeClass(doclogcmp, 'showComponent');
        $A.util.addClass(doclogcmp, 'hideComponent');
        
        var docmgmcmp = component.find("documentManagementId");
        $A.util.removeClass(docmgmcmp, 'hideComponent');
        $A.util.addClass(docmgmcmp, 'showComponent');
       	component.set("v.displayPatientsTable", false);
        component.set("v.searchString", "");
        helper.setNamespace(component);
        helper.getInit(component, event, helper);
        helper.getLogs(component);
        
    },
    
    selectCategory : function(component, event, helper) {
		var selectedCateg = event.srcElement.getAttribute('data-category');
        helper.saveCategory(component, event, helper, selectedCateg);
        
    },
    
    assignToMe : function(component, event, helper) {
        helper.assignToMe(component, event, helper);
    },
    
    showReassignDocument : function(component, event, helper) {
        component.set("v.body", '');
        component.set("v.showReassignSection", true);
    },
    
    //Reassign the document to the selected user
    reassignDoc: function(component, event, helper) {
        helper.reassignDoc(component, event);
    },
    
    archiveFax : function(component, event, helper) {
        if (confirm(component.get("v.ConfirmText"))){
            helper.doArchive(component);
        }
    },
    
    markAsSpam : function(component, event, helper) {
        if (confirm(component.get("v.ConfirmText"))){
            helper.markSpam(component);
        }
    },
    
    markAsUnspam : function(component, event, helper) {
        if (confirm(component.get("v.ConfirmText"))){
            helper.markUnspam(component, event);
        }
    }, 
    
    markAsIllegible : function(component, event, helper) {
        if (confirm(component.get("v.ConfirmText"))){
            helper.markIllegible(component);
        }
    },
    
    searchPatient : function(component, event, helper) {
        var searchTerm = component.get("v.searchString");
        
        if(searchTerm != null && searchTerm.trim().length >= 2 ) {
        helper.searchPatient(component);
        component.set("v.displayPatientsTable", true);
        }
        else {
            var toastEvent=$A.get("e.force:showToast");
            toastEvent.setParams({
                "title":    'Warning',
                "message":  component.get("v.validityMessage"),
                "type":     'warning'
            });
            toastEvent.fire();
        }
    },
    
    setPatientInformation : function(component, event, helper) {
        var elem = event.getSource().get("v.text");
        component.set("v.patiendId", elem);
    },
    
    returnToList  : function(component, event, helper) {
        helper.returnToList(component);
    },   

    goToSelectedLink : function(component, event, helper) {
        var objectId = event.currentTarget.id;
       window.open('/one/one.app#/sObject/' + objectId + '/view', '_blank', "toolbar=yes,scrollbars=yes,resizable=yes,left=1050,top=100,width=800,height=800");
    },
    
    closeReassignSection : function(component, event, helper) {
    	component.set("v.showReassignSection", false);
    },
    
    popOutDocument : function (component, event, helper) {
        var docId = component.get("v.recordId");
        var isEmail = component.get("v.loadEmailContainer");
       	var componentName;
        if (isEmail === true) {
        	componentName = "PC_Document_InboundEmail";
        } else {
        	componentName = "PC_Document_InboundFax";
        }
        var vfpage = component.get("v.namespacePrefix")+'PC_PopOutDocument';
        var url = '/apex/'+ vfpage +'?documentId=' + docId + '&componentName=' + componentName + '&isPopout=' + true;
        window.open(url, "_blank", "toolbar=yes,scrollbars=yes,resizable=yes,left=1050,top=100,width=800,height=800");
	},
    
    linkCheck : function(component, event, helper) {
        var docId = component.get("v.recordId");
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
                    if (returnValue === component.get("v.accountPatientType")) {
                        component.set("v.accountRecordType",returnValue);
                        helper.refreshCmp(component, event, helper);
						var doclogcmp = component.find("documentLogLinkId");
                        $A.util.removeClass(doclogcmp, 'hideComponent');
                        $A.util.addClass(doclogcmp, 'showComponent');
                        
                        var docmgmcmp = component.find("documentManagementId");
                        $A.util.removeClass(docmgmcmp, 'showComponent');
                        $A.util.addClass(docmgmcmp, 'hideComponent');
                    } else {
                        helper.createDocumentLog(component, event, helper, accountId, docId);
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
    },
    
    hideAckModal : function(component, event, helper) {
        helper.hideAckModal(component, event, helper);
    },
    
    showAckModal : function(component, event, helper) {
        helper.showAckModal(component, event, helper);
    },
    
    onSelectChange : function(component, event, helper) {
    	component.set("v.recordType",component.find("selectAccountRt").get("v.value"));
    },
    
    markComplete : function (component, event, helper) {
        var checkStatus = component.get("v.details");
        if (checkStatus[0].docStatusLabel == component.get("v.documentCompleted")) {
            component.set("v.modalMessage", component.get("v.documentCompleteMessage"))
            helper.showAckModal(component, event, helper);
        } else {
            /*var booleanCheck = true;*/
            if (confirm(component.get("v.ConfirmText"))) {
                    helper.markComplete(component);
            }
            /*if (checkStatus[0].docStatus == $A.get("$Label.c.PC_Document_Split_Failure") ||
                checkStatus[0].docStatus == $A.get("$Label.c.PC_Document_Ready_For_Split") ||
                checkStatus[0].docStatus == $A.get("$Label.c.PC_Document_Awaiting_Attachment") ||
                checkStatus[0].docStatus == $A.get("$Label.c.PC_Document_Split_In_Progress") ) {

                booleanCheck = false;
            }
            if (booleanCheck) {
                if (confirm(component.get("v.ConfirmText"))) {
                    helper.markComplete(component);
                }
            } else {
                component.set("v.modalMessage", $A.get("$Label.c.PC_Document_Complete_Error_Text"))
                helper.showAckModal(component, event, helper);
            }*/
        }
    }
})