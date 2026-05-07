/**
 * Created by peharitha on 11/26/2018.
 */
({
    doInit: function(component, event, helper) {
        helper.setNamespace(component);
        helper.fetchPrescriptionData(component,helper);
    },
    navigateToRecord : function(component , event, helper){
        var recId = event.currentTarget.id;
        window.open('/one/one.app#/sObject/' + recId );
    },
    handleSuspectPrescriptionAddition : function(component, event, helper) {
        var suspectProductInfoObj = component.get("v.aeWrapper");
        var previousPrescriptionRec = component.get("v.suspectPrescriptionRec");
        var suspectPrescriptionRec = event.getParam("suspectPrescriptionRec");
        var isEdit = event.getParam("isEdit");
        var submissionStatus = component.get("v.submissionStatus");
        var relSuspectPrescriptions;
        var index;
        var newSuspectPrescriptionList;
        if(isEdit == false){
            newSuspectPrescriptionList = component.get("v.newSuspectPrescriptionList");
            newSuspectPrescriptionList.push(suspectPrescriptionRec);
            component.set("v.newSuspectPrescriptionList", newSuspectPrescriptionList);
            //add To Be Inserted Suspect Prescription list to aeWrapper
            suspectProductInfoObj['newSuspectPrescriptionList'] = newSuspectPrescriptionList;
            // check for submission status and update the updateprescriptionlist
             relSuspectPrescriptions = component.get("v.relSuspectPrescriptions");
             if(!$A.util.isEmpty(relSuspectPrescriptions) && !$A.util.isEmpty(submissionStatus) && submissionStatus == 'Submitted'){
                 suspectProductInfoObj['updatedSuspectPrescriptionList'] = relSuspectPrescriptions;
             }
        }else{
            if(suspectPrescriptionRec.recId == 'undefined' || suspectPrescriptionRec.recId == '' || suspectPrescriptionRec.recId == null){
                //replace edited Suspect Prescriptions with latest one in the List shown on Table
                newSuspectPrescriptionList = component.get("v.newSuspectPrescriptionList");
                index = newSuspectPrescriptionList.indexOf(previousPrescriptionRec);
                if (index > -1) {
                   newSuspectPrescriptionList[index] = suspectPrescriptionRec;
                }
                component.set("v.newSuspectPrescriptionList", newSuspectPrescriptionList);

                //add To Be Inserted Suspect Prescription list to aeWrapper
                suspectProductInfoObj['newSuspectPrescriptionList'] = newSuspectPrescriptionList;
            }else{
                var updateSuspectPList = true;
                var updatedSuspectPrescriptionList = component.get("v.updatedSuspectPrescriptionList");
                updatedSuspectPrescriptionList.push(suspectPrescriptionRec);
                component.set("v.updatedSuspectPrescriptionList", updatedSuspectPrescriptionList);

                //replace edited Suspect Prescriptions with latest one in the List shown on Table
                relSuspectPrescriptions = component.get("v.relSuspectPrescriptions");
                index = relSuspectPrescriptions.indexOf(previousPrescriptionRec);
                if (index > -1) {
                       relSuspectPrescriptions[index] = suspectPrescriptionRec;
                }
                component.set("v.relSuspectPrescriptions", relSuspectPrescriptions);

                if(!$A.util.isEmpty(submissionStatus) && submissionStatus == 'Submitted' ){
                         suspectProductInfoObj['updatedSuspectPrescriptionList'] = relSuspectPrescriptions;
                updateSuspectPList = false;
                }

                //add To Be updated Suspect Prescription list to aeWrapper
                if(updateSuspectPList == true){
                suspectProductInfoObj['updatedSuspectPrescriptionList'] = updatedSuspectPrescriptionList;
                }
            }

        }
        component.set("v.aeWrapper",suspectProductInfoObj);
    },
    validateSuspectProduct: function(component, event, helper) {
        var isAdditionalFieldsConfigValid=true;
        if(component.get("v.errors").length >0){
            isAdditionalFieldsConfigValid=false;
        }
        return isAdditionalFieldsConfigValid;
    },

    openSuspectProductPopup : function(component, event, helper){
        var productId = component.get("v.selectedProduct.val");
        if(!$A.util.isUndefinedOrNull(productId)){
            component.set("v.isEdit", false);
            component.set("v.productAvailable", true);
            component.set("v.prescriptionAvailable", false);
            helper.openPrescriptionForm(component, event, helper);
        }

    },

    openPrescriptionPopup : function(component, event, helper){
        var buttonName = event.getSource().get("v.name");
        var prescription = event.getSource().get("v.value");
        var nonePicklistLabel = component.get("v.nonePicklistLabel");
        var relProduct;
        //NEW: open new Suspect Prescription Form with out any selected existing prescription
        if(buttonName == 'newPrescription'){
            component.set("v.isEdit", false);
            component.set("v.productAvailable", false);
            component.set("v.prescriptionAvailable", false);
            helper.openNewSuspectPrescriptionForm(component, event, helper);
        }
        //NEW: open new Suspect Prescription Form with values pre-populated from selected existing prescription
        else if(buttonName == 'prescription' && prescription != nonePicklistLabel && prescription != 'undefined' && prescription != null){
            component.set("v.isEdit", false);
            component.set("v.productAvailable", false);
            component.set("v.prescriptionAvailable", true);
            helper.openPrePopulatedNewSuspectPrescriptionForm(component, event, helper,prescription);
        }
        //EDIT: open Suspect Prescription Form with data from Existing Suspect Prescription
        else if(buttonName == 'editSPButton' && prescription != 'undefined' && prescription != null){
            component.set("v.isEdit", true);
            var relPrescription = prescription.prescription;
            relProduct = prescription.product;
            if(!$A.util.isUndefinedOrNull(relProduct) && relProduct != ''){
                component.set("v.productAvailable", true);
            }else{
                component.set("v.productAvailable", false);
            }
            if(!$A.util.isUndefinedOrNull(relPrescription) && relPrescription != '' && relPrescription != nonePicklistLabel){
                component.set("v.prescriptionAvailable", true);
            }else{
                component.set("v.prescriptionAvailable", false);
            }

            helper.loadAndOpenSuspectPrescription(component, event, helper,prescription);
        }
        //EDIT: open Suspect Prescription Form with data from Draft Suspect Prescription
        else if(buttonName == 'editDraftSPButton' && !$A.util.isUndefinedOrNull(prescription) && !$A.util.isEmpty(prescription)){
            component.set("v.isEdit", true);
            relProduct = prescription.product;
            if(!$A.util.isUndefinedOrNull(relProduct) && relProduct!=''){
                component.set("v.productAvailable", true);
            }else{
                component.set("v.productAvailable", false);
            }

            if(!$A.util.isUndefinedOrNull(prescription.prescriptionId) && prescription.prescriptionId !=''){
                component.set("v.prescriptionAvailable", true);
            }else{
                component.set("v.prescriptionAvailable", false);
            }
            helper.openDraftSuspectPrescription(component, event, helper,prescription);
        }
        var cmpTarget = component.find('overlayLib');
        $A.util.removeClass(cmpTarget, 'slds-p-around_medium');
    },
    removePrescription : function(component, event, helper){
       //Remove deleted Suspect Prescriptions from Table
       var relSuspectPrescriptions = component.get("v.relSuspectPrescriptions");
       var spRec = event.getSource().get("v.value");
       var index = relSuspectPrescriptions.indexOf(spRec);
       if (index > -1) {
         relSuspectPrescriptions.splice(index, 1);
       }
       component.set("v.relSuspectPrescriptions", relSuspectPrescriptions);

       //add deleted Suspect Prescription to deletedSuspectPrescriptionList
       var deletedSPList = component.get("v.deletedSuspectPrescriptionList");
       deletedSPList.push(spRec.recId);
       component.set("v.deletedSuspectPrescriptionList", deletedSPList);

       //add To Be Deleted Suspect Prescription list to aeWrapper
       var suspectProductInfoObj = component.get("v.aeWrapper");
       suspectProductInfoObj['deletedSPList'] = deletedSPList;
       component.set("v.aeWrapper",suspectProductInfoObj);
    },
    removeNewlyAddedPrescription : function(component, event, helper){
       var suspectProductInfoObj = component.get("v.aeWrapper");
       var newSPList = component.get("v.newSuspectPrescriptionList");
       var sp = event.getSource().get("v.value");
       var index = newSPList.indexOf(sp);
       if (index > -1) {
         newSPList.splice(index, 1);
       }
       component.set("v.newSuspectPrescriptionList", newSPList);
       /*** [PC-6124]: Following two lines of code are required, since whenever any draft Suspect Product is deleted,
       the main list 'aeWrapper' also needs to be updated with the final list of new Suspect Products which would be inserted on
       click of 'Save' button on Adverse Event Menu screen.***/
       suspectProductInfoObj['newSuspectPrescriptionList'] = newSPList;
       component.set("v.aeWrapper",suspectProductInfoObj);
       /** [PC-6124] :END **/
    },
})