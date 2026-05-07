({
    doInit : function(component, event, helper) {
        helper.clearErrorMessages(component, event, helper);
        helper.setNamespace(component);
        helper.setRecordId(component, event, helper);
        helper.getFieldLabels(component, event, helper);
        helper.getRefInfo(component, event, helper);
       	helper.isReferralActive(component, event, helper);
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
    
    launchMap : function(component, event, helper){
        component.set("v.isModalMapActive", true);

        var componentName = component.get("v.namespace") + ':' + 'PC_PatientLocationMapViewer';
        $A.createComponent(
            componentName,
            {
                "recordId" : component.get("v.recordId"),
                "genericMap" : false
                
            },
            function(newComponent) {
                component.set("v.body", newComponent);
            }
        );
    },
    launchNewReferral : function(component, event, helper){
        debugger;
        component.set("v.isModalMapActive", true);

        var componentName = component.get("v.namespace") + ':' + 'PC_NewReferral';
        $A.createComponent(
            componentName,
            {
                "recordId" : component.get("v.recordId")

            },
            function(newComponent, status) {
                if (status === "SUCCESS") {
                    component.set("v.newReferralBody", newComponent);
                }
                else {
                    var toastEvent=$A.get("e.force:showToast");
                                    toastEvent.setParams({
                                        "title":    'Warning',
                                        "message":  'Something went wrong, Please contact System Administrator',
                                        "type":     'warning'
                                    });
                                    toastEvent.fire();
                }

            }
        );
    },
    closeMap : function(component, event, helper){
        component.set("v.isModalMapActive", false);

    }

    
    //Navigates to Referral related list view
    /*gotoRelatedList : function (component, event, helper) {
        var relatedListEvent = $A.get("e.force:navigateToRelatedList");
        var relatedListId = component.get("v.namespacePrefix") + 'PC_Pharmacy_Referrals__r';
        relatedListEvent.setParams({
            "relatedListId": relatedListId,
            "parentRecordId": component.get("v.recordId")
        });
        relatedListEvent.fire();
    }*/
})