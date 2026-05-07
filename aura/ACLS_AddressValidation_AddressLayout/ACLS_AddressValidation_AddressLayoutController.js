({
    init : function(component, event, helper) {
        var pageRef = component.get("v.pageReference");
        var state = pageRef.state; // state holds any query params
        var base64Context = state.inContextOfRef;

        // For some reason, the string starts with "1.", if somebody knows why,
        // this solution could be better generalized.
        if (base64Context.startsWith("1\.")) {
            base64Context = base64Context.substring(2);
        }
        var addressableContext = JSON.parse(window.atob(base64Context));
        
        //var recordId = component.get("v.recordId");
        
        component.set("v.accountId", addressableContext.attributes.recordId);
        var accountId = component.get("v.accountId");
        if(addressableContext.attributes.objectApiName !== 'PC_Address__c'){
            component.find('accountField').set('v.value', accountId);
        }
    
    },
    handleCreateLoad: function(component, event, helper) {
        
        var addressData = [{
    
            "PC_Address_1__c": "",
            "PC_Address_2__c": null,
            "PC_City__c": "",
            
            "ACLS_Verification_Status__c": "",
            "ACLS_Address_Codes__c": "",
            
            "PC_State__c": "",
            "PC_Zip_Code__c": "",
            "ACLS_Zip_Code_Extension__c": "",
            
            "PC_Country__c": ""
        }];
        
        component.set("v.addressInfoForValidationVerified", addressData);
        
        
        
        
        
        
                 var addressInfoForValidationVerified = component.get("v.addressInfoForValidationVerified");
                
                
                 var address1Field = component.find("address1Field").get("v.value");
                 
                var address2Field = component.find("address2Field").get("v.value");
                
                var cityField = component.find("cityField").get("v.value");
                
                var stateField = component.find("stateField").get("v.value");
                var zipcodeField = component.find("zipcodeField").get("v.value");
                
                //var accountField = component.find("accountField").get("v.value");
                //var startDateField = component.find("startDateField").get("v.value");
                //var endDateField = component.find("endDateField").get("v.value");
                var verificationStatusField = component.find("verificationStatusField").get("v.value");
                //var addressCodesField = component.find("addressCodesField").get("v.value");
                //var addressTypeField = component.find("addressTypeField").get("v.value");
                //var statusField = component.find("statusField").get("v.value");
                //var countryField = component.find("countryField").get("v.value");
                var zipcodeExtensionField = component.find("zipcodeExtensionField").get("v.value");
                
                
                if(address1Field != null){
                    addressInfoForValidationVerified[0].PC_Address_1__c = address1Field;
                }
                if(address2Field != null){
                    addressInfoForValidationVerified[0].PC_Address_2__c = address2Field;
                }
                if(cityField != null){
                    addressInfoForValidationVerified[0].PC_City__c = cityField;
                }
                if(zipcodeField != null){
                    addressInfoForValidationVerified[0].PC_Zip_Code__c = zipcodeField;
                }
                if(stateField != null){
                    addressInfoForValidationVerified[0].PC_State__c = stateField;
                }
                if(zipcodeExtensionField != null){
                    addressInfoForValidationVerified[0].ACLS_Zip_Code_Extension__c = zipcodeExtensionField;
                }
                if(verificationStatusField != null){
                    addressInfoForValidationVerified[0].ACLS_Verification_Status__c = verificationStatusField;
                }
                component.set("v.addressInfoForValidationVerified",addressInfoForValidationVerified);
                
    },
	validateAddress: function(component, event, helper) {
        
        var userInputAddress = component.get("v.userInputAddress");
        
        var address1Field = component.find("address1Field").get("v.value");
        var address2Field = component.find("address2Field").get("v.value");
        var cityField = component.find("cityField").get("v.value");
        var stateField = component.find("stateField").get("v.value");
        var zipcodeField = component.find("zipcodeField").get("v.value");
        
        var accountField = component.find("accountField").get("v.value");
        var startDateField = component.find("startDateField").get("v.value");
        var endDateField = component.find("endDateField").get("v.value");
        var verificationStatusField = component.find("verificationStatusField").get("v.value");
        var addressCodesField = component.find("addressCodesField").get("v.value");
        var addressTypeField = component.find("addressTypeField").get("v.value");
        var statusField = component.find("statusField").get("v.value");
        var countryField = component.find("countryField").get("v.value");
        var zipcodeExtensionField = component.find("zipcodeExtensionField").get("v.value");
        
        
        userInputAddress =[
            {
                PC_Account__c : accountField,
                PC_Address_1__c : address1Field,
                PC_Address_2__c : address2Field,
                PC_City__c : cityField,
                PC_Start_Date__c : startDateField,
                PC_End_Date__c : endDateField,
                ACLS_Verification_Status__c : verificationStatusField,
                ACLS_Address_Codes__c : addressCodesField,
                PC_Address_Description__c : addressTypeField,
                PC_State__c : stateField,
                PC_Zip_Code__c : zipcodeField,
                ACLS_Zip_Code_Extension__c : zipcodeExtensionField,
                PC_Status__c : statusField,
                PC_Country__c : countryField
                
            }
        ]
        
        component.set('v.isValidateBtnClicked',true);
        component.set('v.userInputAddress',userInputAddress);
        //var userInputAddress1 = component.get("v.userInputAddress");
        
        component.set('v.openChildComponent',true);
        //var openChildComponent = component.get("v.openChildComponent");
        
    },
    handleSubmit: function(component, event, helper) {
        
           
          var shouldSave = true;
    
        var address1Field = component.find("address1Field").get("v.value");
        var accountField = component.find("accountField").get("v.value");
        var address2Field = component.find("address2Field").get("v.value");
        var cityField = component.find("cityField").get("v.value");
        var stateField = component.find("stateField").get("v.value");
        var zipcodeField = component.find("zipcodeField").get("v.value");
        //var countryField = component.find("countryField").get("v.value");
        var zipcodeExtensionField = component.find("zipcodeExtensionField").get("v.value");
        var verificationStatusField = component.find("verificationStatusField").get("v.value");

        var addressInfoForValidationVerified = component.get("v.addressInfoForValidationVerified");
            
            if((address1Field == null)||(address1Field == '')||(cityField == null)||(cityField == '')||(accountField == null)||(accountField == '')||((address1Field == null)&&(cityField == null))||((address1Field == '')&&(cityField == ''))||((accountField == null)&&(cityField == null))||((accountField == '')&&(cityField == ''))||((accountField == null)&&(address1Field == null))||((accountField == '')&&(address1Field == ''))||((address1Field == '')&&(cityField == '')&&(accountField == ''))||((address1Field == null)&&(cityField == null)&&(accountField == null))){
            
            var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": $A.get("$Label.c.ACLS_Error_Message_Title"),
                    
                    "message": $A.get("$Label.c.ACLS_Address_Layout_MandatoryFields_ErrorMessage"),
                     
                    "type": "error"
                });
                toastEvent.fire();
                
                 shouldSave = false;
        }
        
        else{
            
            if((addressInfoForValidationVerified[0].ACLS_Verification_Status__c == 'Verified')||(addressInfoForValidationVerified[0].ACLS_Verification_Status__c == 'Override')){
                if(addressInfoForValidationVerified[0].ACLS_Verification_Status__c == 'Verified'){
            if((address1Field != null)&&(cityField != null)&&(zipcodeField != null)&&(stateField != null)&&(zipcodeExtensionField != null)&&(verificationStatusField != null)){
                
       if((address1Field != addressInfoForValidationVerified[0].PC_Address_1__c) ||
                (address2Field != addressInfoForValidationVerified[0].PC_Address_2__c) ||(cityField != addressInfoForValidationVerified[0].PC_City__c)||
                (zipcodeField != addressInfoForValidationVerified[0].PC_Zip_Code__c)||(stateField != addressInfoForValidationVerified[0].PC_State__c)||
                (zipcodeExtensionField != addressInfoForValidationVerified[0].ACLS_Zip_Code_Extension__c)||(verificationStatusField != addressInfoForValidationVerified[0].ACLS_Verification_Status__c)){
                    
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": $A.get("$Label.c.ACLS_Error_Message_Title"),
                        "message": $A.get("$Label.c.ACLS_Address_Layout_ErrorMessage"),
                        "type": "error"
                    });
                    toastEvent.fire();
                    
                     shouldSave = false;
                    
                }
            }
             }
             if(addressInfoForValidationVerified[0].ACLS_Verification_Status__c == 'Override'){
                
                
                    
           if((address1Field != addressInfoForValidationVerified[0].PC_Address_1__c) ||
                    (address2Field != addressInfoForValidationVerified[0].PC_Address_2__c) ||(cityField != addressInfoForValidationVerified[0].PC_City__c)||
                    (zipcodeField != addressInfoForValidationVerified[0].PC_Zip_Code__c)||(stateField != addressInfoForValidationVerified[0].PC_State__c)||
                    (zipcodeExtensionField != addressInfoForValidationVerified[0].ACLS_Zip_Code_Extension__c)||(verificationStatusField != addressInfoForValidationVerified[0].ACLS_Verification_Status__c)){
                        
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": $A.get("$Label.c.ACLS_Error_Message_Title"),
                            "message": $A.get("$Label.c.ACLS_Address_Layout_ErrorMessage"),
                            "type": "error"
                        });
                        toastEvent.fire();
                        
                         shouldSave = false;
                        
                    }
                
                 }
           
            
        }
        if((addressInfoForValidationVerified[0].ACLS_Verification_Status__c == '')||(addressInfoForValidationVerified[0].ACLS_Verification_Status__c == null)){
                var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": $A.get("$Label.c.ACLS_Error_Message_Title"),
                        "message": $A.get("$Label.c.ACLS_Address_Layout_ErrorMessage"),
                        "type": "error"
                    });
                    toastEvent.fire();
                    
                     shouldSave = false;
        }
    }
        
            
                if(shouldSave){
                    event.preventDefault(); // Prevent default form submission
                 component.find("recordEditForm").submit(); // Submit the form for saving
                 var workspaceAPI = component.find("workspace");
                 workspaceAPI.getFocusedTabInfo().then(function(response) {
                     var focusedTabId = response.tabId;
                     workspaceAPI.closeTab({tabId: focusedTabId});
                 })
                 .catch(function(error) {
                 }); 
                 }
                
       
    },
    handleCancel: function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.closeTab({tabId: focusedTabId});
        })
        .catch(function(error) {
        });
    },
    handleCancelModal: function(component, event, helper) {
        component.set("v.openChildComponent", false);
    },
    handleValidatedAddressList:function(component, event, helper) {
        var addressList = event.getParam("validatedAddressList");
        
        
        component.set("v.userInputAddress", addressList);
        component.set("v.addressInfoForValidationVerified", addressList);
        //var userInputAddress = component.get("v.userInputAddress");
        var addressInfoForValidationVerified = component.get("v.addressInfoForValidationVerified");
        var newAddress = component.get("v.newAddress");
        newAddress=addressInfoForValidationVerified[0];
        component.set("v.newAddress", newAddress);
        var newAddress1 = component.get("v.newAddress");
        
        component.find('address1Field').set('v.value', newAddress1.PC_Address_1__c);
        component.find('address2Field').set('v.value', newAddress1.PC_Address_2__c);
        component.find('cityField').set('v.value', newAddress1.PC_City__c);
        component.find('stateField').set('v.value', newAddress1.PC_State__c);
        component.find('zipcodeField').set('v.value', newAddress1.PC_Zip_Code__c);
        component.find('zipcodeExtensionField').set('v.value', newAddress1.ACLS_Zip_Code_Extension__c);
        component.find('verificationStatusField').set('v.value', newAddress1.ACLS_Verification_Status__c);
        component.find('addressCodesField').set('v.value', newAddress1.ACLS_Address_Codes__c);
    }
})