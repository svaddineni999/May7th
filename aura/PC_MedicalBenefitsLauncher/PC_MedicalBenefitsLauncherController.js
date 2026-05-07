/**
 * Created by peharitha on 1/31/2019.
 */
({
    doInit: function(component, event, helper){
        helper.setNamespace(component);
    },
    openMedicalBenefitsForm : function(component, event, helper){
        var namespace = component.get("v.namespace");
        var api = namespace +':'+component.get("v.medicalBenefitsComponentName");
        var modalBody;
        $A.createComponent(api,{"caseId": component.get("v.caseId"),
                                "medicalBenefitsCmpAttributes": component.get("v.medicalBenefitsCmpAttributes")},
                           function(content, status, errorMessage) {
                               if (status === "SUCCESS") {
                                   modalBody = content;
                                   component.find('medicalBenefitsPopup').showCustomModal({
                                       header: component.get("v.medicalBenifitsPoupLabel"),
                                       body: modalBody,
                                       showCloseButton: true,
                                       cssClass: "mymodal slds-modal_large pcOverlayModal",
                                       closeCallback: function() {
                                           helper.clearErrorMessages(component, event, helper);
                                       }
                                   })
                               }else if (status === "ERROR") {
                                   // Show error message
                                   component.set("v.errors",errorMessage);
                               }else{
                                   console.log("Failed with status: " + status);
                               }
                           }
                          );

        var cmpTarget = component.find('medicalBenefitsPopup');
        $A.util.removeClass(cmpTarget, 'slds-p-around_medium');
    },
})