/**
 * Created by peharitha on 12/7/2018.
 */
({
    autoPopulateProductDetails: function (component, event, helper){
        component.set("v.additionalfieldSetFormBody", '');
        var fieldsMap= component.get("v.additionalFieldsConfig.fieldsMap");
        var fsFields= component.get("v.additionalFieldsConfig.fsFields");
        var usePrescription= component.get("v.usePrescription");
        var aeWrapper= component.get("v.aeWrapper");
        var productId = component.get("v.selectedProduct.val");
        if(!$A.util.isUndefinedOrNull(productId)){
            var action =  component.get("c.setProductDetails");
            action.setParams({
                fieldsMap: fieldsMap,
                fsFields: fsFields,
                productId: productId,
                suspectProductInfoObj: aeWrapper,
                usePrescription: usePrescription
            });
            action.setCallback(this, function(response){
                var state= response.getState();
                if (state == "SUCCESS"){
                    var aeWrap =response.getReturnValue();
                    component.set("v.aeWrapper" , aeWrap);
                    helper.createAdditionalFieldSetForm(component, event, helper);
                }
                else{
                    helper.handleErrors(component, response.getError());
                }
            });
            $A.enqueueAction(action);
        }else{
            helper.createAdditionalFieldSetForm(component, event, helper);
        }
    },


    createAdditionalFieldSetForm : function(cmp, event, helper) {
        var additionalFieldsConfig = cmp.get('v.additionalFieldsConfig');
        var action = cmp.get('c.getPopulatedFieldSet');
        action.setParams({
            fsName: additionalFieldsConfig.fieldSetName,
            suspectProductInfoObj: cmp.get("v.aeWrapper")
        });

        action.setCallback(this,
            function(response) {
            var state = response.getState();
            if (state == "SUCCESS"){
                if (response.getReturnValue()==null){
                   cmp.set("v.fsFields", null);
                }
                else{
                    var fields = response.getReturnValue().fieldPath;
                    var aeWrap = response.getReturnValue().fieldValue;
                    cmp.set("v.fsFields", fields);
                    if(fields != null && fields.length > 0){
                        if($A.util.isEmpty(fields)) {
                            // do nothing
                        }
                        else{
                            var additionalField = '';
                            for(var i=0; i<fields.length; i++) {
                                additionalField = fields[i].fieldPath;
                                if(!$A.util.isEmpty(additionalField) && $A.util.isEmpty(aeWrap[additionalField])){
                                   aeWrap[additionalField] = '';
                                }
                            }
                            cmp.set("v.aeWrapper.additionalFields", aeWrap);
                        }
                        helper.createFieldSetCmp(cmp, event, helper, fields, additionalFieldsConfig);
                    }else {
                        var noFieldsFoundErrorDescription = cmp.get("v.noFieldsFoundErrorDescription");
                        helper.handleErrors(cmp,noFieldsFoundErrorDescription);
                    }
                }
            }
            else{
               helper.handleErrors(cmp, response.getError());
            }

        });
        $A.enqueueAction(action);
    },

    createFieldSetCmp : function(cmp, event, helper, fields, additionalFieldsConfig) {
        $A.createComponent(
            cmp.get("v.namespace") + ":PC_FieldSetForm",
            {
                "fsName": additionalFieldsConfig.fieldSetName,
                "typeName": additionalFieldsConfig.objectAPIName,
                "record": cmp.getReference("v.aeWrapper.additionalFields"),
                "isValid" : cmp.getReference("v.isFieldSetFormValid")
            },
            function(newCmp, status, errorMessage){
                if (status === "SUCCESS") {
                    var body = cmp.get("v.additionalfieldSetFormBody");
                    body.push(newCmp);
                    cmp.set("v.additionalfieldSetFormBody", body);
                }else if (status === "ERROR") {
                    helper.handleErrors(cmp, errorMessage);
                }else if (status === "INCOMPLETE") {
                    console.log("No response from server or client is offline.")
                }else{
                    console.log("Creating Additional Fields Form on Suspect Prescription Failed with status>> "+status)
                }
            }
        );
    },

    addSuspectProduct: function (component, event, helper){
        var aeWrapperMap = component.get("v.aeWrapper");
        if(aeWrapperMap.productName == '' || aeWrapperMap.productName == null){
            var error = component.get("v.reviewErrors");
            component.set("v.errors", [error]);
        }else{
            var action =  component.get("c.addSuspectPrescription");
            action.setParams({
                aeId: component.get("v.aeId"),
                suspectProductInfoObj: aeWrapperMap
            });
            action.setCallback(this, function(response){
                var state= response.getState();
                if (state == "SUCCESS"){
                    var newSP = response.getReturnValue();
                    newSP['additionalFields'] = component.get("v.aeWrapper.additionalFields");
                    //Fire pushSPlistEvent Event
                    var pushSPlistEvent = component.getEvent("pushSPlistEvent");
                    pushSPlistEvent.setParams({
                        "suspectPrescriptionRec" : newSP,
                        "isEdit" : component.get("v.isEdit")
                    });
                    pushSPlistEvent.fire();
                    //close the Suspect Prescription Form Popup
                    component.find("overlayLib").notifyClose();
                }
                else{
                    helper.handleErrors(component, response.getError());
                }
            });
            $A.enqueueAction(action);
        }
    },

    updateSuspectProduct: function (component, event, helper){
        var suspectProductInfoObj = component.get("v.aeWrapper");
        var spRec = component.get("v.suspectPrescriptionRec");

        //spRec.prescription = suspectProductInfoObj['prescription'];
        spRec.productName = suspectProductInfoObj['productName'];
        spRec.product = suspectProductInfoObj['product'];
        spRec.productStrength = suspectProductInfoObj['productStrength'];
        spRec.manufacturer = suspectProductInfoObj['manufacturer'];
        spRec.ndc = suspectProductInfoObj['ndc'];
        spRec.lot = suspectProductInfoObj['lot'];
        spRec.concomitant = suspectProductInfoObj['concomitant'];
        spRec.dose = suspectProductInfoObj['dose'];
        spRec.frequency = suspectProductInfoObj['frequency'];
        spRec.route = suspectProductInfoObj['route'];
        spRec.therapyStartDate = suspectProductInfoObj['therapyStartDate'];
        spRec.therapyEndDate = suspectProductInfoObj['therapyEndDate'];
        spRec.diagnosis = suspectProductInfoObj['diagnosis'];
        spRec.prodCompounded = suspectProductInfoObj['prodCompounded'];
        spRec.prodOTC = suspectProductInfoObj['prodOTC'];
        spRec.expirationDate = suspectProductInfoObj['expirationDate'];
        spRec.eventAbated = suspectProductInfoObj['eventAbated'];
        spRec.eventReappeared = suspectProductInfoObj['eventReappeared'];
        spRec.additionalFields = suspectProductInfoObj['additionalFields'];

        //Fire pushSPlistEvent Event
        var pushSPlistEvent = component.getEvent("pushSPlistEvent");
        pushSPlistEvent.setParams({
            "suspectPrescriptionRec" : spRec,
            "isEdit" : component.get("v.isEdit")
            });
        pushSPlistEvent.fire();
        //close the Suspect Prescription Form Popup
        component.find("overlayLib").notifyClose();
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