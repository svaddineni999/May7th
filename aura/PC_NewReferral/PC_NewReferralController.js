/**
 * Created by vkashikar on 8/13/2018.
 */
({
    handleClick : function(component, event, helper) {
        debugger;
        helper.clearErrorMessages(component, event, helper);
        var selectedButton = event.getSource();
        var selectedButtonName = selectedButton.get("v.name");
        if(selectedButtonName == "yesBtn") {
            helper.toggleButtons(component, event, helper, "yesBtn");
        }
        else {
            helper.toggleButtons(component, event, helper, "noBtn");
        }

    },
    doInit : function(component, event, helper) {
        debugger;
        helper.setNamespace(component);
        helper.setRecordId(component, event, helper);
        helper.clearErrorMessages(component, event, helper);
        helper.fetchFormData(component, event, helper);
    },
    setSelectedProgramCoverage : function(component, event, helper) {
        helper.clearErrorMessages(component);
        helper.setSelectedProgramCoverage(component, event, helper);
    },
    submit : function(component, event, helper) {
        helper.createNewReferral(component, event, helper);
    }

})