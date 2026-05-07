({
    cancelhandle: function(component, event, helper) {
        var isEnrollmentWizard = component.get("v.isEnrollmentWizard");
        if(isEnrollmentWizard){
        var count=component.get("v.count");
    
    var addressList=component.get("v.addressList");
    if(addressList[count].ACLS_Verification_Status__c == 'Override'){
        addressList[count].ACLS_Verification_Status__c='Override';
    }
    else if(addressList[count].ACLS_Verification_Status__c == 'Verified'){
        addressList[count].ACLS_Verification_Status__c='Verified';
    }
    else{
        addressList[count].ACLS_Verification_Status__c='';
    }
    
    
    
    var sendValidatedAddressList = component.getEvent("validatedAddressList");
        sendValidatedAddressList.setParams({
            "validatedAddressList": addressList
        });
        sendValidatedAddressList.fire();
    }
            var cancelEvent = component.getEvent("cancelModal");
    cancelEvent.fire();
        
        
    

    },
    
    doInit : function(component, event, helper) {
        
        
        var addressList = component.get("v.addressList")[0];
        component.set("v.addressValue",addressList);
        
        component.set("v.count",0);
        
        if(component.get("v.addressValue")){
            component.set("v.openChild",true);
            
            
        }
        
        var addressValue=component.get("v.addressValue");
        
        var action = component.get("c.verifyAddress");
        action.setParams({
            "actuala1": addressValue.PC_Address_1__c,
            "actuala2": addressValue.PC_Address_2__c,
            "actualpostal": addressValue.PC_Zip_Code__c,
            "actualstate": addressValue.PC_State__c,
            "actualcity": addressValue.PC_City__c,
            "actualcountry": addressValue.PC_Country__c
        });
        
        action.setCallback(this,function(response){
            
            var state = response.getState();
            console.log(state);
            
            if (state === "SUCCESS"){
                console.log('response.getReturnValue() '+JSON.stringify(response.getReturnValue()));
                component.set("v.suggestedAddress",response.getReturnValue());
            }
            else {
                console.log(response.getError());
               console.log(JSON.stringify(response));
            }
        });
        $A.enqueueAction(action);
    
},

verifyMelissaAddress: function(component, event, helper) {
    component.set("v.isAcceptClicked",true);
    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": $A.get("$Label.c.ACLS_Address_Verification_Status"),
                         "message": $A.get("$Label.c.ACLS_Address_Verified")  
                    });
                    toastEvent.fire();
    var count=component.get("v.count");
    console.log('count verifyMelissaAddress '+count);
    var addressList=component.get("v.addressList");
    var suggestedAddress=component.get("v.suggestedAddress");
    addressList[count].PC_Address_1__c = suggestedAddress.PC_Address_1__c;
    addressList[count].PC_Address_2__c = suggestedAddress.PC_Address_2__c;
    addressList[count].PC_Zip_Code__c = suggestedAddress.PC_Zip_Code__c;
    addressList[count].PC_State__c = suggestedAddress.PC_State__c;
    addressList[count].PC_City__c = suggestedAddress.PC_City__c;
    addressList[count].PC_Country__c = suggestedAddress.PC_Country__c;
    addressList[count].ACLS_Zip_Code_Extension__c = suggestedAddress.ACLS_Zip_Code_Extension__c;
    addressList[count].ACLS_Address_Codes__c = suggestedAddress.ACLS_Address_Codes__c;
    addressList[count].ACLS_Verification_Status__c='Verified';
    console.log('addressList[count] '+ JSON.stringify(addressList[count]));
    var sendValidatedAddressList = component.getEvent("validatedAddressList");
        sendValidatedAddressList.setParams({
            "validatedAddressList": addressList
        });
        sendValidatedAddressList.fire();
    if(count <= addressList.length-2){
        
            
        
        count++;
        
        console.log('count verifyMelissaAddress line64 '+count);
        component.set("v.count",count);
        component.set("v.addressValue",addressList[count]);
        var addressValue=component.get("v.addressValue");
        var action = component.get("c.verifyAddress");
        
        action.setParams({
            "actuala1": addressValue.PC_Address_1__c,
            "actuala2": addressValue.PC_Address_2__c,
            "actualpostal": addressValue.PC_Zip_Code__c,
            "actualstate": addressValue.PC_State__c,
            "actualcity": addressValue.PC_City__c,
            "actualcountry": addressValue.PC_Country__c
            
        });
        
        action.setCallback(this,function(response){
            
            var state = response.getState();
            console.log(state);
            if (state === "SUCCESS"){
                console.log('response.getReturnValue() '+JSON.stringify(response.getReturnValue()));
                component.set("v.suggestedAddress",response.getReturnValue());
            }
            else {
                console.log(response.getError());
               console.log(JSON.stringify(response));
            }
        });
        $A.enqueueAction(action);
    }else {
        var addressList = component.get("v.addressList");
        var sendValidatedAddressList = component.getEvent("validatedAddressList");
        sendValidatedAddressList.setParams({
            "validatedAddressList": addressList
        });
        sendValidatedAddressList.fire();
        var cancelEvent = component.getEvent("cancelModal");
        cancelEvent.fire();
        }
    
},

