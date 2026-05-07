({
    setNamespace : function(component) {
        var ns = CH_PC_Util.getNamespace(component);
        var nsPrefix = CH_PC_Util.getNamespacePrefix(component);
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", nsPrefix);
    },
    setConfiguration : function(component) {
        var configString = component.get("v.config");
        var nsPrefix = component.get("v.namespacePrefix");
        var fieldSetNames = [];
        fieldSetNames.push(nsPrefix + 'PC_Patient_Information');
        fieldSetNames.push(nsPrefix + 'PC_Communication_Preference');
        fieldSetNames.push(nsPrefix + 'PC_Caregiver_Information');
        if (configString != null) {
            var config = JSON.parse(configString);
            if(config["fieldSetNames"]!=null){
                 fieldSetNames = config["fieldSetNames"];
            }
        }
        if (!$A.util.isUndefinedOrNull(fieldSetNames)) {
            component.set("v.fieldSetNames", fieldSetNames);
        }
    },
    getAccountOrApplicant : function(component, event, helper){
        component.set("v.showSpinner",true);
        component.set("v.isFieldValuesLoaded",false);
        var action = component.get("c.getAccountOrApplicant");
        var enrollDetails = new Map();
        enrollDetails['patientId'] = component.get("v.enrollmentCase.accountId");
        enrollDetails['enrollmentId'] = component.get("v.enrollmentCase.enrollmentId");
        enrollDetails['activeApplicantId'] = component.get("v.enrollmentCase.applicantId");
        enrollDetails['fieldSetNames'] = component.get("v.fieldSetNames").toString();

        action.setParams({
            "enrollDetails"		: enrollDetails
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {

                var existingAccount = response.getReturnValue();
                component.set("v.lastModifiedDate",existingAccount.LastModifiedDate);
                /*
                 * Getting the account or applicant info
                 */
                var persistentAccount = component.get("v.persistentAccount");
                //For an online enrollment form, if an account exists, display warning message
                if(component.get("v.enrollmentCase.isOnlineApplicant") && !$A.util.isUndefinedOrNull(component.get("v.enrollmentCase.accountId"))){
                    var warnings = component.get("v.pageWarnings");
                    warnings.push(helper.getOnlineFormWarning(component));
                    component.set("v.pageWarnings",warnings);
                }

                if(persistentAccount === null) {
                    component.set("v.persistentAccount",existingAccount);//When no saved account info is available
                } else { //Account modified warning shown only if accounts are updated, not if applicants are updated
                    if(existingAccount.Id != null && existingAccount.Id != undefined &&
                       existingAccount.LastModifiedDate != persistentAccount.LastModifiedDate){
                        component.set("v.persistentAccount",existingAccount);
                        var accountPageWarnings = component.get("v.pageWarnings");
                        accountPageWarnings.push(helper.getAccountPageError(component));
                        component.set("v.pageWarnings",accountPageWarnings);
                    }
                }
                component.set("v.isFieldValuesLoaded",true);
            }else if (state ==="ERROR"){
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
            component.set("v.showSpinner",false);
        });
        $A.enqueueAction(action);
    },

    getAccountPageError : function(component) {
        var pageError = component.get("v._pageError");
        var pageErrorReplacements = component.get("v._accountPageErrorReplacements");
        for(var replacement in pageErrorReplacements) {
            if(pageErrorReplacements.hasOwnProperty(replacement)) {
                pageError = pageError.replace(replacement,pageErrorReplacements[replacement]);
            }
        }
        return pageError;
    },
    getOnlineFormWarning : function(component) {
        var pageWarning = component.get("v._onlineFormWarning");
        return pageWarning;
    },
})