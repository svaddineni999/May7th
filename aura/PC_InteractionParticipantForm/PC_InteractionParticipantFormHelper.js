({
    setNamespace : function(component, event, helper) {
        var ns = CH_PC_Util.getNamespace(component);
        var nsPrefix = CH_PC_Util.getNamespacePrefix(component);
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", nsPrefix);
    },
    showSpinner: function(component, event, helper) {
        component.set('v.showSpinner', true);
    },
    hideSpinner : function(component,event,helper){
        component.set('v.showSpinner', false);
    },
    setPageReferenceValues: function(component, event, helper) {
        var namespace = component.get("v.namespace");
        var pageReference = component.get("v.pageReference");
        var caseIdQualifiedApiName = CH_PC_Util.getQualifiedQueryParam(component,'caseId',namespace);
        var selectedLocationQualifiedApiName = CH_PC_Util.getQualifiedQueryParam(component,'selectedLocation',namespace);

        var caseId, selectedLocation;
        if(pageReference && pageReference.state){
            if(pageReference.state[caseIdQualifiedApiName] != 'NULL' && pageReference.state[caseIdQualifiedApiName] != 'undefined'){
                caseId = pageReference.state[caseIdQualifiedApiName];
            }
            if(pageReference.state[selectedLocationQualifiedApiName] != 'NULL' && pageReference.state[selectedLocationQualifiedApiName] != 'undefined'){
                selectedLocation = pageReference.state[selectedLocationQualifiedApiName];
            }
        }else{
            var query = location.search.substr(1);
            var result = {};
            query.split("&").forEach(function(part) {
                var item = part.split("=");
                if(!$A.util.isUndefinedOrNull(item[0]) && !$A.util.isUndefinedOrNull(item[1])){
                    result[item[0]] = decodeURIComponent(item[1]);
                }
            });
            caseId = ($A.util.isUndefinedOrNull(caseId))?result[caseIdQualifiedApiName]:caseId;
            selectedLocation = ($A.util.isUndefinedOrNull(selectedLocation))?result[selectedLocationQualifiedApiName]:selectedLocation;
        }
        component.set("v.caseId", (caseId != undefined)? caseId :component.get("v.caseId"));
        component.set("v.selectedLocation", (selectedLocation != undefined)? selectedLocation :component.get("v.selectedLocation"));
    },

    setDefaultValues : function(component, event, helper) {
        var interaction_custom_obj = component.get('v.namespacePrefix') + 'PC_Interaction__c';
        component.set("v.interactionObjectAPIName",interaction_custom_obj);

        var patientProgram = component.get('v.namespacePrefix') + 'PC_Patient_Program__c';
        var participant = component.get('v.namespacePrefix') + 'PC_Participant__c';
        var defaultFieldValues = component.get("v.defaultFieldValues");
        defaultFieldValues[patientProgram] = component.get('v.caseId');
        defaultFieldValues[participant] = component.get('v.selectedLocation');
        component.set("v.defaultFieldValues",defaultFieldValues);
    },

    handleSubmit: function(component, event, helper) {
        var interactionCreateRecordFormCmp = component.find('interactionCreateRecordForm');
        var fieldsValues = interactionCreateRecordFormCmp.submit();
    },

    handleCancel : function(component,event,helper){
            var workspaceAPI = component.find("bookAppointmentWorkspace");
            workspaceAPI.isConsoleNavigation().then(function(isConsole){
                if(isConsole){
                    workspaceAPI.getFocusedTabInfo().then(function(response) {
                        var focusedTabId = response.tabId;
                        workspaceAPI.closeTab({tabId: focusedTabId});
                    }).catch(function(error) {
                        var errors = [];
                        errors.push(error);
                        helper.handleErrors(component,errors);
                    });
                }else{
                    window.close();
                }
            })
            .catch(function(error) {
                var allErrors = [];
                allErrors.push(error);
                helper.handleErrors(component,allErrors);
            });
        },

    handleSuccess: function(component, event, helper) {
        var record = event.getParams();
        var successMessage = 'Record Created Successfully';
        component.set('v.interactionRecordId', record.id);

        var participantSelectionCmp = component.find("participantSelectionCmp");
        var saveResult = participantSelectionCmp.save();

        helper.navigateToRecordPage(component, event, helper);
        helper.showToast(component, successMessage, 'success');
        helper.closeTab(component, event, helper);
    },

    navigateToRecordPage: function(component, event, helper) {
        var workspaceAPI = component.find("bookAppointmentWorkspace");
        var interactionId = component.get("v.interactionRecordId");
        var interactionObjectAPIName = component.get("v.interactionObjectAPIName");

        workspaceAPI.isConsoleNavigation().then(function(isConsole) {
            if (isConsole) {
                workspaceAPI.getEnclosingTabId().then(function(enclosingTabId) {
                    if (!enclosingTabId) {
                        workspaceAPI.openTab({
                            url: '/lightning/r/'+interactionObjectAPIName+'/'+interactionId+'/view'
                        }).then(function(response) {
                            workspaceAPI.focusTab({tabId : response});
                        });
                    }else {
                        workspaceAPI.openSubtab({
                            parentTabId:enclosingTabId,
                            url: '/lightning/r/'+interactionObjectAPIName+'/'+interactionId+'/view'
                        }).then(function(response) {
                            workspaceAPI.focusTab({tabId : response});
                        });
                    }
                });
            }else {
                var url = '/one/one.app#/sObject/' + interactionId + '/view';
                window.location.href = url;
            }
        })
        .catch(function(error) {
            console.log(error);
        });
    },

    showToast: function(component, message, type){
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            mode: 'dismissable',
            message: message,
            type: $A.util.isEmpty(type) ? "info" : type,
        });
        toastEvent.fire();
    },

    closeTab: function(component, event, helper) {
        var workspaceAPI = component.find("bookAppointmentWorkspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.closeTab({tabId: focusedTabId});
        })
        .catch(function(error) {
            console.log(error);
        });
    }
})