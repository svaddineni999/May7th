/**
 * Created by vkashikar on 1/30/2018.
  *Modification Log
  * Shishir Bansal 		  18-May-2018    [PC-3171]  Bug- fix E-Benefits lookup is resulting in an exception in a specific case
 */
({
    setNamespace : function(component) {
        var component_to_string = component.toString();
        var markupTagLoc = component_to_string.indexOf('markup://');
        var endOfNamespaceLoc = component_to_string.indexOf(':',markupTagLoc+9);
        var ns = component_to_string.substring(markupTagLoc+9,endOfNamespaceLoc);
        var namespacePrefix = (ns == "c" || ns == "C") ?  "" :  ns + "__";
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", namespacePrefix);
    },
    setRecordId : function(component, event, helper) {
        if(!$A.util.isEmpty(component.get("v.relatedToId"))
                      && !$A.util.isEmpty("v.relatedToObject")
                      && component.get("v.relatedToObject").toLowerCase() == 'case')
        {
            component.set("v.recordId", component.get("v.relatedToId"));
        }
    },
    applyCSS: function(component){
        component.set("v.cssStyle", ".forceStyle .viewport .oneHeader.slds-global-header_container {z-index:0} .forceStyle.desktop .viewport{overflow:hidden}");
    },
    revertCssChange: function(component){
        component.set("v.cssStyle", ".forceStyle .viewport .oneHeader.slds-global-header_container {z-index:5} .forceStyle.desktop .viewport{overflow:visible}");
    },
    getselectedPicklist : function(component, event, helper){
        return true;
    },
    validate : function(component, event, helper, elementId){
        
        var element = component.find(elementId);
        var options = element.get("v.options");
        var tempServiceOutPutList = [];
        var multilistSelected = false;

        for(var i=0, iLen=options.length; i<iLen; i++){
            var opt = options[i];
            if (opt.selected){

                multilistSelected = true;
                if(opt.value == 'Select'){
                    return true;
                }
                else{
                    if(elementId == 'select-01'){
                        component.set("v.selectedHealthPlan",opt.value);
                    }
                    if(elementId == 'select-02'){
                        var tempServiceOutput = new Object();
                        tempServiceOutput.caseId = component.get("v.recordId");
                        tempServiceOutput.pharmacyId = opt.value;
                        tempServiceOutput.pharmacyName = opt.text;
                        tempServiceOutput.isExternalPharmacy = opt.isExternalPharmacy;
                        tempServiceOutput.healthPlanId = component.get("v.selectedHealthPlan");
                        tempServiceOutput.isSpinner = true;
                        tempServiceOutput.prescriptionId = component.get("v.selectedPrescription").id;
                        tempServiceOutPutList.push(tempServiceOutput);
                    }
                    else if(elementId == 'select-03'){
                        component.set("v.selectedPrescription",component.get("v.prescriptionMap")[opt.value]);
                    }
                }
            }

        }
        if(elementId == 'select-02'){
            if(multilistSelected){
                component.set("v.serviceOutput",tempServiceOutPutList);
                return false;
            }
            else{
                return true;
            }
        }
        else{
            return false;
        }
    },
    showToast : function(component, event, helper, message, type, title) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type" : type
        });
        toastEvent.fire();
    },
    showToastSuccess : function(component, event, helper, message, type, title) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type" : type,
            "mode" : "dismissible",
            messageTemplate: message,
            messageTemplateData: ['Salesforce', {
                url: '/'+component.get("v.pharmacyCoverage").Id,
                label: component.get("v.pharmacyCoverage").Name
            }
                                 ]
        });
        toastEvent.fire();
    },
    getEBenefitsInfo : function(component, event, helper) {
        var action = component.get("c.getEBenefitsInfo");
        var recordId = component.get("v.recordId");
        action.setParams({
            "caseId" : recordId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {

                var returnValue = response.getReturnValue();
                component.set("v.serviceInput", returnValue);

                var pharmacyCardInfo = returnValue.cardHolder;
                component.set("v.pharmacyCardFetchInfo",pharmacyCardInfo);
                var prescriptions = [];
                for(var key in returnValue.prescriptions){
                    prescriptions.push({id:key,prescription:returnValue.prescriptions[key]});
                }
                
                component.set("v.prescriptions",prescriptions);
                component.set("v.prescriptionMap",returnValue.prescriptions);
                
                helper.setHealthPlanOptions(component, event, helper);
                helper.setDefaultHealthPlan(component, event, helper);
                helper.setPrescriptionOptions(component, event, prescriptions);                
               	helper.setDefaultPrescription(component, event, helper);
                //helper.setPharmacyOptions(component, event, helper);
                helper.loadPharmacyFinder(component, event, helper);
            } 
			else {

                helper.handleErrors(response.getError());
            }
        });
        $A.enqueueAction(action);
    },
    loadPharmacyFinder: function(component, event, helper) {
        var cmpName = component.get("v.pharmacyFinderCmpName");
        if(!cmpName.includes(':')) {
            cmpName = component.get("v.namespace") + ':' + cmpName;
        }
        var componentAttributes = component.get("v.pharmacyFinderCmpAttributes");
        //var componentAttributesObj = JSON.parse(componentAttributes);
        var componentAttributesObj = componentAttributes;

        //if(!$A.util.isEmpty(selectedPrescription)) {
            componentAttributesObj['prescriptionId'] = component.getReference("v.selectedPharmcyIdForfinder");
        //}

        console.log("Component attributes being passed to the action cmp");
        console.log(componentAttributesObj);
        $A.createComponent(
            cmpName,
            componentAttributesObj,
            function(newComponent,status, errorMessage) {
                if (status === "SUCCESS") {
                    component.set("v.pharmacyFinderCmp", newComponent);
                    var pharmacyFinderDiv = component.find("pharmacyFinderDiv");
                    var pharmacyFinderBody = pharmacyFinderDiv.get("v.body");
                    pharmacyFinderBody.push(newComponent);
                    pharmacyFinderDiv.set("v.body",pharmacyFinderBody);
                }
                else {
                    var toastEvent=$A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title":    'Warning',
                            "message":  'Something went wrong, Please contact System Administrator',
                            "type":     'warning'
                        });
                        toastEvent.fire();
                }
            }
        );
    },
    setPharmacyOptions: function(component, event, helper) {

        var pharmacyFinderCmp = component.get("v.pharmacyFinderCmp");
        var selectedOptions = pharmacyFinderCmp.get("v.selectedPharmacies");
        var dependentOptions = [];
        if(selectedOptions != null && selectedOptions.length > 0) {
            for (var i = 0; i < selectedOptions.length; i++) {
                dependentOptions.push({
                    class: "optionClass",
                    label: selectedOptions[i].displayName,
                    value: selectedOptions[i].id,
                    text: selectedOptions[i].displayName,
                    selected : true
                });
            }
        }
        component.find('select-02').set("v.options", dependentOptions);
    },
    setPharmacyOptions_old: function(component, event, helper) {

        var response = component.get("v.serviceInput");
        var dependentOptions = [];
        if(response != null && response.pharmacies != null && response.pharmacies.length > 0) { 
            for (var i = 0; i < response.pharmacies.length; i++) {
                dependentOptions.push({
                    class: "optionClass",
                    label: response.pharmacies[i].displayName,
                    value: response.pharmacies[i].id
                });
            }
            
        }
        component.find('select-02').set("v.options", dependentOptions);
    },
    setHealthPlanOptions: function(component, event, helper) {

        var response = component.get("v.serviceInput");
        var dependentOptions = [];
        dependentOptions.push({
                    class: "optionClass",
                    label: component.get("v.defaultDropDownValue"),
                    value: "Select"
        });
        
        if(response != null && response.healthPlans != null && response.healthPlans.length > 0) {
            for (var i = 0; i < response.healthPlans.length; i++) {
                dependentOptions.push({
                    class: "optionClass",
                    label: response.healthPlans[i].displayName,
                    value: response.healthPlans[i].id
                });
            }
        }
        component.find('select-01').set("v.options", dependentOptions);
    },
    
    
    
    setDefaultHealthPlan : function(component, event, helper) {
        var response = component.get("v.serviceInput");
        if(response != null && response.healthPlans != null && response.healthPlans.length == 1) {
            var firstHealthPlan = response.healthPlans[0];
            component.find("select-01").set("v.value",firstHealthPlan.id);
            helper.updateCardHolderInfo(component, event, helper);            
        }
    },
    
    setPrescriptionOptions: function(component, event, helper) {
		var response = component.get("v.serviceInput");
		var dependentOptions = [];
		dependentOptions.push({
                class: "optionClass",
                label: component.get("v.defaultDropDownValue"),
                value: "Select"
		});
		if(response != null && response.prescriptions != null && Object.keys(response.prescriptions).length > 0) {
			var displayName ='';
			for( var key in response.prescriptions){
       
				displayName = '';

                if(response.prescriptions[key].productName != undefined ){
                    displayName = response.prescriptions[key].productName +':';
                }
                if(response.prescriptions[key].dosage != undefined){
                    displayName +=  response.prescriptions[key].dosage +':';
                }
                displayName += response.prescriptions[key].name;

                
                dependentOptions.push({
                    class: "optionClass",
                    label: displayName,
                    value: key
                });
			}
		} 
        component.find('select-03').set("v.options", dependentOptions);
    },
		
		
    setDefaultPrescription : function(component, event, helper) {

		var prepResponse = component.get("v.prescriptions");
		if(prepResponse!= null && prepResponse.length ==1){
			component.find("select-03").set("v.value",prepResponse[0].id);
			component.set("v.selectedPharmcyIdForfinder",prepResponse[0].id);
			helper.updatePrescriptionInfo(component, event , helper);
		}
	},

	
		submit : function(component, event, helper) {

		    debugger;
        
			component.set("v.selectedOuput",null);
			var healthPlanSelected = true;
			var prescriptionSelected = true;
			var pharmacySelected = true;

			component.set("v.prescriptionRequired",false);
			component.set("v.pharmacyRequired",false);

			var isCardholderAndPhysicianInfoComplete = false;


            //helper.setPharmacyOptions(component, event, helper);

			healthPlanSelected = helper.validate(component,event,helper,"select-01");
			component.set("v.healthPlanRequired",healthPlanSelected);

			if(!healthPlanSelected) {
				prescriptionSelected = helper.validate(component,event,helper,"select-03");
				component.set("v.prescriptionRequired",prescriptionSelected);
			}

			if(!prescriptionSelected) {
				pharmacySelected = helper.validate(component,event,helper,"select-02");
				component.set("v.pharmacyRequired",pharmacySelected);
			}

			if(!pharmacySelected) {
				isCardholderAndPhysicianInfoComplete=helper.checkAllFields(component, event, helper);
			}

			if(!healthPlanSelected && !pharmacySelected && !prescriptionSelected && isCardholderAndPhysicianInfoComplete ){
				component.set("v.isModalMapActiveInner",true);
				component.find("resultsBlock").getElement().scrollIntoView();
				//window.location.hash = 'resultsBlockAnchor';
				var outPutLength = component.get("v.serviceOutput").length;
				var action = [];
				var arrayItem = [];
				for(var i = 0; i < outPutLength; i++){
					action[i] = component.get("c.getPharmacyBenefitInfo");
					arrayItem[i] = component.get("v.serviceOutput")[i];
					console.log('isExternalPharmacy-->'+arrayItem[i]);
					action[i].setParams({
						"caseId" : component.get("v.recordId"),
						"healthPlanId" : arrayItem[i].healthPlanId,
						"pharmacyId" : arrayItem[i].pharmacyId,
						"isExternalPharmacy": arrayItem[i].isExternalPharmacy,
						"prescriptionId" : component.get("v.selectedPrescription").id,
						"daysSupply" : component.get("v.daysSupplyRequested"),
						"requestedQuantity" : component.get("v.quantityRequested"),
						"index" : i,
						"eBenefitsPharmacyJson": JSON.stringify(helper.getSelectedPharmacyObject(component, arrayItem[i].pharmacyId))
					});
					
					action[i].setBackground();
					action[i].setCallback(this, function(response, i) {
                    var state = response.getState();
                    var returnValue = response.getReturnValue();
                    var tempOutput = component.get("v.serviceOutput");

                    if (component.isValid() && state === "SUCCESS") {
                        if(returnValue != null ){
                            var index = returnValue.index;
                            tempOutput[index].isSpinner = false;
                            if(returnValue.isSuccess) {
                                tempOutput[index].eBenefitsServiceResponse = returnValue.eBenefitsServiceResponse;
                                tempOutput[index].isSuccess = true;
                                tempOutput[index].pharmacy = returnValue.pharmacy;
                                //if(returnValue.eBenefitsServiceResponse.priorAuthorization != undefined){
                                //tempOutput[index].isPriorAuthRequired = returnValue.eBenefitsServiceResponse.priorAuthorization.isRequired ;
                                //}
                                /*if(returnValue.eBenefitsServiceResponse.product != undefined){
                                tempOutput[index].drugDbSourceCode = returnValue.eBenefitsServiceResponse.product.drugDbSourceCode;
                                }*/
                            }
                            else {
                                tempOutput[index].isSuccess = false;
                                tempOutput[index].errorMessage = returnValue.errorMessage;
                            }
                            component.set("v.serviceOutput",tempOutput);

                        }
                        else{
                            var lightningErrorMsg = component.get("v.lightningErrorMsg");
                            var toastErrorTitle = component.get("v.toastTitleError");
                            helper.showToast(component, event, helper, lightningErrorMsg ,"error",toastErrorTitle);
                        }
                    }
                    else {
                        var errorMsg = component.get("v.lightningErrorMsg");
                        var errorTitle = component.get("v.toastTitleError");
                        helper.showToast(component, event, helper, errorMsg,"error",errorTitle);
                    }


                    
                });
            }

                for(var j=0; j<outPutLength; j++) {
                    $A.enqueueAction(action[j]);
                }
            }
            else
            {
                component.find("modalContent").getElement().scrollIntoView(); //goto top of the page
                //window.location.hash = 'modalContentAnchor';
            }
    },
    toggleAccordion : function(component, toggleElementAuraId) {
       var toggleElement = component.find(toggleElementAuraId);
       for(var cmp in toggleElement)
       {
            $A.util.toggleClass(toggleElement[cmp], 'slds-show');
            $A.util.toggleClass(toggleElement[cmp], 'slds-hide');
       }
    },
    getSelectedPharmacyObject : function(component, pharmacyId) {
        var selectedPharmaies = component.get("v.selectedPharmacies");
        var selectedItem = selectedPharmaies.find(item => item['id'] == pharmacyId);
        return selectedItem;
    },
    handleErrors : function(errors) {
        // Configure error toast
        console.error('Errors:');
        console.error(errors);
        let toastParams = {
            title: "Error",
            message: "Unknown error", // Default error message
            type: "error"
        };
        // Pass the error message if any
        if (errors && Array.isArray(errors) && errors.length > 0) {
            toastParams.message = errors[0].message;
        }
        // Fire error toast
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams(toastParams);
        toastEvent.fire();
    },
    
    updateCardHolderInfo : function(component, event, helper) {
      
        
        var element = component.find("select-01");
        
        
        var options = element.get("v.options");
        var tempServiceOutPutList = [];
        var multilistSelected = false;
        for(var i=0, iLen=options.length; i<iLen; i++){
            var opt = options[i];
            if (opt.selected){
                
                if(opt.value != 'Select'){
                    
                    component.set("v.selectedHealthPlan",opt.value);
                    component.set("v.isHealthPlanSelected", true);
                    var action = component.get("c.getCardHolderInfo");
                    var selectedHealthPlan = component.get("v.selectedHealthPlan");
                    action.setParams({
                        "healthPlanId" : selectedHealthPlan
                    });
                    action.setCallback(this, function(response) {
                        var state = response.getState();
                        if (component.isValid() && state === "SUCCESS") {
                            var patient = response.getReturnValue();
                            
                            component.set("v.cardHolderFetchInfo",patient);
                            
                        } else {
                            
                            helper.handleErrors(response.getError());
                        }
                    });
                    $A.enqueueAction(action);
                }
                else{
                    component.set("v.cardHolderFetchInfo", null);
                    component.set("v.isHealthPlanSelected", false);
                }
            }
        }
        
        
    },
    
    updatePrescriptionInfo: function(component, event, helper) {
        component.set("v.selectedPrescription",null);
        
        helper.validate(component,event,helper,"select-03");
        
        var element = component.find("select-03");
        
        var options = element.get("v.options");
        for(var i=0, iLen=options.length; i<iLen; i++){

            
            var opt = options[i];
            if (opt.selected){
                component.set("v.daysSupplyRequested",null);
                component.set("v.quantityRequested",null);
                component.set("v.prescriptionPhysician", null);

                if(opt.value == 'Select'){

                    component.set("v.isPhysicianAvailable", false);

                }
                else{

                    helper.getPhysicianForPrescription(component, event, helper);
                    var selectedPres = component.get("v.selectedPrescription");
                    if(selectedPres.daysSupply == null){
                        component.set("v.daysSupplyRequested",null);
                    }
                    else{
                        component.set("v.daysSupplyRequested",selectedPres.daysSupply);
                    }
                    if(selectedPres.requestedQuantity == null){
                        component.set("v.quantityRequested",null);
                    }
                    else{
                        component.set("v.quantityRequested",selectedPres.requestedQuantity);
                    }
                }
            }
        }
    },
    
    
    
    getPhysicianForPrescription : function(component, event, helper) {
        
        
        var element = component.find("select-03");
        
        var options = element.get("v.options");
        var tempServiceOutPutList = [];
        var multilistSelected = false;
        var selectedPrescriptionId;
        component.set("v.isPhysicianAvailable", false);
        for(var i=0, iLen=options.length; i<iLen; i++){
            var opt = options[i];
            if (opt.selected){
                
                if(opt.value != 'Select'){
                    selectedPrescriptionId = component.get("v.selectedPrescription").id;  
                } 
            }
        }
        var action = component.get("c.getPhysicianForPrescription");
        
        action.setParams({
            "prescriptionId" : selectedPrescriptionId
            
            
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                
                
                var physician = response.getReturnValue();
                if(physician.firstName!=undefined){
                    component.set("v.prescriptionPhysician",physician);
                    component.set("v.isPhysicianAvailable", true);
                }
                
                
            } else {
                
                helper.handleErrors(response.getError());
            }
        });
        $A.enqueueAction(action);
        
    },
    
    
    checkAllFields : function(component, event, helper) {
        
        var cardHolderInfo = component.get("v.cardHolderFetchInfo");
        var physicianInfo = component.get("v.prescriptionPhysician");
        var prescriptionInfo = component.get("v.selectedPrescription");
        var patientInfo = component.get("v.pharmacyCardFetchInfo").patient;
        var daysSupplyRequested = component.find("daysSupplyRequested").get("v.value");
        var quantityRequested = component.find("quantityRequested").get("v.value");

        var isCardholderMissingInfo=true;
        var isPhysicianMissingInfo=true;
        var lightningErrorMsg='';
        var toastErrorTitle = component.get("v.toastTitleError");
        if(cardHolderInfo!=null && cardHolderInfo.firstName!=null && cardHolderInfo.firstName!=''
           && cardHolderInfo.lastName!=null && cardHolderInfo.lastName!=''
           && cardHolderInfo.gender!=null && cardHolderInfo.gender!=''
           && cardHolderInfo.birthdate!=null && cardHolderInfo.birthdate!=''
           && cardHolderInfo.address.city!=null && cardHolderInfo.address.city!=''
           && cardHolderInfo.address.state!=null && cardHolderInfo.address.state!=''
           && cardHolderInfo.address.postalCode!=null && cardHolderInfo.address.postalCode!='')
        {
            isCardholderMissingInfo=false;
            
        }
        
        if(physicianInfo!=null && physicianInfo.firstName!=null && physicianInfo.firstName!=''
           && physicianInfo.lastName!=null && physicianInfo.lastName!=''
           &&  physicianInfo.npi!=null && physicianInfo.npi!='')
        {
            isPhysicianMissingInfo=false;
        }
        if(isCardholderMissingInfo){
            lightningErrorMsg = component.get("v.missingCardholderInfo");
            helper.showToast(component, event, helper, lightningErrorMsg,"error",toastErrorTitle);
            return false;
        }
        if(isPhysicianMissingInfo || daysSupplyRequested=='' || quantityRequested==''){
            lightningErrorMsg = component.get("v.missingPrescriptionInfo");
            helper.showToast(component, event, helper, lightningErrorMsg,"error",toastErrorTitle);
            return false;
        }

         if( Number.isNaN(daysSupplyRequested) || Number.isNaN(quantityRequested)){
                    lightningErrorMsg = component.get("v.nonNumericPrescriptionInfo");
                    helper.showToast(component, event, helper, lightningErrorMsg,"error",toastErrorTitle);
                    return false;
          }
         if(!Number.isInteger(parseFloat(daysSupplyRequested))) {
                       // Checking if the number is decimal
               lightningErrorMsg = component.get("v.nonNumericPrescriptionInfo");
               helper.showToast(component, event, helper, lightningErrorMsg,"error",toastErrorTitle);
               return false;
         }
          if( prescriptionInfo==null || prescriptionInfo.ndc==null || Number.isNaN(prescriptionInfo.ndc)){
                              lightningErrorMsg = component.get("v.missingNDC");
                              helper.showToast(component, event, helper, lightningErrorMsg,"error",toastErrorTitle);
                              return false;
          }
          if( prescriptionInfo==null || $A.util.isEmpty(prescriptionInfo.unitOfMeasureCode)){
                                        lightningErrorMsg = component.get("v.missingUnitOfMeasurecode");
                                        helper.showToast(component, event, helper, lightningErrorMsg,"error",toastErrorTitle);
                                        return false;
                    }
          if( patientInfo==null || patientInfo.firstName==null|| patientInfo.lastName==null|| patientInfo.gender==null
                    || patientInfo.birthdate==null || patientInfo.address==null || patientInfo.address.city==null|| patientInfo.address.state==null|| patientInfo.address.postalCode==null){
                              lightningErrorMsg = component.get("v.missingPatientInfo");
                              helper.showToast(component, event, helper, lightningErrorMsg,"error",toastErrorTitle);
                              return false;
         }

         if(Number.isInteger(quantityRequested)) {
             component.set("v.quantityRequested",quantityRequested + '.0');
         }
         return true;       
    },
    handleAddPharmacy : function(component, event, helper) {




        var selPharmacies = event.getParam("selectedPharmacies");

        if(!$A.util.isEmpty(selPharmacies)) {
            var newSelectedPharmacies = helper.getNewSelectedPharmacies(component, selPharmacies);
            var options = component.find('select-02').get("v.options");
            var selectedPharmacies = component.get("v.selectedPharmacies");
            if(newSelectedPharmacies != null && newSelectedPharmacies.length > 0) {
                for (var i = 0; i < newSelectedPharmacies.length; i++) {
                    options.push({
                        class: "optionClass",
                        label: newSelectedPharmacies[i].displayName,
                        value: newSelectedPharmacies[i].id,
                        text: newSelectedPharmacies[i].displayName,
                        selected : true,
                        isExternalPharmacy : newSelectedPharmacies[i].isExternalPharmacy
                    });
                    selectedPharmacies.push(newSelectedPharmacies[i]);
                }
            }

            component.find('select-02').set("v.options", options);

            component.set("v.selectedPharmacies", selectedPharmacies);


        }
    },
    getNewSelectedPharmacies : function(component, selectedPharmacies) {
        var existingPharmacies = component.find('select-02').get("v.options");
        var newSelectedPharmacies = [];
        var exists = false;
        for (var i = 0; i < selectedPharmacies.length; i++) {
            for(var j=0; j < existingPharmacies.length; j++) {
                if(selectedPharmacies[i].id == existingPharmacies[j].value) {
                    exists = true;
                    break;
                }
            }
            if(!exists) {
                newSelectedPharmacies.push(selectedPharmacies[i]);
            }
        }
        return newSelectedPharmacies;
    },

    handleRemovePharmacy : function(component, event, helper){

            var currentNode = event.currentTarget;
            var id = currentNode.getAttribute("data-id");

            //var val = component.get("pharmacyMultiSelect").get("v.value");
            var selectedPharmacies = [];
            var allPharmacies = component.get("v.selectedPharmacies");

            if(!$A.util.isEmpty(id)) {
                for(var j=0; j < allPharmacies.length; j++) {
                    if(allPharmacies[j].id == id) {
                        // do nothing
                    }
                    else
                    {
                          selectedPharmacies.push(allPharmacies[j]);
                    }

                    }
            }
            component.set("v.selectedPharmacies",selectedPharmacies);

            helper.removeUnselectedPharmacy(component,event, id);

    },

    removeUnselectedPharmacy: function( component , event , removeId){

         var existingPharmacies = component.find('select-02').get("v.options");
                var newSelectedPharmacies = [];


                    for(var j=0; j < existingPharmacies.length; j++) {
                        if( removeId  == existingPharmacies[j].value) {
                            // do nothing
                        }
                        else {
                            newSelectedPharmacies.push(existingPharmacies[j]);
                        }
                    }

                    component.find('select-02').set("v.options", newSelectedPharmacies);


                }





})