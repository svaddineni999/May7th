/**
 * Created by vkashikar on 1/30/2018.
 Modification Log:
 Shishir Bansal           [PC-3055] Added toggle method for Rearrange existing UI components on Rx RTBC (e-benefits investigation
                          for pharmacy) pop out
 Shishir Bansal           [PC-3568] added lighting component name(PC_ViewSPsByPayer) in the action Center Attributes
 */
({
    doInit : function(component, event, helper) {
        debugger;
        helper.setNamespace(component);
        helper.setRecordId(component);
        component.set("v.isModalMapActive",true);
        //helper.applyCSS(component);
        helper.getEBenefitsInfo(component, event, helper);
        
    },
    closeWindow : function(component, event, helper){
        //helper.revertCssChange(component);
        component.set("v.isModalMapActive", false);
    },
    submit : function(component, event, helper){
        debugger;
        helper.submit(component, event, helper);
    },
    
    changePrescription : function(component, event, helper){
        debugger;
        var selectedPrescriptionId = component.find("select-03").get("v.value");
        if($A.util.isEmpty(selectedPrescriptionId) || selectedPrescriptionId.toLowerCase() == 'select') {
            selectedPrescriptionId = '';
        }
        component.set("v.selectedPharmcyIdForfinder",selectedPrescriptionId);
        helper.updatePrescriptionInfo(component, event, helper);
    },
    addCoverage : function(component, event, helper){
        debugger;
        var action = component.get("c.createProgramCoverage");
        action.setParams({
            "pharmacyBenefitsDetails_JSON" : JSON.stringify(component.get("v.selectedOuput"))
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                component.set("v.pharmacyCoverage",returnValue);
                var successMsg = component.get("v.progCoverageSuccessMsg");
                var toastSuccessTitle = component.get("v.toastTitleSuccess");
                helper.showToastSuccess(component, event, helper, successMsg,"success",toastSuccessTitle);
                component.set("v.isModalMapActive", false);
            } else {
                var lightningErrorMsg = component.get("v.lightningErrorMsg");
                var toastErrorTitle = component.get("v.toastTitleError");
                helper.showToast(component, event, helper, lightningErrorMsg,"error",toastErrorTitle);
            }
            //helper.revertCssChange(component);
        });
        $A.enqueueAction(action);
        
        
    },



    viewPreferredPBM:function(component,event,helper){


        var viewSpsByPayerCmpName = component.get("v.specialtyPharmacyByPayerCmpName");

        var recordId = component.get("v.recordId");
        var modalBody;
        try{
            if($A.util.isEmpty(viewSpsByPayerCmpName)){
                throw new Error(component.get("v.configurationErrorMsg"));
            }

            if(!(viewSpsByPayerCmpName.indexOf(':') > -1)){
                viewSpsByPayerCmpName = component.get("v.namespace") + ":" + viewSpsByPayerCmpName;
            }

        $A.createComponent(viewSpsByPayerCmpName,{},
            function(content, status, errorMessage) {

                if (status === "SUCCESS") {

                    modalBody = content;
                    component.find('ePAOverlay').showCustomModal({
                        header: component.get("v.PBM_ModalTitle"),
                        body: modalBody,
                        showCloseButton: true,
                        cssClass : "ePAOverlay",
                        closeCallback: function() {
                            document.body.style.overflow = "auto"; // to handle salesforce defect with respect to overlays.
                        }
                    })
                }

            });
        }
        catch(error){
            var lightningErrorMsg = error.message;
            var toastErrorTitle = component.get("v.toastTitleError");
            helper.showToast(component, event, helper, lightningErrorMsg,"error",toastErrorTitle);
        }
    },

    toggleAccordion : function(component, event, helper) {

        var currentTarget = event.currentTarget;
        var toggleElementAuraId = currentTarget.getAttribute('data-toggleContentAuraId');
        helper.toggleAccordion(component, toggleElementAuraId);


    },
    radioChecked : function(component, event, helper){
        var element = event.getSource().get("v.text");
        if(event.getSource().get("v.value")){
            component.set("v.selectedOuput",element);
        }
    },
    
    updatePatientInfo : function(component, event, helper){
        helper.updateCardHolderInfo(component, event, helper);
    },
    handleAddPharmacy : function(component, event, helper) {
        helper.handleAddPharmacy(component, event, helper);
    },
    removePharmacies : function(component, event, helper){
        debugger;
        helper.handleRemovePharmacy(component, event, helper);
    }

    
})