({
	doInit : function (component, event, helper) {
	    helper.setNamespace(component);
        var pageReference = component.get("v.pageReference");
        var namespace = component.get("v.namespace");
        var Id = CH_PC_Util.getQualifiedQueryParam(component,'Id',namespace);
        var documentId;
        if(pageReference != null && pageReference.state[Id] != 'NULL' && pageReference.state[Id] != 'undefined'){
            documentId = pageReference.state[Id];
        }else{
            var query = location.search.substr(1);
            var result = {};
            query.split("&").forEach(function(part) {
                var item = part.split("=");
                if(!$A.util.isUndefinedOrNull(item[0]) && !$A.util.isUndefinedOrNull(item[1])){
                    result[item[0]] = decodeURIComponent(item[1]);
                }
            });
            documentId = result[Id];
        }
        component.set("v.docId", documentId);

        var docId = component.get("v.docId");
        var searchPatient= {
            engagementProgram:"",
            engagementProgramId:"",
            engagementProgramCode:"",
            manufacturerId:"",
            manuProgramName:"",
            patientId:"",
            fsFields:"",
            masterPatient : "false"
        };

        component.set("v.fieldSetName", '');

        component.set("v.searchPatient", searchPatient);
        helper.docDetailsHelper(component, helper, docId);
    },

    fetchFieldSets : function (component, event, helper){
        component.set("v.showSearchResult",false);
        component.set("v.noMatchFound",false);
        component.set("v.isSelected",false);
        helper.getfsFieldsForEngagementProgram(component, event, helper);
    },
    
    showSpinner : function (component, event, helper) {
		var spinner = component.find('spinner');
        var evt = spinner.get("e.toggle");
        evt.setParams({ isVisible : true });
        evt.fire();  
    },
    
    hideSpinner : function (component, event, helper) {
       var spinner = component.find('spinner');
       var evt = spinner.get("e.toggle");
       evt.setParams({ isVisible : false });
       evt.fire();   
    },
    
    dontModalBox : function(component, event, helper) {
        helper.hidePopupHelper(component, 'modaldialog', 'slds-fade-in-');
		helper.hidePopupHelper(component, 'backdrop', 'slds-backdrop--');        
        event.preventDefault();
	    return false;
    },
    
    closePreEnrollmentWizard : function(component, event, helper) {    	
        setInterval(function(){window.close()},2000);
    },
    
    getSearchResult : function(component, event, helper) {
        var errors ;
        component.set("v.errors", errors);
        var validFieldSet = helper.validateFieldSetForm(component, event, helper);
        if(validFieldSet){
            helper.getSearchResultHelper(component, event, helper);
        }
        event.preventDefault();
        return false;
    },
    
    enrollPatient : function(component, event, helper) {      
        helper.showPopupHelper(component, 'modaldialog', 'slds-fade-in-');
        helper.showPopupHelper(component,'backdrop','slds-backdrop--');
    },
    
    onSelect : function(component, event, helper) {
        component.set("v.newEnrollmentSelected",false);

        var idValue=event.getSource().get("v.text");
        var accountAppMapArray=component.get('v.accountAppWrapperArray');
        for(var i=0;i<accountAppMapArray.length;i++){

            if(accountAppMapArray[i].key==idValue){
                component.set("v.selectedPatient",accountAppMapArray[i].value);
                component.set("v.newApplicant",accountAppMapArray[i].value);

            }
        }
        component.set("v.isSelected",true);
        helper.setSearchFSMapToSend(component, event, helper, idValue);

    },

    navigateTo : function (component, event, helper) {
        var recordId = event.getSource().get("v.value");
        var workspaceAPI = component.find("workspace");
        var device = $A.get("$Browser.formFactor");
        if(device != 'DESKTOP'){
            var navService = component.find("navService");
            // Uses the pageReference definition in the init handler
            var pageReference = {
                "type": "standard__recordPage",
                "attributes": {
                   "recordId": recordId,
                   "actionName": "view"
               }
            };
            event.preventDefault();
            navService.navigate(pageReference);
        }else{
            var isCustomApp = component.get("v.isCustomApp");
            if(isCustomApp){
                var url = '/one/one.app#/sObject/' + recordId + '/view';
                window.open(url,'_blank');
            }else{
                CH_PC_Util.openRecordInBrowserWindow(workspaceAPI, recordId, false);
            }
        }
    },
    
    executeNextStep : function(component, event, helper) {    
        var searchDetails = component.get("v.searchPatient");
    	var newEnrollment = component.get("v.newEnrollmentSelected");
        var selectedPatient = component.get("v.selectedPatient");
        
        //Reset the search actions 
        component.set("v.isNewApplicant", false);
        component.set("v.isExistingAccount", false);
        component.set("v.isEnrollingInOtherProgram", false);
        component.set("v.reqCaseId", "");
        
        if (newEnrollment) {
            //If New Enrollment is selected by User then launch new enrollment by passing the user entered details
            component.set("v.isNewApplicant", true);
        } else {
            //Check If selected record is an Applicant and doesnot matches the user entered engagement Program 
            //and enrollment Case status is not completed then display user popup message for patient enrolling in other programs
            if (selectedPatient.accountType == "Applicant" && selectedPatient.enrollmentCaseStatus != "Completed" && selectedPatient.engagementProgram != searchDetails.engagementProgramId){

                component.set("v.isEnrollingInOtherProgram", true);
            } else {
                //For all other Patient accounts or applicant records getExistingCaseId from server
                var action = component.get("c.getExistingCase");
                action.setParams({
                    "patientId": selectedPatient.patientId,
                    "programId": searchDetails.engagementProgramId,
                    "accountType": selectedPatient.accountType
                });
                action.setCallback(this, function(response) {
                    var state = response.getState();
                    if (component.isValid() && state === "SUCCESS") {
                        var returnValue = response.getReturnValue();
                        if (!$A.util.isUndefinedOrNull(returnValue)) {
                            //For Records the caseId is returned --> respective components should be called by passing the reqCaseId
                            component.set("v.reqCaseId",returnValue);
                            component.set("v.isExistingAccount", true);
                        } else {
                            //if No case id is returned then selected Patient has no existing cases for engagement program 
                            //and a new enrollment should be launched by passing the user entered patient information

                            //Hitha:As we are going to pass the fsfieldsmap to the new enrollment component we can commet FN, LN and DOB
                            component.set("v.newApplicant.patientId", selectedPatient.patientId);
                            component.set("v.newApplicant.engagementProgramId", searchDetails.engagementProgramId);
                            component.set("v.newApplicant.manuProgramName", searchDetails.manuProgramName);
                            component.set("v.newApplicant.engagementProgramCode", searchDetails.engagementProgramCode);
                            component.set("v.isNewApplicant", true);
                        }
                    } else {
                        console.log("Failed with state: " + state);
                    }
                });
                $A.enqueueAction(action);
            }
        }
    },
    
    newEnrollment : function(component, event, helper) {
        var selectedAppAccRadioButtonList=component.find("selectRadioId");
        if(!$A.util.isUndefinedOrNull(selectedAppAccRadioButtonList)){
            if(Array.isArray(selectedAppAccRadioButtonList)){
                for(var i=0;i<selectedAppAccRadioButtonList.length;i++){
                    selectedAppAccRadioButtonList[i].set("v.value",false);
                }
            }else{
                selectedAppAccRadioButtonList.set("v.value",false);
            }

        }
        var searchDetails = component.get("v.searchPatient");
        component.set("v.newApplicant",searchDetails);
        component.set("v.newApplicantFSfield",searchDetails.fsFields);
        component.set("v.isSelected",true);
        component.set("v.newEnrollmentSelected",true);
    },
    
    showPatientDetail : function (component, event, helper) {
        var index = event.target.dataset.index;
        var lstPatient = component.get("v.lstPatient");
        var accId = lstPatient[index].patientId;
        window.open('/one/one.app#/sObject/' + accId + '/view', '_blank', "toolbar=no,scrollbars=yes,resizable=yes,top=100,width=800,height=800");
    }
})