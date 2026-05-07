/**
 * Created by peharitha on 11/26/2018.
 */
({
    openPrePopulatedNewSuspectPrescriptionForm: function (component, event, helper,prescriptionId){
        var action =  component.get("c.prePopulateSuspectPrescriptionForm");
        action.setParams({
            fieldsMap: component.get("v.additionalFieldsConfig.fieldsMap"),
            fsFields: component.get("v.additionalFieldsConfig.fsFields"),
            prescriptionId: prescriptionId,
            suspectProductInfoObj: component.get("v.aeWrapper")
        });
        action.setCallback(this, function(response){
            var state= response.getState();
            if (state == "SUCCESS"){
                var aeWrap =response.getReturnValue();
                component.set("v.aeWrapper" , aeWrap);
                helper.openPrescriptionForm(component, event, helper);
            }
            else{
                helper.handleErrors(component, response.getError());
            }
        });
        $A.enqueueAction(action);
    },

    openNewSuspectPrescriptionForm: function (component, event, helper,prescriptionId){

        var suspectProductInfoObj = component.get("v.aeWrapper");
        suspectProductInfoObj['prescription'] = '';
        suspectProductInfoObj['product'] =  '';
        suspectProductInfoObj['productName'] =  '';
        suspectProductInfoObj['productStrength'] = '';
        suspectProductInfoObj['manufacturer'] = '';
        suspectProductInfoObj['ndc'] = '';
        suspectProductInfoObj['lot'] = '';
        suspectProductInfoObj['concomitant'] = '';
        suspectProductInfoObj['dose'] = '';
        suspectProductInfoObj['frequency'] = '';
        suspectProductInfoObj['route'] = '';
        suspectProductInfoObj['therapyStartDate'] = '';
        suspectProductInfoObj['therapyEndDate'] = '';
        suspectProductInfoObj['diagnosis'] = '';
        suspectProductInfoObj['prodCompounded'] = '';
        suspectProductInfoObj['prodOTC'] = '';
        suspectProductInfoObj['expirationDate'] = '';
        suspectProductInfoObj['eventAbated'] = '';
        suspectProductInfoObj['eventReappeared'] = '';
        suspectProductInfoObj['additionalFields'] = null;
        component.set("v.aeWrapper" , suspectProductInfoObj);
        helper.openPrescriptionForm(component, event, helper);

    },

    loadAndOpenSuspectPrescription: function (component, event, helper,spRec){
        var suspectProductInfoObj = component.get("v.aeWrapper");

        suspectProductInfoObj['prescription'] = spRec.prescription;
        suspectProductInfoObj['product'] =  spRec.product;
        suspectProductInfoObj['productName'] =  spRec.productName;
        suspectProductInfoObj['productStrength'] = spRec.productStrength;
        suspectProductInfoObj['manufacturer'] = spRec.manufacturer;
        suspectProductInfoObj['ndc'] = spRec.ndc;
        suspectProductInfoObj['lot'] = spRec.lot;
        suspectProductInfoObj['concomitant'] = spRec.concomitant;
        suspectProductInfoObj['dose'] = spRec.dose;
        suspectProductInfoObj['frequency'] = spRec.frequency;
        suspectProductInfoObj['route'] = spRec.route;
        suspectProductInfoObj['therapyStartDate'] = spRec.therapyStartDate;
        suspectProductInfoObj['therapyEndDate'] = spRec.therapyEndDate;
        suspectProductInfoObj['diagnosis'] = spRec.diagnosis;
        suspectProductInfoObj['prodCompounded'] = spRec.prodCompounded;
        suspectProductInfoObj['prodOTC'] = spRec.prodOTC;
        suspectProductInfoObj['expirationDate'] = spRec.expirationDate;
        suspectProductInfoObj['eventAbated'] = spRec.eventAbated;
        suspectProductInfoObj['eventReappeared'] = spRec.eventReappeared;
        suspectProductInfoObj['additionalFields'] = spRec.additionalFields;
        component.set("v.aeWrapper" , suspectProductInfoObj);
        component.set("v.suspectPrescriptionRec" , spRec);
        helper.openPrescriptionForm(component, event, helper);
    },

    openDraftSuspectPrescription: function (component, event, helper,spRec){
        var suspectProductInfoObj = component.get("v.aeWrapper");

        suspectProductInfoObj['prescription'] = spRec.prescription;
        suspectProductInfoObj['product'] =  spRec.product;
        suspectProductInfoObj['productName'] =  spRec.productName;
        suspectProductInfoObj['productStrength'] = spRec.productStrength;
        suspectProductInfoObj['manufacturer'] = spRec.manufacturer;
        suspectProductInfoObj['ndc'] = spRec.ndc;
        suspectProductInfoObj['lot'] = spRec.lot;
        suspectProductInfoObj['concomitant'] = spRec.concomitant;
        suspectProductInfoObj['dose'] = spRec.dose;
        suspectProductInfoObj['frequency'] = spRec.frequency;
        suspectProductInfoObj['route'] = spRec.route;
        suspectProductInfoObj['therapyStartDate'] = spRec.therapyStartDate;
        suspectProductInfoObj['therapyEndDate'] = spRec.therapyEndDate;
        suspectProductInfoObj['diagnosis'] = spRec.diagnosis;
        suspectProductInfoObj['prodCompounded'] = spRec.prodCompounded;
        suspectProductInfoObj['prodOTC'] = spRec.prodOTC;
        suspectProductInfoObj['expirationDate'] = spRec.expirationDate;
        suspectProductInfoObj['eventAbated'] = spRec.eventAbated;
        suspectProductInfoObj['eventReappeared'] = spRec.eventReappeared;
        suspectProductInfoObj['additionalFields'] = spRec.additionalFields;

        component.set("v.aeWrapper" , suspectProductInfoObj);
        component.set("v.suspectPrescriptionRec" , spRec);

        helper.openPrescriptionForm(component, event, helper);
    },

    openPrescriptionForm: function (component, event, helper){
        var suspectProductModalHeader = component.get("v.prescriptionFormPopupLabel");
        if(component.get("v.isMedicalInquiry")){
            suspectProductModalHeader = component.get("v.medicalInquiryProductLabel");
        }
        var namespace = component.get("v.namespace");
        var nonePicklistLabel = component.get("v.nonePicklistLabel");
        var api = namespace +':'+ component.get("v.prescriptionFormComp");
        var modalBody;
        $A.createComponent(api,{"fieldLabels": component.get("v.fieldLabels"),
                                "aeId": component.get("v.aeId"),
                                "isEdit": component.get("v.isEdit"),
                                "productAvailable": component.get("v.productAvailable"),
                                "prescriptionAvailable": component.get("v.prescriptionAvailable"),
                                "suspectPrescriptionRec": component.get("v.suspectPrescriptionRec"),
                                "aeWrapper": component.get("v.aeWrapper"),
                                "usePrescription": component.get("v.usePrescription"),
                                "isMedicalInquiry":component.get("v.isMedicalInquiry"),
                                "namespace": component.get("v.namespace"),
                                "selectedProduct": component.get("v.selectedProduct"),
                                "additionalFieldsConfig": component.get("v.additionalFieldsConfig"),
                                "prodCompoundedOptions": component.get("v.prodCompoundedOptions"),
                                "prodOTCOptions": component.get("v.prodOTCOptions"),
                                "eventAbatedOptions": component.get("v.eventAbatedOptions"),
                                "eventReappearedOptions": component.get("v.eventReappearedOptions"),
                                "dateFormatErrorMessage" : component.get("v.dateFormatErrorMessage"),
                                "dateFormat" : component.get("v.dateFormat"),
                                "pushSPlistEvent": component.getReference("c.handleSuspectPrescriptionAddition")},function(content, status, errorMessage) {
            if (status === "SUCCESS") {
               modalBody = content;
               component.find('overlayLib').showCustomModal({
                   header: suspectProductModalHeader,//component.get("v.prescriptionFormPopupLabel"),
                   body: modalBody,
                   showCloseButton: true,
                   cssClass: "mymodal slds-modal_medium pcOverlayModal pcLightningFormOverride",
                   closeCallback: function() {
                        component.set("v.aeWrapper.prescription", nonePicklistLabel);
                        component.set("v.selectedProduct", null);
                        component.set("v.aeWrapper.additionalFields", null);
                   }
               })
            }else if (status === "ERROR") {
                // Show error message
                helper.handleErrors(component, errorMessage);
            }
        });
    },

    fetchPrescriptionData : function(component,helper){
        var nonePicklistLabel = component.get("v.nonePicklistLabel");
        if($A.util.isUndefinedOrNull(component.get("v.usePrescription"))){
            component.set("v.usePrescription", true);
        }
        var action = component.get("c.getPrescriptionData");
        action.setParams({
            caseId: component.get("v.caseId"),
            aeId: component.get("v.aeId"),
            usePrescription: component.get("v.usePrescription"),
            isMedicalInquiry: false //Later for additional information it needs to be component.get("v.isMedicalInquiry");
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {

                var returnValue = response.getReturnValue();
                component.set("v.fieldLabels", returnValue.fieldLabels);

                if(returnValue.suspectPrescriptions != 'undefined' && returnValue.suspectPrescriptions != null){
                    component.set("v.relSuspectPrescriptions", returnValue.suspectPrescriptions);

                    /** PC-6141: Following lines of code have been added in order to update 'aeWrapper' attribute with existing list of
                    suspect prescriptions required to be populated when the Suspect Prescription tab is visited on editing a new version of AE record **/
                    var suspectProductInfoObj = component.get("v.aeWrapper");
                    var submissionStatus = component.get("v.submissionStatus");
                    var relSuspectPrescriptions = component.get("v.relSuspectPrescriptions");
                    var existingSuspectPrescriptionList = suspectProductInfoObj['updatedSuspectPrescriptionList'];

                    if(!$A.util.isEmpty(relSuspectPrescriptions) && !$A.util.isEmpty(submissionStatus) && submissionStatus == 'Submitted'){
                        if($A.util.isEmpty(existingSuspectPrescriptionList)){
                            suspectProductInfoObj['updatedSuspectPrescriptionList'] = relSuspectPrescriptions;
                        }
                    }
                    component.set("v.aeWrapper",suspectProductInfoObj);
                    /** PC-6141 -- END**/
                }
                component.set("v.prodCompoundedOptions", returnValue.prodCompoundedOptions);
                component.set("v.prodOTCOptions", returnValue.prodOTCOptions);
                component.set("v.eventAbatedOptions", returnValue.eventAbatedOptions);
                component.set("v.eventReappearedOptions", returnValue.eventReappearedOptions);

                var prescriptions=[];
                prescriptions.push({label: nonePicklistLabel, value:nonePicklistLabel});
                for(var i=0;i< returnValue.prescriptions.length;i++){
                    prescriptions.push({label: returnValue.prescriptions[i].label, value:returnValue.prescriptions[i].value});
                }
                component.set("v.prescriptions", prescriptions);
                component.set('v.additionalFieldsConfig', returnValue.additionalFieldsConfig);
            }else {
                helper.handleErrors(component, response.getError());
            }
        });
        $A.enqueueAction(action);
    },

    setNamespace : function(component) {
        var component_to_string = component.toString();
        var markupTagLoc = component_to_string.indexOf('markup://');
        var endOfNamespaceLoc = component_to_string.indexOf(':',markupTagLoc+9);
        var ns = component_to_string.substring(markupTagLoc+9,endOfNamespaceLoc);
        var namespacePrefix = (ns == "c" || ns == "C") ?  "" :  ns + "__";
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", namespacePrefix);

    },
    handleErrors : function(component, errors) {
        var allErrors = new Array();
        if (!$A.util.isEmpty(errors)) {
            if (errors[0] && errors[0].message) {
                allErrors.push(errors[0].message);
            }
        } else {
            console.log('Unknown Error');
            allErrors.push('Unknown error');
        }
        component.set("v.errors", allErrors);
    },
})