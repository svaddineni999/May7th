({
    doInit : function(component, event, helper) {
        var addressInfoList = component.get("v.addressInfo");
        var initAddressInfoForValidationVerified = addressInfoList.slice(0);//copying addressInfoList into initAddressInfoForValidationVerified
        component.set("v.initAddressInfoForValidation", addressInfoList);
        component.set("v.initAddressInfoForValidationVerified", initAddressInfoForValidationVerified);
        //var initAddressInfoForValidation = component.get("v.initAddressInfoForValidation");
        
        
        var addressMapList = [];
        var addressInfoForValidationVerifiedMapList = [];
        
        for (var i = 0; i < addressInfoList.length; i++) {
          var addressObj = addressInfoList[i];
          
          
          var map = {};
          map[addressObj.AddressId] = addressObj;
          
          
          addressMapList.push(map);
        }
        component.set("v.addressMapList", addressMapList);
        
        for (var i = 0; i < initAddressInfoForValidationVerified.length; i++) {
            var addressObj = addressInfoList[i];
            
            
            var map = {};
            map[addressObj.AddressId] = addressObj;
            
            
            addressInfoForValidationVerifiedMapList.push(map);
          }
          component.set("v.addressInfoForValidationVerifiedMapList", addressInfoForValidationVerifiedMapList);
        
        

        
        
    },
    validateAddress: function(component, event, helper) {
        
        var parentCmp = component.getSuper();
        
        
        var patientInfoCmp = parentCmp.find('patientInformation');
        
        //var pcRecordFormCmp = patientInfoCmp.find('pcRecordFormByFieldSets');
        
        
        
        var addressInfoList = component.get("v.addressInfo");
        
        if(addressInfoList && addressInfoList.length > 0){
            
            component.set('v.showAddressValidation',true);
            component.set('v.addressInfoForValidation',addressInfoList);
            component.set('v.openChildComponent',true);
            component.set('v.isEnrollmentWizardComponent',true);
        }
        
        
    },
    handleCancelModal: function(component, event, helper) {
        component.set("v.openChildComponent", false);
        
        
    },
    
    validate: function(component, event, helper) {
        component.set('v.isValid', false);
        //Calls validate function of parent component
        var parentCmp = component.getSuper();
        parentCmp.validate();
        /*
         *isValid is a global attribute.
         *If parent component is invalid then isValid will be false.
         */
        var parentIsValid = component.get("v.isValid");
        
        var childIsValid = false;
        //Validation logic for child component to be executed only if parent component is valid.
        if (parentIsValid) {
            /*
             *Logic can be added to validate the fields of yourcomponent
             */
            //Custom validation logic for parent component fields
            
            var patientInfoCmp = parentCmp.find('patientInformation');
            var pcRecordFormCmp = patientInfoCmp.find('pcRecordFormByFieldSets');
            var formFields = pcRecordFormCmp.getAllFormValues();
            if (formFields[' PatientConnect__PC_First_Name__c'] == '') {
                //Custom error message can be assigned for parent component fields.
                pcRecordFormCmp.setErrors('PatientConnect__PC_First_Name__c', 'First Name should not be blank');
            } else {
                childIsValid = true;
            }
            
            //Below line is required to make sure the custom error message is displayed on UI.
            pcRecordFormCmp.validateForm();
        }
        
        var addressInfoForValidationVerified = component.get("v.addressInfoForValidationVerified");
        var addressInfoList = component.get("v.addressInfo");
        var verificationStatusCheck = false;
        for(i=0;i<addressInfoList.length;i++){
            if(!(addressInfoList[i].hasOwnProperty('ACLS_Verification_Status__c'))||addressInfoList[i].ACLS_Verification_Status__c == ''){
                verificationStatusCheck = true;
                break;
            }
        }
        if(!addressInfoForValidationVerified){
            if(verificationStatusCheck){
                var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": $A.get("$Label.c.ACLS_Error_Message_Title"),
                         "message": $A.get("$Label.c.ACLS_Address_Validation_Message"),
                        "type": "error"
                    });
                    toastEvent.fire();
                    childIsValid = false;
                    component.set("v.isValid", childIsValid);
            }
            else{
            
            var addressInfoList = component.get("v.addressInfo");
            
            
            var initAddressInfoForValidation = component.get("v.initAddressInfoForValidation");

            
            var addressMapList = component.get("v.addressMapList");
             addressMapList = [];
        
        
        for (var i = 0; i < addressInfoList.length; i++) {
          var addressObj = addressInfoList[i];
          
          
          var map = {};
          map[addressObj.AddressId] = addressObj;
          
          
          addressMapList.push(map);
        }
            var addressInfoForValidationVerifiedMapList = component.get("v.addressInfoForValidationVerifiedMapList");
            if(initAddressInfoForValidation.length > addressInfoList.length){
                for(var i=0; i<addressInfoForValidationVerifiedMapList.length; i++) {
                    
                    var key = Object.keys(addressInfoForValidationVerifiedMapList[i])[0];
                    var address = addressInfoForValidationVerifiedMapList[i][key];
            
                    var exists = false;
                    for(var j=0; j<addressInfoList.length; j++) {
                        
                        if(address.AddressId === addressInfoList[j].AddressId) {
                            exists = true;
                            break;
                        }
                    }
            
                    // If the address doesn't exist in the updated addressList, remove it from both the addressMapList and the addressInfoForValidationVerifiedMapList
                    if(!exists) {
                        
                        
                        addressInfoForValidationVerifiedMapList.splice(i, 1);
                        i--;
                    }
                }
            }
            if(initAddressInfoForValidation.length < addressInfoList.length){
                var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": $A.get("$Label.c.ACLS_Error_Message_Title"),
                         "message": $A.get("$Label.c.ACLS_Address_Validation_Message"),
                        "type": "error"
                    });
                    toastEvent.fire();
                    childIsValid = false;
                    component.set("v.isValid", childIsValid);
            }
            
            if( addressMapList.length == addressInfoForValidationVerifiedMapList.length){
                
                for (var i=0; i < addressMapList.length; i++) {
                    
                    var AddressId = Object.keys(addressMapList[i])[0];
                    
                    

                    if ((addressMapList[i][AddressId].PC_Address_1__c !== addressInfoForValidationVerifiedMapList.find(item => Object.keys(item)[0] === AddressId)[AddressId].PC_Address_1__c)||
                    (addressMapList[i][AddressId].PC_City__c !== addressInfoForValidationVerifiedMapList.find(item => Object.keys(item)[0] === AddressId)[AddressId].PC_City__c) ||
                    (addressMapList[i][AddressId].PC_Zip_Code__c !== addressInfoForValidationVerifiedMapList.find(item => Object.keys(item)[0] === AddressId)[AddressId].PC_Zip_Code__c) ||
                    (addressMapList[i][AddressId].PC_State__c !== addressInfoForValidationVerifiedMapList.find(item => Object.keys(item)[0] === AddressId)[AddressId].PC_State__c) ||
                    (addressMapList[i][AddressId].ACLS_Zip_Code_Extension__c !== addressInfoForValidationVerifiedMapList.find(item => Object.keys(item)[0] === AddressId)[AddressId].ACLS_Zip_Code_Extension__c) ||
                    (addressMapList[i][AddressId].ACLS_Verification_Status__c !== addressInfoForValidationVerifiedMapList.find(item => Object.keys(item)[0] === AddressId)[AddressId].ACLS_Verification_Status__c)) {
                
                var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": $A.get("$Label.c.ACLS_Error_Message_Title"),
                         "message": $A.get("$Label.c.ACLS_Address_Validation_Message"),
                        "type": "error"
                    });
                    toastEvent.fire();
                    childIsValid = false;
                    component.set("v.isValid", childIsValid);
               }
                }
            }
        }
        } 
        
        if(addressInfoForValidationVerified){
            var verifiedStatusCheck = false;
        for(i=0;i<addressInfoForValidationVerified.length;i++){
            if(addressInfoForValidationVerified[i].ACLS_Verification_Status__c == ''){
                verifiedStatusCheck = true;
                break;
            }
        }
            if(verifiedStatusCheck){
                var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": $A.get("$Label.c.ACLS_Error_Message_Title"),
                         "message": $A.get("$Label.c.ACLS_Address_Validation_Message"),
                        "type": "error"
                    });
                    toastEvent.fire();
                    childIsValid = false;
                    component.set("v.isValid", childIsValid);
            }else{
        var addressInfoList = component.get("v.addressInfo");
        var addressMapList = component.get("v.addressMapList");
             addressMapList = [];
        
        
        for (var i = 0; i < addressInfoList.length; i++) {
          var addressObj = addressInfoList[i];
          
          
          var map = {};
          map[addressObj.AddressId] = addressObj;
          
          
          addressMapList.push(map);
        }
        var addressInfoForValidationVerified = component.get("v.addressInfoForValidationVerified");
        var addressInfoForValidationVerifiedMapList = component.get("v.addressInfoForValidationVerifiedMapList");
             addressInfoForValidationVerifiedMapList = [];
             
             for (var i = 0; i < addressInfoForValidationVerified.length; i++) {
          var addressObj = addressInfoForValidationVerified[i];
          
          
          var map = {};
          map[addressObj.AddressId] = addressObj;
          
          
          addressInfoForValidationVerifiedMapList.push(map);
        }
        for (var i=0; i < addressMapList.length; i++) {
                    
                    var AddressId = Object.keys(addressMapList[i])[0];
                    
                    

                    if ((addressMapList[i][AddressId].PC_Address_1__c !== addressInfoForValidationVerifiedMapList.find(item => Object.keys(item)[0] === AddressId)[AddressId].PC_Address_1__c)||
                    (addressMapList[i][AddressId].PC_City__c !== addressInfoForValidationVerifiedMapList.find(item => Object.keys(item)[0] === AddressId)[AddressId].PC_City__c) ||
                    (addressMapList[i][AddressId].PC_Zip_Code__c !== addressInfoForValidationVerifiedMapList.find(item => Object.keys(item)[0] === AddressId)[AddressId].PC_Zip_Code__c) ||
                    (addressMapList[i][AddressId].PC_State__c !== addressInfoForValidationVerifiedMapList.find(item => Object.keys(item)[0] === AddressId)[AddressId].PC_State__c) ||
                    (addressMapList[i][AddressId].ACLS_Zip_Code_Extension__c !== addressInfoForValidationVerifiedMapList.find(item => Object.keys(item)[0] === AddressId)[AddressId].ACLS_Zip_Code_Extension__c) ||
                    (addressMapList[i][AddressId].ACLS_Verification_Status__c !== addressInfoForValidationVerifiedMapList.find(item => Object.keys(item)[0] === AddressId)[AddressId].ACLS_Verification_Status__c)) {
                
                var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": $A.get("$Label.c.ACLS_Error_Message_Title"),
                         "message": $A.get("$Label.c.ACLS_Address_Validation_Message"),
                        "type": "error"
                    });
                    toastEvent.fire();
                    childIsValid = false;
                    component.set("v.isValid", childIsValid);
               }
                }
                
}
}       
        
    },
    handleValidatedAddressList:function(component, event, helper) {
        var addressList = event.getParam("validatedAddressList");
        for (var i=0; i < addressList.length; i++) {
            if((addressList[i].ACLS_Verification_Status__c !== '')&&(addressList[i].ACLS_Verification_Status__c !== null)){
                component.set("v.addressInfo", addressList);
        component.set("v.addressInfoForValidationVerified", addressList);
            }
        }
        
        
        
    }
})