rejectMelissaAddress: function(component, event, helper) {
    component.set("v.isRejectClicked",true);
    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": $A.get("$Label.c.ACLS_Address_Verification_Status"),
                         "message": $A.get("$Label.c.ACLS_Address_Overridden")  
                    });
                    toastEvent.fire();
    var count=component.get("v.count");
    console.log('count verifyMelissaAddress 102 '+count);
    var addressList=component.get("v.addressList");
    console.log('addressList.length '+addressList.length);
    
    addressList[count].ACLS_Verification_Status__c='Override';
    console.log('addressList[count] '+ JSON.stringify(addressList[count]));
    var sendValidatedAddressList = component.getEvent("validatedAddressList");
        sendValidatedAddressList.setParams({
            "validatedAddressList": addressList
        });
        sendValidatedAddressList.fire();
    if(count <= addressList.length-2){
        
            
        
        count++;
        
        console.log('count verifyMelissaAddress line 113 '+count);
        component.set("v.count",count);
        component.set("v.addressValue",addressList[count]);
        var addressValue=component.get("v.addressValue");
        var action = component.get("c.verifyAddress");
        
        action.setParams({
            "actuala1": addressValue.PC_Address_1__c,
            "actuala2": addressValue.PC_Address_2__c,
            "actualpostal": addressValue.PC_Zip_Code__c,
            "actualstate": addressValue.PC_State__c,
            "actualcity": addressValue.PC_City__c,
            "actualcountry": addressValue.PC_Country__c
            
        });
        
        action.setCallback(this,function(response){
            
            var state = response.getState();
            console.log(state);
            if (state === "SUCCESS"){
                console.log('response.getReturnValue() '+JSON.stringify(response.getReturnValue()));
                component.set("v.suggestedAddress",response.getReturnValue());
            }
            else {
                console.log(response.getError());
               console.log(JSON.stringify(response));
            }
        });
        $A.enqueueAction(action);
    }else {
        var addressList = component.get("v.addressList");
        var sendValidatedAddressList = component.getEvent("validatedAddressList");
        sendValidatedAddressList.setParams({
            "validatedAddressList": addressList
        });
        sendValidatedAddressList.fire();
        var cancelEvent = component.getEvent("cancelModal");
        cancelEvent.fire();
        }
},
 // function automatic called by aura:waiting event  
 showSpinner: function(component, event, helper) {
    // make Spinner attribute true for displaying loading spinner 
    component.set("v.spinner", true); 
},
 
// function automatic called by aura:doneWaiting event 
hideSpinner : function(component,event,helper){
    // make Spinner attribute to false for hiding loading spinner    
    component.set("v.spinner", false);
}
})