({

    doInit : function (component, event, helper){
        helper.setNamespace(component);
        helper.setConfiguration(component);

        /*
         * Get All the picklist entries from schema
         */
        helper.getPicklistEntryMap(component);
        helper.getPicklistDependencies(component, event, helper);

        /*
         * Get the current existing Account
         */
        helper.getAccount(component,event, helper);

        /*
         * Get All the FieldList Values from DB
         */
        helper.getFieldLabels(component);
        helper.setFieldSetObject(component, event, helper);
        helper.getPickListValNone(component, event, helper);

    },

    /*
     * Validation Rules
     */
    validate : function(component, event, helper) {
        var valid 					= true;
        var phoneNumber             = /^(\d+-?)+\d+$/; //[PC-1453] Phone number validation to accept numbers and dashes
        var emailCheck				= /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        var email 					= component.get("v.persistentAccount").email;
        var phone					= component.get("v.persistentAccount").phone;
        var dob 					= new Date(component.get("v.persistentAccount").dob);
        var todayDate 				= new Date();
        var account 				= component.get("v.persistentAccount");
        helper.validatePrimaryAddress(component);
        var countPrimary 			= component.get("v.countPrimary");
        var missingRequiredFields 	= false;
        var pageErrors 				= [];

        var requiredFieldErrorMessage			= component.get("v.requiredFieldErrorMessage");
        var phoneFieldErrorMessage				= component.get("v.phoneFieldErrorMessage");
        var emailFieldErrorMessage				= component.get("v.emailFieldErrorMessage");

        var requiredPageErrorMessage			= component.get("v.requiredPageErrorMessage");
        var dobPageErrorMessage					= component.get("v.dobPageErrorMessage");
        var phonePageErrorMessage				= component.get("v.phonePageErrorMessage");
        var emailPageErrorMessage				= component.get("v.emailPageErrorMessage");
        var primaryAddressLessPageErrorMessage	= component.get("v.primaryAddressLessPageErrorMessage");
        var primaryAddressMorePageErrorMessage	= component.get("v.primaryAddressMorePageErrorMessage");

        helper.clearErrorMessage (component, ['firstName','lastName','phone','email']);
        helper.clearErrorMessageLightning(component , ['dob']);

        if ($A.util.isEmpty(account.firstName)) {
            missingRequiredFields 	= true;
            var firstName = component.find("firstName");
            firstName.set("v.errors", [{message:requiredFieldErrorMessage}]);
        }

        if ($A.util.isEmpty(account.lastName)) {
            missingRequiredFields 	= true;
            var lastName = component.find("lastName");
            lastName.set("v.errors", [{message:requiredFieldErrorMessage}]);
        }

        if (missingRequiredFields) {
            pageErrors.push(requiredPageErrorMessage);
            valid = false;
        }

        if (!$A.util.isEmpty(component.get("v.persistentAccount").dob) && dob > todayDate) {
            pageErrors.push(dobPageErrorMessage);
            var dateOfBirth = component.find("dob");
            //inputCmp.set("v.errors", [{message:dobFieldErrorMessage}]);
            dateOfBirth.setCustomValidity(dobPageErrorMessage);
            dateOfBirth.reportValidity();
            valid = false;
        }

        if (!$A.util.isEmpty(phone) && (phone.match(phoneNumber) === null)) {
            pageErrors.push(phonePageErrorMessage);
            var phoneField = component.find("phone");
            phoneField.set("v.errors", [{message:phoneFieldErrorMessage}]);
            valid = false;
        }

        if (!$A.util.isEmpty(email) && email.match(emailCheck) === null) {
            pageErrors.push(emailPageErrorMessage);
            var emailField = component.find("email");
            emailField.set("v.errors", [{message:emailFieldErrorMessage}]);
            valid = false;
        }

        if(component.get("v.persistentAddress").length != 0){
            //Check for Primary Address - core enrollment wizard functionality
            if (countPrimary === 0) {
                pageErrors.push(primaryAddressLessPageErrorMessage);
                valid = false;
            }

            if (countPrimary > 1) {
                pageErrors.push(primaryAddressMorePageErrorMessage);
                valid = false;
            }
        }

        var validFieldSet = helper.validateFieldSetForm(component);
        if(!validFieldSet){
            valid = false;
            pageErrors.push(requiredPageErrorMessage);
        }
        component.set("v.pageErrors", pageErrors);
        component.set("v.isValid", valid);

    },

    showModalBox : function(component, event, helper) {
        helper.showModalBox(component, event, helper);
    },

    dontModalBox : function(component, event, helper) {
        var elementsbackGroundSection = component.find('aura_backGroundSectionId').getElement();
        var elementsnewAccountSection = component.find('aura_newAccountSectionId').getElement();
        elementsbackGroundSection.style.display = "none";
        elementsnewAccountSection.style.display = "none";
        var source 		= "";
        var flag		= "";
        helper.initailizeAddress(component, source, flag);
        event.preventDefault();
        if(component.find("lwcAddressAutoComplete")!=null || typeof component.find("lwcAddressAutoComplete")!='undefined'){
            component.find("lwcAddressAutoComplete").destroy();
        }
        component.set("v.allFieldsValidLwc", false);
        return false;
    },

    addAddress : function(component, event, helper) {
        component.set("v.errorCheck",true);
        helper.clearErrorMessage (component, ['address1','city']);
        helper.validateAddressFields(component, ['address1','city']);
        var getAddress 	= component.get("v.newAddress");
        var setAddress 	= component.get("v.persistentAddress");
        console.log ("getAddress.applicantSourceId : "+getAddress.applicantSourceId);
        var elementsbackGroundSection = component.find('aura_backGroundSectionId').getElement();
        var elementsnewAccountSection = component.find('aura_newAccountSectionId').getElement();
        if (component.get("v.errorCheck")) {
            if(!$A.util.isEmpty(getAddress.applicantSourceId)) {
            	getAddress.isAddressSelected = true;

                var onlineFormAddress = component.get("v.onlineFormAddress");
                for(var i=0; i<onlineFormAddress.length; i++) {
                    if(onlineFormAddress[i].applicantSourceId == getAddress.applicantSourceId) {
                        onlineFormAddress[i].isAddressSelected = true;
                        break;
                    }
                }
                component.set("v.onlineFormAddress", onlineFormAddress);
            }

            helper.setAddressLabels(component, getAddress);

            setAddress.push(getAddress);
            component.set("v.persistentAddress",setAddress);
            helper.initailizeAddress(component, "", "");

            elementsbackGroundSection.style.display = "none";
            elementsnewAccountSection.style.display = "none";
            event.preventDefault();
        } else {
            elementsbackGroundSection.style.display = "block";
            elementsnewAccountSection.style.display = "block";
            event.preventDefault();
        }
    },

    addAddressLwc : function(component, event, helper) {
        component.find('lwcAddressAutoComplete').validateOnAdd();

        if(component.get("v.allFieldsValidLwc")){
            var getAddress 	= component.get("v.newAddress");
            var setAddress 	= component.get("v.persistentAddress");
            console.log ("getAddress.applicantSourceId : "+getAddress.applicantSourceId);

            getAddress.address1 = component.get("v.streetLwc");
            getAddress.city = component.get("v.cityLwc");
            getAddress.state = component.get("v.stateLwc");
            getAddress.country = component.get("v.countryLwc");
            getAddress.zipCode = component.get("v.zipcodeLwc");

            if(!$A.util.isEmpty(getAddress.applicantSourceId)) {
            	getAddress.isAddressSelected = true;

                var onlineFormAddress = component.get("v.onlineFormAddress");
                for(var i=0; i<onlineFormAddress.length; i++) {
                    if(onlineFormAddress[i].applicantSourceId == getAddress.applicantSourceId) {
                        onlineFormAddress[i].isAddressSelected = true;
                        break;
                    }
                }
                component.set("v.onlineFormAddress", onlineFormAddress);
            }

            helper.setAddressLabelsLwc(component, getAddress);

            setAddress.push(getAddress);
            component.set("v.persistentAddress",setAddress);
            helper.initailizeAddress(component, "", "");

            var elementsbackGroundSection = component.find('aura_backGroundSectionId').getElement();
            var elementsnewAccountSection = component.find('aura_newAccountSectionId').getElement();
            elementsbackGroundSection.style.display = "none";
            elementsnewAccountSection.style.display = "none";
            event.preventDefault();
            component.set("v.allFieldsValidLwc", false);
            component.set("v.lwcChanged", false);
            if(component.find("lwcAddressAutoComplete")!=null || component.find("lwcAddressAutoComplete")!='undefined'){
                component.find("lwcAddressAutoComplete").destroy();
            }
    }
    },

    updateAddress : function(component, event, helper) {
        var index 			= component.get("v.newAddressIndex");
        var getAddress 		= component.get("v.newAddress");
        var setAddress 		= component.get("v.persistentAddress");
        component.set("v.errorCheck",true);
        helper.clearErrorMessage (component, ['address1','city']);
        helper.validateAddressFields(component, ['address1','city']);
        var elementsbackGroundSection = component.find('aura_backGroundSectionId').getElement();
        var elementsnewAccountSection = component.find('aura_newAccountSectionId').getElement();
        if(component.get("v.errorCheck")){
            helper.setAddressLabels(component, getAddress);
            setAddress[index] 	= getAddress;
            component.set("v.persistentAddress",setAddress);

            elementsbackGroundSection.style.display = "none";
            elementsnewAccountSection.style.display = "none";
            var source 			= "";
            var flag			= "";
            helper.initailizeAddress(component, source, flag);
            event.preventDefault();
        } else {
            elementsbackGroundSection.style.display = "block";
            elementsnewAccountSection.style.display = "block";
            event.preventDefault();
        }
    },

    updateAddressLwc : function(component, event, helper) {
        if(component.get("v.lwcChanged")){
            component.find('lwcAddressAutoComplete').validateOnAdd();
        }

        if(component.get("v.allFieldsValidLwc")||(!component.get("v.allFieldsValidLwc")&&!component.get("v.lwcChanged"))){
            var index 			= component.get("v.newAddressIndex");
            var getAddress 		= component.get("v.newAddress");
            var setAddress 		= component.get("v.persistentAddress");

            getAddress.address1 = component.get("v.streetLwc");
            getAddress.city = component.get("v.cityLwc");
            getAddress.state = component.get("v.stateLwc");
            getAddress.country = component.get("v.countryLwc");
            getAddress.zipCode = component.get("v.zipcodeLwc");

            helper.setAddressLabelsLwc(component, getAddress);
            setAddress[index] 	= getAddress;
            component.set("v.persistentAddress",setAddress);

            var elementsbackGroundSection = component.find('aura_backGroundSectionId').getElement();
            var elementsnewAccountSection = component.find('aura_newAccountSectionId').getElement();
            elementsbackGroundSection.style.display = "none";
            elementsnewAccountSection.style.display = "none";
            var source 			= "";
            var flag			= "";
            helper.initailizeAddress(component, source, flag);
            event.preventDefault();

            component.set("v.allFieldsValidLwc", false);
            component.set("v.lwcChanged", false);
            if(component.find("lwcAddressAutoComplete")!=null || component.find("lwcAddressAutoComplete")!='undefined'){
                component.find("lwcAddressAutoComplete").destroy();
            }
        }
    },

    editAddress : function(component, event, helper){
        var selectedTargetNode = event.currentTarget;
        var index = selectedTargetNode.dataset.id.substring(3);
        component.set("v.newAddressIndex",index);
        var persistentAddress 	= component.get("v.persistentAddress");

        var newAddress 			= {
            Id					: persistentAddress[index].Id,
            account 			: persistentAddress[index].account,
            address				: persistentAddress[index].address,
            addressType 		: persistentAddress[index].addressType,
            address1 			: persistentAddress[index].address1,
            state 				: persistentAddress[index].state,
            address2 			: persistentAddress[index].address2,
            zipCode 			: persistentAddress[index].zipCode,
            address3 			: persistentAddress[index].address3,
            country 			: persistentAddress[index].country,
            city 				: persistentAddress[index].city,
            status 				: persistentAddress[index].status,
            primary				: persistentAddress[index].primary,
            lastModifiedDate	: persistentAddress[index].lastModifiedDate,
            source				: persistentAddress[index].source,
            flag				: "Edited",
            dataChk				: persistentAddress[index].dataChk,
            isAddressSelected	: false,
            applicantSourceId	: persistentAddress[index].applicantSourceId
        };
        component.set("v.newAddress",newAddress);
        var elementsbackGroundSection = component.find('aura_backGroundSectionId').getElement();
        var elementsnewAccountSection = component.find('aura_newAccountSectionId').getElement();
        elementsbackGroundSection.style.display = "block";
        elementsnewAccountSection.style.display = "block";
        component.set("v.addrModalOpen", true);
        component.set("v.button" , false);
        helper.onControllerFieldChangeHelper(component, helper, newAddress.country);
        component.find('conCountry').set("v.value", newAddress.country);
        component.find('conState').set("v.value", persistentAddress[index].state);
    },

    editAddressLwc : function(component, event, helper){
        var selectedTargetNode = event.currentTarget;
        var index = selectedTargetNode.dataset.id.substring(3);
        component.set("v.newAddressIndex",index);
        var persistentAddress 	= component.get("v.persistentAddress");

        var newAddress 			= {
            Id					: persistentAddress[index].Id,
            account 			: persistentAddress[index].account,
            address				: persistentAddress[index].address,
            addressType 		: persistentAddress[index].addressType,
            address1 			: persistentAddress[index].address1,
            state 				: persistentAddress[index].state,
            address2 			: persistentAddress[index].address2,
            zipCode 			: persistentAddress[index].zipCode,
            address3 			: persistentAddress[index].address3,
            country 			: persistentAddress[index].country,
            city 				: persistentAddress[index].city,
            status 				: persistentAddress[index].status,
            primary				: persistentAddress[index].primary,
            lastModifiedDate	: persistentAddress[index].lastModifiedDate,
            source				: persistentAddress[index].source,
            flag				: "Edited",
            dataChk				: persistentAddress[index].dataChk,
            isAddressSelected	: false,
            applicantSourceId	: persistentAddress[index].applicantSourceId
        };

        component.set("v.streetLwc", persistentAddress[index].address1);
        component.set("v.cityLwc", persistentAddress[index].city);
        component.set("v.stateLwc", persistentAddress[index].state);
        component.set("v.countryLwc", persistentAddress[index].country);
        component.set("v.zipcodeLwc", persistentAddress[index].zipCode);

        component.set("v.newAddress",newAddress);
        helper.createLwcAddress(component, event, helper);

        var elementsbackGroundSection = component.find('aura_backGroundSectionId').getElement();
        var elementsnewAccountSection = component.find('aura_newAccountSectionId').getElement();
        elementsbackGroundSection.style.display = "block";
        elementsnewAccountSection.style.display = "block";
        component.set("v.addrModalOpen", true);
        component.set("v.button" , false);
    },

    removeAddress : function(component, event, helper){
        var selectedTargetNode = event.currentTarget;
        var index = selectedTargetNode.dataset.id.substring(3);

        //var index 				= event.target.getAttribute("data-id").substring(3);
        var persistentAddress 	= component.get("v.persistentAddress");
        var onlineFormAddress 	= component.get("v.onlineFormAddress");
        if(!$A.util.isEmpty(persistentAddress[index].applicantSourceId)) {
            for(var i=0; i<onlineFormAddress.length; i++) {
                if(onlineFormAddress[i].applicantSourceId == persistentAddress[index].applicantSourceId) {
                    onlineFormAddress[i].isAddressSelected = false;
                    break;
                }
            }
        }
        persistentAddress.splice(index,1);
        component.set("v.persistentAddress", persistentAddress);
        component.set("v.onlineFormAddress", onlineFormAddress);

        if (onlineFormAddress.length && persistentAddress.length) {
            helper.updateActionIndicators(component);
        }
    },

    // function call on change tha controller field
    onControllerFieldChange: function(component, event, helper) {
        // get the selected value
        var controllerValueKey = event.getSource().get("v.value");
        helper.onControllerFieldChangeHelper(component, helper, controllerValueKey);

    },

    // Function call on change the Dependent field
    onDependentFieldChange: function(component, event, helper) {
        //alert(event.getSource().get("v.value"));
    },

    addNewAddressViaApplicant : function (component, event, helper) {
        var onlineApplicantAddress = component.get("v.onlineFormAddress");
        var selectedTargetNode = event.currentTarget;
        var index = selectedTargetNode.dataset.text;
        // you may have to add clear message method here
        //The following fields are available only if the auto complete address setting is set to true, hence the check is required
        if(component.get('v.addressAutoComplete')!=null && component.get('v.addressAutoComplete')!=undefined && !$A.util.isEmpty(component.get('v.addressAutoComplete')) && !component.get('v.addressAutoComplete')){
            helper.clearErrorMessage (component, ['address1','city']);
        }
        var newAddress = {
            address 			: onlineApplicantAddress[index].address,
            address1 			: onlineApplicantAddress[index].address1,
            address2 			: onlineApplicantAddress[index].address2,
            state 				: onlineApplicantAddress[index].state,
            address3 			: onlineApplicantAddress[index].address3,
            city 				: onlineApplicantAddress[index].city,
            country 			: onlineApplicantAddress[index].country,
            zipCode 			: onlineApplicantAddress[index].zipCode,
            source 				: onlineApplicantAddress[index].source,
            addressType 		: onlineApplicantAddress[index].addressType,
            dataChk 			: onlineApplicantAddress[index].dataChk,
            flag 				: onlineApplicantAddress[index].flag,
            lastModifiedDate 	: onlineApplicantAddress[index].lastModifiedDate,
            primary 			: onlineApplicantAddress[index].primary,
            applicantSourceId	: onlineApplicantAddress[index].applicantSourceId,
            isAddressSelected 	: true
        };

        component.set("v.isValidated", false);
        component.set("v.newAddress", newAddress);
        component.set("v.button", true);//Sets the modal button to "Add"

        helper.onControllerFieldChangeHelper(component, helper, newAddress.country);
        //The following fields are available only if the auto complete address setting is set to true, hence the check is required.
        if(component.get('v.addressAutoComplete')!=null && component.get('v.addressAutoComplete')!=undefined && !$A.util.isEmpty(component.get('v.addressAutoComplete')) && !component.get('v.addressAutoComplete')){
            component.find('conCountry').set("v.value", newAddress.country);
            component.find('conState').set("v.value", newAddress.state);
        }

        var elementsbackGroundSection = component.find('aura_backGroundSectionId').getElement();
        var elementsnewAccountSection = component.find('aura_newAccountSectionId').getElement();
        elementsbackGroundSection.style.display = "block";
        elementsnewAccountSection.style.display = "block";
        if(component.get('v.addressAutoComplete')!=null && component.get('v.addressAutoComplete')!=undefined && !$A.util.isEmpty(component.get('v.addressAutoComplete')) && component.get('v.addressAutoComplete')){
            helper.createLwcAddress(component, event, helper);
        }
    },

    handleValidateChange: function(component, event, helper) {
        component.set("v.streetLwc", event.getParam('street'));
        component.set("v.cityLwc", event.getParam('city'));
        component.set("v.stateLwc", event.getParam('province'));
        component.set("v.countryLwc", event.getParam('country'));
        component.set("v.zipcodeLwc", event.getParam('postalCode'));
        component.set("v.allFieldsValidLwc", event.getParam('fieldsValueValid'));
        component.set("v.lwcChanged", event.getParam('fieldValueChanged'));


        console.log('street: '+event.getParam('street'));
        console.log('city: '+event.getParam('city'));
        console.log('province: '+event.getParam('province'));
        console.log('country: '+event.getParam('country'));
        console.log('postalCode: '+event.getParam('postalCode'));

    },
})