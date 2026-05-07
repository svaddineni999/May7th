({
    doInit : function(component, event, helper) {
        debugger;
        helper.setNamespace(component);
        helper.getFieldLabels(component, event, helper);
        helper.getPAInfo(component, event, helper);
       	helper.getPARecordTypeId(component, 'Case');
        helper.isPACaseActive(component, event, helper);
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
    
    newPriorAuthorization :  function(component, event, helper) {
        debugger;
	    var params = {
            "entityApiName": "Case",
            "recordTypeId" : component.get("v.paRecTypeId"),
            "defaultFieldValues" : {
          }            
        }

        var prgId = component.get("v.namespacePrefix") + "PC_Program__c" ;
        params["defaultFieldValues"][prgId] = component.get("v.recordId");
        var createRecordEvent = $A.get("e.force:createRecord");
        createRecordEvent.setParams(params);
        createRecordEvent.fire();
    },

    newElectronicPA : function(component, event, helper) {
        debugger;
        var recordId = component.get("v.recordId");
        var overridePrescriptionWithCoverage = component.get("v.overridePrescriptionWithCoverage");
        var modalBody;
        var ePACmpName = component.get("v.namespace") + ":" + "PC_ePriorAuthInitiationForm";
        $A.createComponent(ePACmpName, {"recordId":recordId,"overridePrescriptionWithCoverage":overridePrescriptionWithCoverage},
               function(content, status) {
                   if (status === "SUCCESS") {
                       helper.applyCSS(component);
                       modalBody = content;
                       component.find('ePAOverlay').showCustomModal({
                           header: component.get("v.ePAModalTitle"),
                           body: modalBody,
                           showCloseButton: true,
                           cssClass : "ePAOverlay pcOverlayModal",
                           closeCallback: function() {
                               console.log('You closed the alert!');
                               helper.revertCssChange(component);
                               component.set("v.ePAModalCloseTracker", !component.get("v.ePAModalCloseTracker"));
                           }
                       })
                   }
               });
    },
    
    gotoRelatedList : function (component, event, helper) {
        var relatedListEvent = $A.get("e.force:navigateToRelatedList");
        var relatedListId = component.get("v.namespacePrefix") + 'PC_Prior_Authorization__r';
        relatedListEvent.setParams({
            "relatedListId": relatedListId,
            "parentRecordId": component.get("v.recordId")
        });
        relatedListEvent.fire();
    },

    openVendorPortal : function (component, event, helper) {
        debugger;
        var id = event.getSource().get("v.value");
        var items = component.get("v.paInfo");
        var selectedItem = items.find(record => record['paID'] == id);
        window.open(selectedItem.paExtURL, '_blank');
    }
})