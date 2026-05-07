({
    getPicklistEntryMap : function(component){
        component.set("v.showSpinner",true);
        var action = component.get("c.getPicklistEntryMap");
        action.setCallback(this, function(response) {
            component.set("v.showSpinner",false);
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                component.set("v.picklistEntryMap", returnValue);
            } else {
                console.log("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);
    },

    getFieldLabels : function(component){
        component.set("v.showSpinner",true);
        var action = component.get("c.getFieldLabels");
        action.setCallback(this, function(response) {
            component.set("v.showSpinner",false);
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                component.set("v.myFieldLabels", returnValue);
            } else {
                console.log("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);
    },

    getAccount : function(component, event, helper){
        component.set("v.showSpinner",true);
        var action = component.get("c.getAccountorApplicant");
        var enrollDetails = new Map();
        enrollDetails['patientId'] = component.get("v.enrollmentCase.accountId");
        enrollDetails['enrollmentId'] = component.get("v.enrollmentCase.enrollmentId");
        enrollDetails['activeApplicantId'] = component.get("v.enrollmentCase.applicantId");//[PC-1379] Handles multiple applicants on enrollment case
        enrollDetails['fieldSetName'] = component.get("v.fieldSetName");
        enrollDetails['replaceTarget'] = component.get("v.replaceTarget");
        enrollDetails['replaceText'] = component.get("v.replaceText");

        action.setParams({
            "enrollDetails"		: enrollDetails,
            "ignoreFields": component.get("v.ignoreFields")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.showSpinner",false);
                var existingAccount = response.getReturnValue();
                /*
                * Getting the list of addresses related to account or applicant
                * To do - Handle the scenario where the user wants to remove the all address (from online form as well as account)??
                */
                var onlineFormAddress = component.get("v.onlineFormAddress");
                //Adding segregation logic for online versus 'Existing or System stored address

                if (!$A.util.isEmpty(existingAccount) &&
                        !$A.util.isEmpty(existingAccount.addrs) &&
                        existingAccount.addrs.length > 0) {
                    for (var k = 0; k < existingAccount.addrs.length; k++) {
                        var address = existingAccount.addrs[k];

                        if(!$A.util.isEmpty(address.applicantSourceId)) {
                            helper.setAddressLabels(component, address);
                            onlineFormAddress.push(address);
                        }
                    }
                }
                if (onlineFormAddress.length > 0) {
                    component.set("v.onlineFormAddress", onlineFormAddress);
                    component.set("v.showAddressRefTable", true);
                }

                var persistentAddress	= component.get("v.persistentAddress");
                var isAddrModified = false;

                if (persistentAddress != null && persistentAddress.length === 0) {
                    //component.set("v.persistentAddress",existingAccount.addrs); //When no saved address are available
                    if (existingAccount.addrs.length > 0) {
                        console.log("existingAccount.addrs.length : "+existingAccount.addrs.length);
                        for (var l = 0; l < existingAccount.addrs.length; l++) {
                            var existingAccountAddress = existingAccount.addrs[l];

                            if($A.util.isEmpty(existingAccountAddress.applicantSourceId)) {
                                helper.setAddressLabels(component, existingAccountAddress);
                                persistentAddress.push(existingAccountAddress);
                            }
                        }
                    }
                    component.set("v.persistentAddress", persistentAddress);
                } else {
                    if (existingAccount.addrs.length > 0 && persistentAddress.length > 0) {
                        for(var i = 0 ; i < persistentAddress.length ; i++){
                            for(var j = 0; j < existingAccount.addrs.length; j++){
                                if(persistentAddress[i].address === existingAccount.addrs[j].address && persistentAddress[i].lastModifiedDate != existingAccount.addrs[j].lastModifiedDate){
                                    helper.setAddressLabels(component, existingAccount.addrs[j]);
                                    persistentAddress[i] = existingAccount.addrs[j];
                                    isAddrModified = true;
                                }
                            }
                        }

                        component.set("v.persistentAddress", persistentAddress);

                        //If even one of applicant's address was modified, show warning message exactly once [PC-1499]
                        if( isAddrModified) {
                            var pageWarnings = component.get("v.pageWarnings");
                            pageWarnings.push(helper.getAddressPageError(component));
                            component.set("v.pageWarnings", pageWarnings);
                        }
                    }
                }
                /*
                 * Getting the account or applicant info
                 */
                var persistentAccount = component.get("v.persistentAccount");
                //[PC-1287] For an online enrollment form, if an account exists, display warning message
                if(component.get("v.enrollmentCase.isOnlineApplicant") && existingAccount.Id != null && existingAccount.Id != undefined){
                    var warnings = component.get("v.pageWarnings");
                    warnings.push(helper.getOnlineFormWarning(component));
                    component.set("v.pageWarnings",warnings);
                }

                if(persistentAccount === null) {
                    component.set("v.persistentAccount",existingAccount);//When no saved account info is available
                    //component.set("v.persistentAddress",existingAccount.addrs);
                } else { //[PC-1440] Account modified warning shown only if accounts are updated, not if applicants are updated
                    if(existingAccount.Id != null && existingAccount.Id != undefined &&
                       existingAccount.lastModifiedDate != persistentAccount.lastModifiedDate){
                        component.set("v.persistentAccount",existingAccount);
                        var accountPageWarnings = component.get("v.pageWarnings");
                        accountPageWarnings.push(helper.getAccountPageError(component));
                        component.set("v.pageWarnings",accountPageWarnings);
                    }
                }

                if (onlineFormAddress.length && persistentAddress.length) {
                    helper.updateActionIndicators(component);
                }
            } else {
                console.log("PC_PatientInfoEWPHelper.getAccount failed with state: " + state);
            }
        });
        $A.enqueueAction(action);
    },

    initailizeAddress : function(component, source, flag){
        var initailizeAddress = {
            account 			: "",
            address				: "",
            addressType 		: "",
            address1 			: "",
            state 				: "",
            stateLabel          : "",
            address2 			: "",
            zipCode 			: "",
            address3 			: "",
            country 			: "",
            countryLabel        : "",
            city 				: "",
            status 				: "",
            statusLabel         : "",
            primary				: false,
            lastModifiedDate	: "",
            source				: source,
            flag				: flag,
            dataChk				: false,
            isAddressSelected	: false
        };
        component.set("v.newAddress",initailizeAddress);
        component.set("v.isDependentDisable", true);
    },

    clearErrorMessage : function (component, fieldArray){
        for (var i = 0; i < fieldArray.length; i++){
            var inputCmp = component.find(fieldArray[i]);
            inputCmp.set("v.errors", [{message:""}]);
        }
    },

    clearErrorMessageLightning : function (component, fieldArray){
        for (var i = 0; i < fieldArray.length; i++){
             var inputCmp = component.find(fieldArray[i]);
             //inputCmp.set("v.errors", [{message:""}]);
             inputCmp.setCustomValidity("");
             inputCmp.reportValidity();
        }
    },

    validateAddressFields : function(component, fieldArray) {
        var requiredFieldErrorMessage = component.get("v.requiredFieldErrorMessage");
        for (var i = 0; i < fieldArray.length; i++){
            if(($A.util.isEmpty(component.find(fieldArray[i]).get("v.value")))){
                var inputCmp = component.find(fieldArray[i]);
                inputCmp.set("v.errors", [{message:requiredFieldErrorMessage}]);
                component.set("v.errorCheck",false);
            }
        }
    },

    validatePrimaryAddress : function(component) {
        var address	= component.get("v.persistentAddress");
        var count 	= 0;
        for(var i = 0; i < address.length; i++)
        {
            if(address[i].primary === true)
            {
                count = count + 1;
            }
        }
        component.set("v.countPrimary",count);
    },
    setAddressLabels : function(component, address) {
        var picklistEntryMap = component.get("v.picklistEntryMap");
        var countryPicklist = picklistEntryMap.countries;
        var statusPicklist = picklistEntryMap.addrStatus;
        var countryStateMap = component.get("v.dependentFieldMap");

        if ($A.util.isEmpty(address.country) || address.country == "__none") {
            address.countryLabel = "";
        } else {
            for (var i = 0; i < countryPicklist.length; i++) {
                if (countryPicklist[i].value == address.country) {
                    address.countryLabel = countryPicklist[i].label;
                    break;
                }
            }
        }

        if ($A.util.isEmpty(address.state) || address.state == "__none") {
            address.stateLabel = "";
        } else {
            var statePicklist = countryStateMap[address.country];

        /* The following null and empty check on 'statePicklist' is required,
           since the state field on Applicant object is text whereas the state field on Address object is picklist. */
            if(statePicklist!=null && !$A.util.isEmpty(statePicklist)){
                for (var j = 0; j < statePicklist.length; j++) {
                    if (statePicklist[j].value == address.state) {
                        address.stateLabel = statePicklist[j].label;
                        break;
                    }
                }
            }

            if ($A.util.isEmpty(address.stateLabel)) {
                address.stateLabel = address.state;
            }
        }

        if ($A.util.isEmpty(address.status) || address.status == "__none") {
            address.statusLabel = "";
        } else {
            for (var k = 0; k < statusPicklist.length; k++) {
                if (statusPicklist[k].value == address.status) {
                    address.statusLabel = statusPicklist[k].label;
                }
            }
        }
    },

        setAddressLabelsLwc : function(component, address) {
            var picklistEntryMap = component.get("v.picklistEntryMap");
            // var countryPicklist = picklistEntryMap.countries;
            var statusPicklist = picklistEntryMap.addrStatus;
            // var countryStateMap = component.get("v.dependentFieldMap");

            if ($A.util.isEmpty(address.country) || address.country == "__none") {
                address.countryLabel = "";
            }
            else {
                address.countryLabel = address.country;
            }

            if ($A.util.isEmpty(address.state) || address.state == "__none") {
                address.stateLabel = "";
            } else {
                address.stateLabel = address.state;
            }

            if ($A.util.isEmpty(address.status) || address.status == "__none") {
                address.statusLabel = "";
            } else {
                for (var k = 0; k < statusPicklist.length; k++) {
                    if (statusPicklist[k].value == address.status) {
                        address.statusLabel = statusPicklist[k].label;
                    }
                }
            }
        },


     setConfiguration : function(component) {
         var configString = component.get("v.config");
         if (configString != null) {
             var config = JSON.parse(configString);
             console.log("Config as in custom metadata...");
             console.log(config);
             debugger;
             if(config["AdditionalInfo"]!=null){
                  var fieldSetName = config["AdditionalInfo"]["fieldSet"];
                  var ignoreFields = config["AdditionalInfo"]["ignoreFields"];
                  var replaceTarget = config["AdditionalInfo"]["replaceTarget"];
                  var replaceText = config["AdditionalInfo"]["replaceText"];
             }
             var overrideAddressAutoComplete = config["overrideAddressAutoComplete"];
             if (!$A.util.isUndefinedOrNull(fieldSetName)) {
                 //component.set("v.fieldSetName", component.get("v.namespacePrefix") + fieldSetName);
                 component.set("v.fieldSetName", fieldSetName);
             }
             if (!$A.util.isUndefinedOrNull(ignoreFields)) {
                 var ignoreFields_WithNamespace = [];
                 for(var i=0; i<ignoreFields.length; i++) {
                     //ignoreFields_WithNamespace.push(component.get("v.namespacePrefix") + ignoreFields[i]);
                     ignoreFields_WithNamespace.push(ignoreFields[i]);
                 }
                 component.set("v.ignoreFields", ignoreFields_WithNamespace);
             }
             if (!$A.util.isUndefinedOrNull(replaceTarget)) {
                 component.set("v.replaceTarget", replaceTarget);
             }
             if (!$A.util.isUndefinedOrNull(replaceText)) {
                 component.set("v.replaceText", replaceText);
             }
             if (!$A.util.isUndefinedOrNull(overrideAddressAutoComplete)) {
                 component.set("v.overrideAddressAutoComplete", overrideAddressAutoComplete);
             }
         }
         this.getAddressAutoCompleteSetting(component);

     },

     getAddressAutoCompleteSetting : function(component) {
         var override = component.get("v.overrideAddressAutoComplete");
         if ($A.util.isUndefinedOrNull(override)||(override!='true'&&override!='false')){
             var action = component.get("c.getAddressAutoCompleteSetting");

             action.setCallback(this,
                function(response) {
                   var state = response.getState();
                   if(state=='SUCCESS'){
                     if (response.getReturnValue()==null){
                         component.set('v.addressAutoComplete',null);
                       }
                       else{
                         component.set('v.addressAutoComplete',(response.getReturnValue()==="true")?true:false);
                       }
                   }else{
                       console.log('Error in getting addressAutoComplete');
                   }
                }
               );
             $A.enqueueAction(action);
         }
         else if (override!=null&&override=='true'){
             component.set('v.addressAutoComplete', true);
         }
         else if (override!=null&&override=='false'){
             component.set('v.addressAutoComplete', false);
         }
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

    setFieldSetObject : function(cmp, event, helper) {
        if (cmp.get("v.fieldSetName") != null) {
            cmp.set("v.showSpinner",true);
            var action = cmp.get('c.getFieldSetFields');
            action.setParams({
                fsName: cmp.get('v.fieldSetName'),
                typeName: cmp.get('v.typeName')
            });
            action.setCallback(this,
                               function(response) {
                                   cmp.set("v.showSpinner",false);
                                   console.log('FieldSetForm HealthPlan Helper -  getFields callback start');
                                   var fields = response.getReturnValue();
                                   var renamedFields = {};
                                   var obj = {};
                                   if(fields != null && fields.length > 0){
                                       helper.setDefaultValueForFieldSetFields(cmp, event, helper, fields);
                                       for (var key in fields) {
                                           if (fields.hasOwnProperty(key)) {
                                               obj[fields[key].fieldPath.replace('.','___')] = '';
                                               console.log(key + " -> " + fields[key].fieldPath.replace('.','___'));
                                           }
                                       }
                                   }
                                   else {
                                       console.log('No fields found from fieldset');
                                   }
                                   console.log('FieldSetForm HealthPlan Helper -  ] getFields callback end');
                                   helper.createFieldSetCmp(cmp, event, helper, fields);
                               }
                              );
            $A.enqueueAction(action);
        }
    },

    createFieldSetCmp : function(cmp, event, helper, fields) {
        $A.createComponent(
            cmp.get("v.namespace") + ":PC_FieldSetForm",
            {
                "fsName": cmp.get("v.fieldSetName"),
                "typeName": cmp.get("v.typeName"),
                "record": cmp.getReference("v.persistentAccount.fsFields"),
                "isValid" : cmp.getReference("v.isFieldSetFormValid")
            },
            function(newCmp, status, errorMessage){
                //Add the new button to the body array
                if (status === "SUCCESS") {
                    var body = cmp.get("v.fieldSetFormBody");
                    body.push(newCmp);
                    cmp.set("v.fieldSetFormBody", body);
                    cmp.set("v.fieldSetFields", fields);
                }
                else if (status === "INCOMPLETE") {
                    console.log("No response from server or client is offline.");
                }
                    else if (status === "ERROR") {
                        console.log("Error: " + errorMessage);
                    }
            }
        );
    },
    setDefaultValueForFieldSetFields : function(cmp, event, helper, fsFields) {
        //var fsFields = cmp.get("v.fieldSetFields");
        debugger;
        var persistentAccount = cmp.get("v.persistentAccount");
        var currentAccFsFields = persistentAccount.fsFields;
        if($A.util.isEmpty(fsFields)) {
            // do nothing
        }
        else {
            var HpField = '';
            for(var i=0; i<fsFields.length; i++) {
                HpField = fsFields[i].fieldPath;
                if($A.util.isEmpty(currentAccFsFields[HpField])) {
                   currentAccFsFields[HpField] = '';
                }
            }
            persistentAccount.fsFields = JSON.parse(JSON.stringify(currentAccFsFields));
            cmp.set("v.persistentAccount",persistentAccount);
        }

    },
    validateFieldSetForm :function(component) {
        console.log(component.get("v.fieldSetFormBody"));
        component.set("v.isFieldSetFormValid",true);
        if (component.get("v.fieldSetFormBody") != null && component.get("v.fieldSetFormBody").length > 0) {
            console.log('In here');
            var fieldSetCmp = component.get("v.fieldSetFormBody")[0];
            fieldSetCmp.validate(); // this sets v.isFieldSetFormValid.
        }
        return component.get("v.isFieldSetFormValid");
    },

    getAddressPageError : function(component) {
        var pageError = component.get("v._pageError");
        var pageErrorReplacements = component.get("v._addressPageErrorReplacements");
        for(var replacement in pageErrorReplacements) {
            if(pageErrorReplacements.hasOwnProperty(replacement)) {
                pageError = pageError.replace(replacement,pageErrorReplacements[replacement]);
            }
        }
        console.log(pageError);
        return pageError;
    },

    getAccountPageError : function(component) {
        var pageError = component.get("v._pageError");
        var pageErrorReplacements = component.get("v._accountPageErrorReplacements");
        for(var replacement in pageErrorReplacements) {
            if(pageErrorReplacements.hasOwnProperty(replacement)) {
                pageError = pageError.replace(replacement,pageErrorReplacements[replacement]);
            }
        }
        console.log(pageError);
        return pageError;
    },

    getOnlineFormWarning : function(component) {
        var pageWarning = component.get("v._onlineFormWarning");
        console.log(pageWarning);
        return pageWarning;
    },

    getPicklistDependencies: function(component, event, helper) {
        component.set("v.showSpinner",true);
        var action = component.get("c.getDependentOptionsImpl");
        action.setCallback(this, function(response) {
            component.set("v.showSpinner",false);
            if (response.getState() == "SUCCESS") {
                var storeResponse = response.getReturnValue();
                component.set("v.dependentFieldMap", storeResponse);
            }else {
                console.log("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);
    },

    updateDependentStates: function(component, statePicklistEntries) {
        // create a empty array var for store dependent picklist values for controller field)
        var dependentOptions = [];
        var state = component.get("v.newAddress").state;

            dependentOptions.push({
                class: "optionClass",
                label: component.get("v.noneOptionName"),
                value: ""
            });

        if (statePicklistEntries != undefined && statePicklistEntries.length > 0) {
            for (var i = 0; i < statePicklistEntries.length; i++) {
                dependentOptions.push({
                    class: "optionClass",
                    label: statePicklistEntries[i].label,
                    value: statePicklistEntries[i].value
                });
            }

            // set the dependentFields variable values to State(dependent picklist field) on ui:inputselect
        }

        var conStateDiv = component.find('conState');
        if(conStateDiv!=null && conStateDiv!=undefined){
            component.find('conState').set("v.options", dependentOptions);
            component.find('conState').set("v.value", state);
        }

        // make disable false for ui:inputselect field
        component.set("v.isDependentDisable", false);
    },
    onControllerFieldChangeHelper: function(component, helper, controllerValueKey) {
        // get the map values
        var dependentPicklistMap = component.get("v.dependentFieldMap");
        var pickListValNone=component.get('v.noneOptionValue');

        // check if selected value is not equal to None then call the helper function.
        // if controller field value is none then make dependent field value is none and disable field

        if (controllerValueKey!=undefined && controllerValueKey != pickListValNone) {

            // get dependent values for controller field by using map[key].
            // for i.e "India" is controllerValueKey so in the map give key Name for get map values like
            // map['India'] = its return all dependent picklist values.
            var dependentPicklistEntries = dependentPicklistMap[controllerValueKey];

            helper.updateDependentStates(component, dependentPicklistEntries);
        } else {

            //component.find('conState').set("v.options", defaultVal);
            component.set("v.isDependentDisable", true);
        }
    },

    showModalBox : function (component, event, helper) {
        var source 		= component.get("v.addressSourceManual");
        var flag		= "New";
        var pickListValNone=component.get('v.noneOptionValue');
        helper.initailizeAddress(component, source, flag);
        helper.onControllerFieldChangeHelper(component,helper,pickListValNone);
        component.set("v.button", true);
        component.set("v.addrModalOpen", true);
        if(!component.get('v.addressAutoComplete')){
            helper.clearErrorMessage (component, ['address1','city']);
        }
        var elementsbackGroundSection = component.find('aura_backGroundSectionId').getElement();
        var elementsnewAccountSection = component.find('aura_newAccountSectionId').getElement();
        elementsbackGroundSection.style.display = "block";
        elementsnewAccountSection.style.display = "block";
        if(component.get('v.addressAutoComplete')){
            this.createLwcAddress(component, event, helper);
            }
        event.preventDefault();
    },

    createLwcAddress : function (component, event, helper){
        console.log(component.get("v.newAddress"));
        $A.createComponent(
            'c:pc_AddressAutoComplete_lwc', {onvalidatechange: component.getReference("c.handleValidateChange"), "aura:id": "lwcAddressAutoComplete",
            selectedAddress : component.get("v.newAddress"), "fieldLabels" : component.get("v.myFieldLabels"), requiredFieldErrorMessage : component.get("v.requiredFieldErrorMessage")},
            function(lwcCmp, status, errorMessage) {
                if (status === "SUCCESS") {
                    var targetComp = component.find("lwcBody");
                    var body =[];
                    body.push(lwcCmp);
                    targetComp.set("v.body", body);
                }
                else if (status === "INCOMPLETE") {
                    console.log("No response from server or client is offline.");
                }
                else if (status === "ERROR") {
                    console.error("Error: " + errorMessage);
                }
            }
          );
    },

    updateActionIndicators : function(component) {
        var getAddress 	= component.get("v.onlineFormAddress");
        var setAddress 	= component.get("v.persistentAddress");
        for(var i=0; i<getAddress.length; i++) {
            for(var j=0; j<setAddress.length; j++) {
                if(setAddress[j].applicantSourceId == getAddress[i].applicantSourceId) {
                    getAddress[i].isAddressSelected = true;
                    setAddress[j].isAddressSelected = true;
                    break;
                }
            }
        }
        component.set("v.newAddress", getAddress);
        component.get("v.persistentAddress",setAddress);
    },
    getPickListValNone : function(component, event, helper) {
        component.set("v.showSpinner",true);

        var action = component.get('c.getPickListValueNone');
        action.setCallback(this,function(response) {
             component.set("v.showSpinner",false);
             var state=response.getState();
             if('SUCCESS'==state){
                    var nonePickListVal=response.getReturnValue();
                    component.set('v.noneOptionValue',nonePickListVal);
             }else{
                    console.log("Failed with state: " + state);
             }
        });
        $A.enqueueAction(action);
    }
})