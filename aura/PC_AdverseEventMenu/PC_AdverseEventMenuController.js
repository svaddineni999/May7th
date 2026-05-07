/**
 * Created by peharitha on 10/26/2018.
 */
({
    doInit : function(component, event, helper) {
        helper.fetchInitData(component, event, helper);

    },
    handleCancel : function(component, event, helper) {
        //closes the modal or popover from the component
        component.find("overlayLib").notifyClose();
    },
    switchTabs: function (component, event, helper){
        helper.switchTabs(component, event, helper);
    },
    handleSave : function(component, event, helper) {
        helper.clearErrors(component);
        helper.createAERec(component, event, helper);
        
        $A.get('e.force:refreshView').fire();
    },
    validate : function(component, event, helper) {
        helper.validate(component, event, helper);
    },
    next : function(component, event, helper) {
        var hideAdditionalInfoTab = component.get("v.adverseEventMenuCmpAttributes.hideAdditionalInfoTab");
        // get the current selected tab value
        helper.clearErrors(component);
        var currentTab = component.get("v.selTabId");
        if(currentTab == 'Patient_Information'){
            var patientInfoComp = component.find("patientInfoComp");
            var result = patientInfoComp.validate();
            if(result == true){
                component.set("v.selTabId" , 'Adverse_Event');
                component.set("v.previousTabId" , 'Patient_Information');
            }else{
                var patientInformation = component.get("v.patientInformation");
                var error = patientInformation + ' ' + component.get("v.reviewErrors");
                component.set("v.errors", [error]);
            }
        }else if(currentTab == 'Adverse_Event'){
            component.set("v.selTabId" , 'Suspect_Products');
            component.set("v.previousTabId" , 'Adverse_Event');
        }else if(currentTab == 'Suspect_Products'){
            component.set("v.selTabId" , 'Initial_Repoter');
            component.set("v.previousTabId" , 'Suspect_Products');
        }else if(currentTab == 'Initial_Repoter'){
            component.set("v.selTabId" , 'Manufacturer');
            component.set("v.previousTabId" , 'Initial_Repoter');
        }else if(currentTab == 'Manufacturer'){
            if(hideAdditionalInfoTab == false || hideAdditionalInfoTab =='false'){
                component.set("v.selTabId" , 'Additional_Info');
                component.set("v.previousTabId" , 'Manufacturer');
            }
        }
    },

    back : function(component, event, helper) {
        // get the current selected tab value
        helper.clearErrors(component);
        var currentTab = component.get("v.selTabId");

        if(currentTab == 'Adverse_Event'){
            component.set("v.selTabId" , 'Patient_Information');
            component.set("v.previousTabId" , 'Adverse_Event');
        } else if(currentTab == 'Suspect_Products'){
            component.set("v.selTabId" , 'Adverse_Event');
            component.set("v.previousTabId" , 'Suspect_Products');
        }else if(currentTab == 'Initial_Repoter'){
            component.set("v.selTabId" , 'Suspect_Products');
            component.set("v.previousTabId" , 'Initial_Repoter');
        } else if(currentTab == 'Manufacturer'){
            component.set("v.selTabId" , 'Initial_Repoter');
            component.set("v.previousTabId" , 'Manufacturer');
        } else if(currentTab == 'Additional_Info'){
            var additionalInfoTab = component.find("additionalInfoTab");
            var result = additionalInfoTab.validate();
            if(result == true){
                component.set("v.selTabId" , 'Manufacturer');
                component.set("v.previousTabId" , 'Additional_Info');
            }else{
                var additionalInformation = component.get("v.additionalInformation");
                var error = additionalInformation +' '+ component.get("v.reviewErrors");
                component.set("v.errors", [error]);
            }
        }
    },
    handleActive : function(component, event, helper) {
        //sets active status Flags of Tabs
        var currentTab = component.get("v.selTabId");

        if(currentTab == 'Patient_Information'){
            component.set("v.visitedTab.patientInfo" , true);
        }else if(currentTab == 'Adverse_Event'){
            component.set("v.visitedTab.adverseEvent" , true);
        }else if(currentTab == 'Suspect_Products'){
            component.set("v.visitedTab.suspectProducts" , true);
        }else if(currentTab == 'Initial_Repoter'){
            component.set("v.visitedTab.initialReporter" , true);
        }else if(currentTab == 'Manufacturer'){
            component.set("v.visitedTab.manufacturer" , true);
        }else if(currentTab == 'Additional_Info'){
            component.set("v.visitedTab.additionalInfo" , true);
        }
    },
})