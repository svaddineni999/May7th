/**
 * Created by shisbansal on 1/31/2019.
 */
({

    doInit : function(component, event, helper) {

        helper.setNamespace(component, event, helper);
        helper.resetComponentAttributes(component);
        helper.clearErrorMessages(component, event, helper);
        helper.init(component, event, helper);
    },

    toggleAccordion : function(component, event, helper) {
           CH_PC_Util.toggleAccordion(component, event, 'data-toggleContentAuraId');
    },

    setPrimaryHealthPlanDetails: function(component, event, helper){
        helper.setPrimaryHealthPlanDetails(component, event, helper);
        helper.validatePrimaryHealthPlan(component, event, helper);
    },
    setSecondaryHealthPlanDetails: function(component, event, helper){
         helper.setSecondaryHealthPlanDetails(component, event, helper);
         helper.validateSecondaryHealthPlan(component, event, helper);
     },
    setTertiaryHealthPlanDetails: function(component, event, helper){
        helper.setTertiaryHealthPlanDetails(component, event, helper);
        helper.validateTertiaryHealthPlan(component, event, helper);
    },

    setPrescriptionDetails: function(component, event, helper){
        helper.setPrescriptionDetails(component, event, helper);
        helper.validatePrescription(component, event, helper);
    },

    setClinicDetails: function(component, event, helper){
        helper.setClinicDetails(component, event, helper);
        helper.validateClinic(component, event, helper);
    },
    handleCancel : function(component, event, helper) {
        //closes the modal or popover from the component
        component.find("medicalBenefitsPopup").notifyClose();
    },
    handleSubmit : function(component, event, helper) {
        helper.clearErrorMessages(component, event, helper);
        helper.doStandardValidations(component,helper);
        helper.validateMedeBVForm(component, event, helper);
        helper.checkIfFormValid(component, event, helper);
        var isFormValid = component.get("v.isFormValid");
        if(isFormValid){
            helper.handleSubmit(component, event, helper);
        }
    },

})