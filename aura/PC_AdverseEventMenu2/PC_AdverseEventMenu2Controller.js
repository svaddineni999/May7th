/**
 * Created by peharitha on 10/26/2018.
 */
({
    doInit : function(component, event, helper) {
        helper.fetchInitData(component, event, helper);
    },
    handleCancel : function(component, event, helper) {
        //closes the modal or popover from the component
        //component.find("overlayLib").notifyClose();
        helper.handleCancel(component,event,helper);
    },
    switchTabs: function (component, event, helper){
        helper.switchTabs(component, event, helper);
    },
    handleSave : function(component, event, helper) {
        helper.clearErrors(component);
        helper.createAERec(component, event, helper);
        //$A.get('e.force:refreshView').fire();
    },
    validate : function(component, event, helper) {
        helper.validate(component, event, helper);
    },
    onEventTypeChange : function(component,event,helper){
        helper.onEventTypeChange(component,event,helper);
        helper.setNavigation(component, event, helper);
    },
    next : function(component, event, helper) {

        // get the current selected tab value
        helper.clearErrors(component);
        helper.next(component,event,helper);
    },

    back : function(component, event, helper) {
        // get the current selected tab value
        helper.clearErrors(component);
        helper.back(component,event,helper);
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
        }else if(currentTab == 'Medical_Inquiry'){
            component.set("v.visitedTab.medicalInquiry" , true);
        }else if(currentTab == 'Initial_Repoter'){
            component.set("v.visitedTab.initialReporter" , true);
        }else if(currentTab == 'Manufacturer'){
            component.set("v.visitedTab.manufacturer" , true);
        }else if(currentTab == 'Additional_Info'){
            component.set("v.visitedTab.additionalInfo" , true);
        }
    },
})