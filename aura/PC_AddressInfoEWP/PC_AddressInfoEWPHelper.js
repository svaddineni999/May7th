/**
 * Created by kkanteti on 11/15/2021.
 */
({
    setNamespace : function(component){
        var ns = CH_PC_Util.getNamespace(component);
        var nsPrefix = CH_PC_Util.getNamespacePrefix(component);
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", nsPrefix);
    },
    setConfiguration : function(component){
        var configString = component.get("v.config");
        var nsPrefix = component.get("v.namespacePrefix");
        var fieldSetNames = [];
        fieldSetNames.push(nsPrefix + 'PC_AddressInformation');
        var displayFieldSetName = nsPrefix + 'PC_AddressInformation';
        if (configString != null) {
            var config = JSON.parse(configString);
            if(config["fieldSetNames"]!=null){
                 fieldSetNames = config["fieldSetNames"];
            }
            if(config["displayFieldSetName"]!=null){
                 displayFieldSetName = config["displayFieldSetName"];
            }
        }
        if (!$A.util.isUndefinedOrNull(fieldSetNames)){
            component.set("v.fieldSetNames", fieldSetNames);
        }
        if (!$A.util.isUndefinedOrNull(displayFieldSetName)){
            component.set("v.displayFieldSetName", displayFieldSetName);
        }
    },
    getExistingAddresses : function(component,event,helper){
        var action = component.get("c.getAddressFieldsAndRecords");
        var enrollDetails = new Map();
        enrollDetails['patientId'] = component.get("v.enrollmentCase.accountId");
        enrollDetails['activeApplicantId'] = component.get("v.enrollmentCase.applicantId");
        enrollDetails['displayFieldSetName'] = component.get("v.displayFieldSetName");
        action.setParams({
            "enrollDetails"		: enrollDetails,
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(component.isValid() && state === "SUCCESS"){
                var response = response.getReturnValue();
                component.set("v.objectName",response.objectName);
                helper.setAddressColumnsWithActions(component,event,helper,response.addressFields);
                var patientId = component.get("v.enrollmentCase.accountId");
                /*
                * Getting the list of addresses related to account or applicant
                * To do - Handle the scenario where the user wants to remove the all address (from online form as well as account)??
                */
                //Adding segregation logic for online versus 'Existing or System stored address

                if ($A.util.isEmpty(patientId) && !$A.util.isEmpty(response.patientAddresses) &&
                        response.patientAddresses.length > 0){
                    component.set("v.onlineFormAddresses", response.patientAddresses);
                    component.set("v.source", response.patientAddresses[0].Source);
                }

                var persistentAddress	= component.get("v.persistentAddress");
                var isAddressModified = false;

                if(persistentAddress != null && persistentAddress.length === 0){
                    if (response.patientAddresses.length > 0) {
                        if(!$A.util.isEmpty(patientId)){
                            component.set("v.persistentAddress",response.patientAddresses);
                        }
                    }
                }else{
                    if(response.patientAddresses.length > 0 && persistentAddress.length > 0){
                        for(var i = 0 ; i < persistentAddress.length ; i++){
                            for(var j = 0; j < response.patientAddresses.length; j++){
                                if(!$A.util.isUndefinedOrNull(persistentAddress[i].LastModifiedDate)){
                                    if(persistentAddress[i].Name === response.patientAddresses[j].Name && persistentAddress[i].LastModifiedDate != response.patientAddresses[j].LastModifiedDate){
                                        persistentAddress[i] = response.patientAddresses[j];
                                        isAddressModified = true;
                                    }
                                }
                            }
                        }
                        component.set("v.persistentAddress", persistentAddress);

                        //If even one of applicant's address was modified, show warning message exactly once [PC-1499]
                        if(isAddressModified) {
                            var pageWarnings = component.get("v.pageWarnings");
                            pageWarnings.push(helper.getAddressPageError(component));
                            component.set("v.pageWarnings", pageWarnings);
                        }
                    }
                }
            }else if(state == "ERROR"){
                var errors = response.getError();
                console.log(JSON.stringify(errors));
                var pageErrors = [];
                pageErrors.push(errors[0].message);
                component.set("v.pageErrors",pageErrors);
                component.set("v.isValid",false);
            }else{
                var unknownErrors = [{
                    message : 'Unknown Error'
                }]
                CH_PC_Util.showAllErrors(component.get("v.errorStatus"),unknownErrors);
            }
        });
        $A.enqueueAction(action);
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
    setAddressColumnsWithActions : function(component,event,helper,addressColumns){
        var selectedAddressColumns = JSON.parse(JSON.stringify(addressColumns));
        var addressColumnActions = [{
            'label': 'Add Address',
            'iconName': 'utility:add',
            'name': 'add_address'
        }];
        var selectedAddressColumnActions = [
            {
                'label': 'Remove Address',
                'iconName': 'utility:close',
                'name': 'remove_address'
            },
            {
                'label': 'Edit Address',
                'iconName': 'utility:edit',
                'name': 'edit_address'
            }
        ];
        addressColumns.unshift({type: 'action', typeAttributes: {rowActions: addressColumnActions}, label:'Actions'});
        selectedAddressColumns.unshift({type: 'action', typeAttributes: {rowActions: selectedAddressColumnActions}, label:'Actions'});

        component.set("v.addressColumns",addressColumns);
        component.set("v.selectedAddressColumns",selectedAddressColumns);
    },
    handleAvailableAddressRowAction : function(component,event,helper){
        var action = event.getParam('action');
        var row = event.getParam('row');
        var persistentAddresses = component.get("v.persistentAddress");
        var rowIndex = this.getRowIndex(persistentAddresses,row);
        if(action.name == 'add_address'){
            if(rowIndex == -1){
                component.set("v.newEditAddress",row);
                component.set("v.showAddressModal",true)
            }else{
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": 'info',
                    "message": component.get("v.addressIsSelected")
                });
                toastEvent.fire();
            }
        }
    },
    handleSelectedAddressRowAction: function(component,event,helper){
        var action = event.getParam('action');
        var row = event.getParam('row');
        var persistentAddresses = component.get("v.persistentAddress");
        var rowIndex = this.getRowIndex(persistentAddresses,row);
        if(action.name == 'remove_address'){
            persistentAddresses.splice(rowIndex, 1);
            component.set("v.persistentAddress",persistentAddresses);
        }else if(action.name == 'edit_address'){
            component.set("v.newEditAddress",row);
            component.set("v.showAddressModal",true);
        }
    },
    getRowIndex: function(rows, row) {
        var rowIndex = -1;
        rows.some(function(current, i) {
            if (current.AddressId === row.AddressId){
                rowIndex = i;
                return true;
            }
        });
        return rowIndex;
    },
    addNewAddress : function(component,event,helper){
        component.set("v.newEditAddress","");
        component.set("v.showAddressModal",true);
    },
    validate : function(component,event,helper){
        component.set('v.isValid', false);
        var isValid = false;
        var persistentAddresses = component.get("v.persistentAddress");
        var primaryAddressField = component.get("v.namespacePrefix") + 'PC_Primary_Address__c';
        var primaryAddressCount = 0;
        if(!$A.util.isUndefinedOrNull(persistentAddresses) && persistentAddresses.length > 0){
            for(var i = 0; i < persistentAddresses.length; i++){
                if(persistentAddresses[i].hasOwnProperty(primaryAddressField)){
                    if(persistentAddresses[i][primaryAddressField]){
                        primaryAddressCount++ ;
                    }
                }
            }
            var pageErrors = [];
            if(primaryAddressCount > 1){
                pageErrors.push(component.get("v.primaryAddressMorePageErrorMessage"));
                component.set("v.pageErrors",pageErrors);
            }else if(primaryAddressCount == 0){
                pageErrors.push(component.get("v.primaryAddressLessPageErrorMessage"));
                component.set("v.pageErrors",pageErrors);
            }else{
                isValid = true;
                component.set("v.isValid",true);
            }
        }else{
             isValid = true;
             component.set("v.isValid",true);
        }
        return isValid;
    }
})