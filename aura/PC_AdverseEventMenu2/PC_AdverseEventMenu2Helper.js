/**
 * Created by peharitha on 10/26/2018.
 */
({
    setNamespace : function(component) {
        var ns = CH_PC_Util.getNamespace(component);
        var nsPrefix = CH_PC_Util.getNamespacePrefix(component);
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", nsPrefix);
    },
    getBooleanValue: function(value){
        value = (typeof value == 'string') ? value.toLowerCase() : value;
        switch(value){
            case true:
            case "true":
                return true;
            default:
                return false;
        }
    },
    setPageReferenceValues: function(component, event, helper) {
        var namespace = component.get("v.namespace");
        var pageReference = component.get("v.pageReference");
        var caseIdName = CH_PC_Util.getQualifiedQueryParam(component,'caseId',namespace);
        var aeIdName = CH_PC_Util.getQualifiedQueryParam(component,'aeId',namespace);
        var patIdName = CH_PC_Util.getQualifiedQueryParam(component,'patId',namespace);
        var hideAdditionalInfoTabName = CH_PC_Util.getQualifiedQueryParam(component,'hideAdditionalInfoTab',namespace);
        var hideMfrName = CH_PC_Util.getQualifiedQueryParam(component,'hideMfr',namespace);
        var hideNotesName = CH_PC_Util.getQualifiedQueryParam(component,'hideNotes',namespace);
        var additionalInfoTabFieldSetName = CH_PC_Util.getQualifiedQueryParam(component,'additionalInfoTabFieldSet',namespace);
        var usePrescriptionForSuspectProductsName = CH_PC_Util.getQualifiedQueryParam(component,'usePrescriptionForSuspectProducts',namespace);
        var useRxForMIName = CH_PC_Util.getQualifiedQueryParam(component,'useRxForMI',namespace);
        var hideCodingName = CH_PC_Util.getQualifiedQueryParam(component,'hideCoding',namespace);
        var dateFormatName = CH_PC_Util.getQualifiedQueryParam(component,'dateFormat',namespace);
        var dateFormatErrorMessageName = CH_PC_Util.getQualifiedQueryParam(component,'dateFormatErrorMessage',namespace);
        var submissionStatusName = CH_PC_Util.getQualifiedQueryParam(component,'submissionStatus',namespace);
        var versionNumberName = CH_PC_Util.getQualifiedQueryParam(component,'versionNumber',namespace);

        var caseId,aeId,patId,hideNotes,hideAdditionalInfoTab,hideMfr,additionalInfoTabFieldSet,usePrescriptionForSuspectProducts,hideCoding,
        dateFormat, dateFormatErrorMessage, submissionStatus, versionNumber,useRxForMI;  //adverseEventMenuCmpAttributes
        if(pageReference && pageReference.state){
            if(pageReference.state[caseIdName] != 'NULL' && pageReference.state[caseIdName] != 'undefined'){
                caseId = pageReference.state[caseIdName];
            }
            if(pageReference.state[aeIdName] != 'NULL' && pageReference.state[aeIdName] != 'undefined'){
                aeId = pageReference.state[aeIdName];
            }
            if(pageReference.state[patIdName] != 'NULL' && pageReference.state[patIdName] != 'undefined'){
                patId = pageReference.state[patIdName];
            }
            if(pageReference.state[hideAdditionalInfoTabName] != 'NULL' && pageReference.state[hideAdditionalInfoTabName] != 'undefined'){
                hideAdditionalInfoTab = pageReference.state[hideAdditionalInfoTabName];
            }
            if(pageReference.state[hideMfrName] != 'NULL' && pageReference.state[hideMfrName] != 'undefined'){
                hideMfr = pageReference.state[hideMfrName];
            }
            if(pageReference.state[hideNotesName] != 'NULL' && pageReference.state[hideNotesName] != 'undefined'){
                hideNotes = pageReference.state[hideNotesName];
            }
            if(pageReference.state[useRxForMIName] != 'NULL' && pageReference.state[useRxForMIName] != 'undefined'){
                useRxForMI = pageReference.state[useRxForMIName];
            }
            if(pageReference.state[hideCodingName] != 'NULL' && pageReference.state[hideCodingName] != 'undefined'){
                hideCoding = pageReference.state[hideCodingName];
            }
            if(pageReference.state[additionalInfoTabFieldSetName] != 'NULL' && pageReference.state[additionalInfoTabFieldSetName] != 'undefined'){
                additionalInfoTabFieldSet = pageReference.state[additionalInfoTabFieldSetName];
            }
            if(pageReference.state[usePrescriptionForSuspectProductsName] != 'NULL' && pageReference.state[usePrescriptionForSuspectProductsName] != 'undefined'){
                usePrescriptionForSuspectProducts = pageReference.state[usePrescriptionForSuspectProductsName];
            }
            if(pageReference.state[dateFormatName] != 'NULL' && pageReference.state[dateFormatName] != 'undefined'){
                dateFormat = pageReference.state[dateFormatName];
            }
            if(pageReference.state[dateFormatErrorMessageName] != 'NULL' && pageReference.state[dateFormatErrorMessageName] != 'undefined'){
                dateFormatErrorMessage = pageReference.state[dateFormatErrorMessageName];
            }
            if(pageReference.state[submissionStatusName] != 'NULL' && pageReference.state[submissionStatusName] != 'undefined'){
                submissionStatus = pageReference.state[submissionStatusName];
            }
            if(pageReference.state[versionNumberName] != 'NULL' && pageReference.state[versionNumberName] != 'undefined'){
                versionNumber = pageReference.state[versionNumberName];
            }
        }
        else{
            var query = location.search.substr(1);
            var result = {};
            query.split("&").forEach(function(part) {
                var item = part.split("=");
                if(!$A.util.isUndefinedOrNull(item[0]) && !$A.util.isUndefinedOrNull(item[1])){
                    result[item[0]] = decodeURIComponent(item[1]);
                }
            });
            caseId = ($A.util.isUndefinedOrNull(caseId))?result[caseIdName]:caseId;
            aeId = ($A.util.isUndefinedOrNull(aeId))?result[aeIdName]:aeId;
            patId = ($A.util.isUndefinedOrNull(patId))?result[patIdName]:patId;
            hideAdditionalInfoTab = ($A.util.isUndefinedOrNull(hideAdditionalInfoTab))?result[hideAdditionalInfoTabName]:hideAdditionalInfoTab;
            hideMfr = ($A.util.isUndefinedOrNull(hideMfr))?result[hideMfrName]:hideMfr;
            hideNotes = ($A.util.isUndefinedOrNull(hideNotes))?result[hideNotesName]:hideNotes;
            additionalInfoTabFieldSet = ($A.util.isUndefinedOrNull(additionalInfoTabFieldSet))?result[additionalInfoTabFieldSetName]:additionalInfoTabFieldSet;
            usePrescriptionForSuspectProducts = ($A.util.isUndefinedOrNull(usePrescriptionForSuspectProducts))?result[usePrescriptionForSuspectProductsName]:usePrescriptionForSuspectProducts;
            useRxForMI = ($A.util.isUndefinedOrNull(useRxForMI))?result[useRxForMIName]:useRxForMI;
            hideCoding = ($A.util.isUndefinedOrNull(hideCoding))?result[hideCodingName]:hideCoding;
            dateFormat = ($A.util.isUndefinedOrNull(dateFormat))?result[dateFormatName]:dateFormat;
            dateFormatErrorMessage = ($A.util.isUndefinedOrNull(dateFormatErrorMessage))?result[dateFormatErrorMessageName]:dateFormatErrorMessage;
            submissionStatus = ($A.util.isUndefinedOrNull(submissionStatus))?result[submissionStatusName]:submissionStatus;
            versionNumber = ($A.util.isUndefinedOrNull(versionNumber))?result[versionNumberName]:versionNumber;
        }
        component.set("v.caseId", (caseId != undefined)? caseId :component.get("v.caseId"));
        component.set("v.aeId", (aeId != undefined)? aeId :component.get("v.aeId"));
        component.set("v.patId", (patId != undefined)? patId :component.get("v.patId"));
        var eventMenuCmpAttributes = {
            "hideAdditionalInfoTab" : hideAdditionalInfoTab != undefined ? this.getBooleanValue(hideAdditionalInfoTab) : false,
            "hideMfr" : hideMfr != undefined ? this.getBooleanValue(hideMfr) : false,
            "hideNotes" : hideNotes != undefined ? this.getBooleanValue(hideNotes) : false,
            "additionalInfoTabFieldSet" : additionalInfoTabFieldSet != undefined ? additionalInfoTabFieldSet : '',
            "usePrescriptionForSuspectProducts" : usePrescriptionForSuspectProducts != undefined ? this.getBooleanValue(usePrescriptionForSuspectProducts) : false,
            "useRxForMI" : useRxForMI != undefined ? this.getBooleanValue(useRxForMI) : false,
            "hideCoding" : hideCoding != undefined ? this.getBooleanValue(hideCoding) : false,
            "dateFormat" : dateFormat != undefined ? dateFormat : component.get("v.dateFormat"),
            "dateFormatErrorMessage" : dateFormatErrorMessage != undefined ? dateFormatErrorMessage : component.get("v.dateFormatErrorMessage")
        };
        component.set("v.adverseEventMenuCmpAttributes", eventMenuCmpAttributes);
        component.set("v.dateFormat", (dateFormat != undefined)? dateFormat :component.get("v.dateFormat"));
        component.set("v.dateFormatErrorMessage", (dateFormatErrorMessage != undefined)? dateFormatErrorMessage :component.get("v.dateFormatErrorMessage"));
        component.set("v.submissionStatus", (submissionStatus != undefined)? submissionStatus :component.get("v.submissionStatus"));
        component.set("v.versionNumber", (versionNumber != undefined)? versionNumber : component.get("v.versionNumber"));
        if(patId != undefined || (aeId != undefined && aeId != 'NULL') || caseId != undefined){
            var patientInfoCmp = component.find('patientInfoComp');
            if(patientInfoCmp != undefined){
                patientInfoCmp.initializeComponent();
            }
        }
        if(!$A.util.isEmpty(versionNumber)){
            var aeHeader = component.get("v.adverseEventHeader");
            aeHeader = aeHeader + ' ' + versionNumber;
            component.set("v.adverseEventHeader",aeHeader);
        }
        if(aeId != null && aeId != undefined && aeId != 'NULL'){
            component.set("v.editMode",true);
        }
    },
    onEventTypeChange : function(component,event,helper){
        if(component.get("v.editMode")){
            var eventTypeInEdit = component.get("v.eventTypeInEdit");
            if(eventTypeInEdit == 'Medical Inquiry'){
                component.set("v.showRelatedInfoOfMedicalInquiry",true);
                component.set("v.showAdverseEventProductComplaintTabs",false);
            }else{
                component.set("v.showRelatedInfoOfMedicalInquiry",false);
                component.set("v.showAdverseEventProductComplaintTabs",true);
            }
        }else{
            var eventTypesInNew = component.get("v.eventTypesInNew");
            if(eventTypesInNew.includes('Adverse Event') || eventTypesInNew.includes('Product Complaint')){
                component.set("v.showAdverseEventProductComplaintTabs",true);
            }else{
                component.set("v.showAdverseEventProductComplaintTabs",false);
            }
            if(eventTypesInNew.includes('Medical Inquiry')){
                component.set("v.showRelatedInfoOfMedicalInquiry",true);
            }else{
                component.set("v.showRelatedInfoOfMedicalInquiry",false);
            }
        }
    },
    getSelectedEventTypes : function(component, event, helper) {
        var eventTypes = [];
        if(component.get("v.editMode")) {
            eventTypes.push(component.get("v.eventTypeInEdit"));
            return eventTypes;
        }
        else {
            return component.get("v.eventTypesInNew");
        }
    },
    setNavigation : function(component, event, helper) {
        // We don't need to validate while we hide and show the tabs. The validation will happen when the user
        // clicks on save, prev, & next.
        component.set("v.disableNextButton",false);
        component.set("v.disablePreviousButton",false);
        var currentTab = component.get("v.selTabId");
        var hideAdditionalInfoTab = component.get("v.adverseEventMenuCmpAttributes.hideAdditionalInfoTab");
        var hideMfr = component.get("v.adverseEventMenuCmpAttributes.hideMfr");
        var selectedEventTypes = helper.getSelectedEventTypes(component, event, helper);
        if((currentTab == 'Adverse_Event' || currentTab == 'Suspect_Products' || currentTab == 'Manufacturer')
                && ( !selectedEventTypes.includes('Adverse Event') && !selectedEventTypes.includes('Product Complaint'))){
            if(selectedEventTypes.includes('Medical Inquiry')) {
                component.set("v.selTabId",'Medical_Inquiry');
                component.set("v.previousTabId",'Initial_Repoter');
                if(hideAdditionalInfoTab){
                    component.set("v.disableNextButton",true);
                }
            }
            else if(!hideAdditionalInfoTab){
                component.set("v.selTabId",'Additional_Info');
                component.set("v.previousTabId",'Initial_Repoter');
                component.set("v.disableNextButton",true);
            }else{
                component.set("v.selTabId",'Initial_Repoter');
                component.set("v.previousTabId",'Patient_Information');
                component.set("v.disableNextButton",true);
            }
        }
        else if(currentTab == 'Medical_Inquiry' && !selectedEventTypes.includes('Medical Inquiry')){
            if(selectedEventTypes.includes('Adverse Event') || selectedEventTypes.includes('Product Complaint')){
                component.set("v.selTabId",'Adverse_Event');
                component.set("v.previousTabId",'Initial_Repoter');
            }
            else{
                component.set("v.selTabId",'Patient_Information');
                component.set("v.previousTabId",'Patient_Information');
                component.set("v.disablePreviousButton",true);
            }
        }
        var currentTabAfterChange = component.get("v.selTabId");
        if(currentTabAfterChange == 'Patient_Information'){
            component.set("v.disablePreviousButton",true);
        }
        if(currentTabAfterChange == 'Additional_Info' || (currentTabAfterChange == 'Medical_Inquiry' && hideAdditionalInfoTab) ||
            (currentTabAfterChange == 'Manufacturer' && hideAdditionalInfoTab && !component.get("v.showRelatedInfoOfMedicalInquiry")) ||
            (currentTabAfterChange == 'Initial_Repoter' && hideAdditionalInfoTab && !component.get("v.showRelatedInfoOfMedicalInquiry") && !component.get("v.showAdverseEventProductComplaintTabs")) ||
            (hideMfr && currentTabAfterChange == 'Suspect_Products' && hideAdditionalInfoTab && !component.get("v.showRelatedInfoOfMedicalInquiry"))){
            component.set("v.disableNextButton",true);
        }
    },
    back : function(component,event,helper){
        var currentTab = component.get("v.selTabId");
        component.set("v.disableNextButton",false);
        if(currentTab == 'Initial_Repoter'){
            component.set("v.disablePreviousButton",true);
            component.set("v.selTabId",'Patient_Information');
            component.set("v.previousTabId",'Initial_Repoter');
        }else if(currentTab == 'Adverse_Event'){
            component.set("v.selTabId",'Initial_Repoter');
            component.set("v.previousTabId",'Adverse_Event');
        }else if(currentTab == 'Suspect_Products'){
            component.set("v.selTabId",'Adverse_Event');
            component.set("v.previousTabId",'Suspect_Products');
        }else if(currentTab == 'Manufacturer'){
            component.set("v.selTabId" , 'Suspect_Products');
            component.set("v.previousTabId" , 'Manufacturer');
        }else if(currentTab == 'Medical_Inquiry'){
            if(component.get("v.showAdverseEventProductComplaintTabs")){
                if(!component.get("v.adverseEventMenuCmpAttributes.hideMfr")){
                    component.set("v.selTabId",'Manufacturer');
                }else{
                    component.set("v.selTabId",'Suspect_Products');
                }
            }else{
                component.set("v.selTabId",'Initial_Repoter');
            }
            component.set("v.previousTabId",'Medical_Inquiry');
        }else if(currentTab == 'Additional_Info'){
            var additionalInfoTab = component.find("additionalInfoTab");
            var result = additionalInfoTab.validate();
            if(result == true){
                if(component.get("v.showRelatedInfoOfMedicalInquiry")){
                    component.set("v.selTabId",'Medical_Inquiry');
                }else if(component.get("v.showAdverseEventProductComplaintTabs")){
                    if(!component.get("v.adverseEventMenuCmpAttributes.hideMfr")){
                        component.set("v.selTabId",'Manufacturer');
                    }else{
                        component.set("v.selTabId",'Suspect_Products');
                    }
                }else{
                    component.set("v.selTabId",'Initial_Repoter');
                }
                component.set("v.previousTabId" , 'Additional_Info');
            }else{
                var additionalInformation = component.get("v.additionalInformation");
                var error = additionalInformation +' '+ component.get("v.reviewErrors");
                component.set("v.errors", [error]);
            }
        }
    },
    next : function(component,event,helper){
        component.set("v.disablePreviousButton",false);
        var hideAdditionalInfoTab = component.get("v.adverseEventMenuCmpAttributes.hideAdditionalInfoTab");
        var currentTab = component.get("v.selTabId");
        if(currentTab == 'Patient_Information'){
            var patientInfoComp = component.find("patientInfoComp");
            var result = patientInfoComp.validate();
            if(result == true){
                component.set("v.selTabId",'Initial_Repoter');
                component.set("v.previousTabId",'Patient_Information');
                if(!component.get("v.showAdverseEventProductComplaintTabs") && !component.get("v.showRelatedInfoOfMedicalInquiry")
                    && hideAdditionalInfoTab){
                        component.set("v.disableNextButton",true);
                    }
            }else{
                component.set("v.disablePreviousButton",true);
                var patientInformation = component.get("v.patientInformation");
                var error = patientInformation + ' ' + component.get("v.reviewErrors");
                component.set("v.errors", [error]);
            }
        }else if(currentTab == 'Initial_Repoter'){
            if(component.get("v.showAdverseEventProductComplaintTabs")){
                component.set("v.selTabId",'Adverse_Event');
                component.set("v.previousTabId",'Initial_Repoter');
            }else if(component.get("v.showRelatedInfoOfMedicalInquiry")){
                component.set("v.selTabId",'Medical_Inquiry');
                component.set("v.previousTabId",'Initial_Repoter');
                if(hideAdditionalInfoTab){
                    component.set("v.disableNextButton",true);
                }
            }else if(!hideAdditionalInfoTab){
                component.set("v.selTabId",'Additional_Info');
                component.set("v.previousTabId",'Initial_Repoter');
                component.set("v.disableNextButton",true);
            }
        }else if(currentTab == 'Adverse_Event'){
            component.set("v.selTabId",'Suspect_Products');
            component.set("v.previousTabId",'Adverse_Event');
            if(component.get("v.adverseEventMenuCmpAttributes.hideMfr") && !component.get("v.showRelatedInfoOfMedicalInquiry")
            && hideAdditionalInfoTab){
                component.set("v.disableNextButton",true);
            }
        }else if(currentTab == 'Suspect_Products'){
            if(!component.get("v.adverseEventMenuCmpAttributes.hideMfr")){
                component.set("v.selTabId",'Manufacturer');
                component.set("v.previousTabId",'Suspect_Products');
                if(!component.get("v.showRelatedInfoOfMedicalInquiry") && hideAdditionalInfoTab){
                    component.set("v.disableNextButton",true);
                }
            }else if(component.get("v.showRelatedInfoOfMedicalInquiry")){
                component.set("v.selTabId",'Medical_Inquiry');
                component.set("v.previousTabId",'Suspect_Products');
                if(hideAdditionalInfoTab){
                    component.set("v.disableNextButton",true);
                }
            }else if(!hideAdditionalInfoTab){
                component.set("v.selTabId",'Additional_Info');
                component.set("v.previousTabId",'Suspect_Products');
                component.set("v.disableNextButton",true);
            }
        }else if(currentTab == 'Manufacturer'){
            if(component.get("v.showRelatedInfoOfMedicalInquiry")){
                component.set("v.selTabId",'Medical_Inquiry');
                component.set("v.previousTabId",'Manufacturer');
                if(hideAdditionalInfoTab){
                    component.set("v.disableNextButton",true);
                }
            }else if(!hideAdditionalInfoTab){
                component.set("v.selTabId",'Additional_Info');
                component.set("v.previousTabId",'Manufacturer');
                component.set("v.disableNextButton",true);
            }
        }else if(currentTab == 'Medical_Inquiry'){
            if(!hideAdditionalInfoTab){
                component.set("v.selTabId",'Additional_Info');
                component.set("v.previousTabId",'Medical_Inquiry');
                component.set("v.disableNextButton",true);
            }
        }
    },
    fetchInitData :function(component ,event ,helper){
        helper.setNamespace(component);
        helper.setPageReferenceValues(component,event,helper);
        if(window.location.href.indexOf("isSaved") > -1) {
            component.set("v.disableSaveButton",true);
        }
        var action =  component.get("c.getData");
        action.setParams({
            aeId: component.get("v.aeId")
        });
        action.setCallback(this, function(response){
            var state= response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                component.set("v.type",returnValue.type);
                component.set("v.fieldLabels" , returnValue.fieldLabels);
                component.set("v.medicalInquiryDescription" , returnValue.medicalInquiryDescription);
                component.set("v.notes" , returnValue.notes);
                component.set("v.submissionStatusOptions",returnValue.submissionStatusOptions);
                component.set("v.submissionStatus", returnValue.selectedSubmissionStatus);
                var eventTypesInNew = [];
                if(returnValue.typeSelectedVal == 'Medical Inquiry'){
                    component.set("v.showRelatedInfoOfMedicalInquiry",true);
                }else if(returnValue.typeSelectedVal == 'Adverse Event' || returnValue.typeSelectedVal ==  'Product Complaint'){
                    component.set("v.showAdverseEventProductComplaintTabs",true);
                }
                if(component.get("v.editMode")){
                    component.set("v.eventTypeInEdit",returnValue.typeSelectedVal);
                }
                if(!$A.util.isEmpty(returnValue.typeSelectedVal)){
                    eventTypesInNew.push(returnValue.typeSelectedVal);
                }
                component.set("v.eventTypesInNew",eventTypesInNew);
                component.set("v.dateFormat",component.get("v.adverseEventMenuCmpAttributes.dateFormat"));
            }
            else{
                var error;
                var errors = response.getError();
                if(errors != null && errors.length > 0 && !$A.util.isEmpty(errors[0]['message'])) {
                error = errors[0]['message'];
                }
                component.set("v.errors", [error]);
            }
        })
        $A.enqueueAction(action);
    },
    validate: function(component, event, helper) {
        component.set('v.errors',[]);
        var isPatientInfoValid = true;
        var isSuspectProductInfoValid = true;
        var isAdditionalInfoValid = true;
        var patientInfoComp = component.find("patientInfoComp");
        if(!component.get("v.editMode")){
            var eventTypeField = component.find('eventTypeField');
            if(component.get("v.eventTypesInNew").length < 1){
                eventTypeField.showHelpMessageIfInvalid();
                return false;
            }
        }
        if(!$A.util.isEmpty(patientInfoComp)){
            isPatientInfoValid = patientInfoComp.validate();
            if(!isPatientInfoValid) {
                helper.addErrorMessage(component, helper, component.get("v.patientInformation") + ' : ' + component.get("v.reviewErrors"));
            }
        }
        var suspectProductComp = component.find("suspectProductComp");
        if(!$A.util.isEmpty(suspectProductComp)){
            isSuspectProductInfoValid = suspectProductComp.validate();
            if(!isSuspectProductInfoValid) {
                helper.addErrorMessage(component, helper, component.get("v.suspectProducts") + ' : ' + component.get("v.reviewErrors"));
            }
        }
        var hideAdditionalInfoTab = component.get("v.adverseEventMenuCmpAttributes.hideAdditionalInfoTab");
        if((hideAdditionalInfoTab == false || hideAdditionalInfoTab =='false')){
            var additionalInfoTab = component.find("additionalInfoTab");
            if(!$A.util.isEmpty(additionalInfoTab)){
                isAdditionalInfoValid = additionalInfoTab.validate();
            }
            if(!isAdditionalInfoValid) {
                helper.addErrorMessage(component, helper, component.get("v.additionalInformation") + ' : ' + component.get("v.reviewErrors"));
            }
        }
        if(!isPatientInfoValid || !isSuspectProductInfoValid || !isAdditionalInfoValid){
            return false;
        }else{
            return true;
        }
    },

	addErrorMessage: function (component, helper, errorMessage){
        var errorList = component.get("v.errors");
        errorList.push(errorMessage);
        component.set("v.errors", errorList);
    },

	switchTabs: function (component, event, helper){
	    component.set("v.disablePreviousButton",false);
	    component.set("v.disableNextButton",false);
        var currentTab = component.get("v.selTabId");
        component.set("v.previousTabId" , currentTab);
        if(currentTab == 'Patient_Information'){
            component.set("v.disablePreviousButton",true);
        }
        var hideAdditionalInfoTab = component.get("v.adverseEventMenuCmpAttributes.hideAdditionalInfoTab");
        var hideMfr = component.get("v.adverseEventMenuCmpAttributes.hideMfr");
        var medicalInquiryTabVisible  = component.get("v.showRelatedInfoOfMedicalInquiry");
        var aeAndProductComplaintTabsVisible  = component.get("v.showAdverseEventProductComplaintTabs");
        if(currentTab == 'Additional_Info' || (currentTab == 'Manufacturer' && hideAdditionalInfoTab && !medicalInquiryTabVisible)
                || (currentTab == 'Suspect_Products' && hideMfr && !medicalInquiryTabVisible && hideAdditionalInfoTab)
                || (currentTab == 'Initial_Repoter' && !aeAndProductComplaintTabsVisible && !medicalInquiryTabVisible && hideAdditionalInfoTab)
                || (currentTab == 'Medical_Inquiry' && hideAdditionalInfoTab)){
            component.set("v.disableNextButton",true);
        }
    },
    handleCancel : function(component,event,helper){
        var workspaceAPI = component.find("adverseEventsMenu2Workspace");
        workspaceAPI.isConsoleNavigation().then(function(isConsole){
            if(isConsole){
                workspaceAPI.getFocusedTabInfo().then(function(response) {
                    var focusedTabId = response.tabId;
                    workspaceAPI.closeTab({tabId: focusedTabId});
                }).catch(function(error) {
                    var errors = [];
                    errors.push(error);
                    helper.handleErrors(component,errors);
                });
            }else{
                window.close();
            }
        })
        .catch(function(error) {
            var allErrors = [];
            allErrors.push(error);
            helper.handleErrors(component,allErrors);
        });
    },
    createAERec: function (component, event, helper){
        component.set('v.disableSaveButton',true);
        if(helper.validate(component, event, helper)){
            var visitedTabs = component.get("v.visitedTab");
            var eventTypes = component.get("v.eventTypesInNew");
            if(component.get("v.editMode")){
                eventTypes = [];
                var eventTypeInEdit = component.get("v.eventTypeInEdit");
                eventTypes.push(eventTypeInEdit);
            }
            if(!eventTypes.includes('Adverse Event') && !eventTypes.includes('Product Complaint')){
                visitedTabs['adverseEvent'] = false;
                visitedTabs['suspectProducts'] = false;
                visitedTabs['manufacturer'] = false;
            }else if(!eventTypes.includes('Medical Inquiry')){
                visitedTabs['medicalInquiry'] = false;
            }
            var action =  component.get("c.createAdverseEvent");
            var aeWrapperVal = component.get("v.aeWrapper");
            var aeInfoMap = {'type' : eventTypes,
                              'medicalInquiryDescription' : component.get("v.medicalInquiryDescription"),
                              'notes' : component.get("v.notes"),
                              'submissionStatus' : component.get("v.submissionStatus")
                              };
            aeWrapperVal['aeInfo']=aeInfoMap;
            action.setParams({
                aeId: component.get("v.aeId"),
                caseId: component.get("v.caseId"),
                aeWrapper: aeWrapperVal,
                visitedTab: visitedTabs,                                                //component.get("v.visitedTab"),
                adverseEventMenuCmpAttributes : component.get("v.adverseEventMenuCmpAttributes")

            });
            action.setCallback(this, function(response){
                var state= response.getState();
                if (state == "SUCCESS"){
                    var returnValue =response.getReturnValue();
                    var adverseEvents = returnValue.adverseEvents;
                    var adverseEventObjectName = returnValue.adverseEventObjectName;
                    for(var i=0;i<adverseEvents.length;i++){
                        var eachResponse = [];
                        eachResponse.push(adverseEvents[i].Name);
                        eachResponse.push(adverseEvents[i].Id);
                        eachResponse.push(adverseEventObjectName);
                        helper.showToast(component, event, helper,eachResponse);
                    }
                    var workspaceAPI = component.find("adverseEventsMenu2Workspace");
                    workspaceAPI.isConsoleNavigation().then(function(isConsole){
                        if(isConsole){
                            var appEvent = $A.get("e.c:PC_AE2_RefreshEvent");
                            appEvent.fire();
                        }
                        if(!component.get("v.editMode")){
                            setTimeout(function(){
                                if(isConsole){
                                    $A.get('e.force:refreshView').fire();
                                }else{
                                    window.location.reload();
                                }
                                component.set('v.disableSaveButton',false);
                            },5000);
                        }else{
                             if(isConsole){
                                 workspaceAPI.getFocusedTabInfo().then(function(response){
                                     var focusedTabId = response.tabId;
                                     workspaceAPI.closeTab({tabId: focusedTabId});
                                 }).catch(function(error) {
                                     var errors = [];
                                     errors.push(error);
                                     helper.handleErrors(component,errors);
                                     component.set('v.disableSaveButton',false);
                                 });
                             }else{
                                 window.location.href = window.location.href + '#isSaved';
                                 component.set('v.disableSaveButton',true);
                             }
                        }
                    }).catch(function(error) {
                        var allErrors = [];
                        allErrors.push(error);
                        helper.handleErrors(component,allErrors);
                        component.set('v.disableSaveButton',false);
                    });
                }
                else{
                    //helper.handleErrors(component, response.getError());
                    var error;
                    var errors = response.getError();
                    if(errors != null && errors.length > 0 && !$A.util.isEmpty(errors[0]['message'])) {
                        error = errors[0]['message'];

                    }
                    component.set("v.errors", [error]);
                    component.set('v.disableSaveButton',false);
                }
            });

            $A.enqueueAction(action);
        }
        else {
            component.set('v.disableSaveButton',false);
        }
    },

    showToast : function(component, event, helper,response) {
        var toastEvent = $A.get("e.force:showToast");
        var msg = response[0] + ' ' +component.get("v.saveSuccessMessage");
        var title = component.get("v.toastSuccessTitle");
        toastEvent.setParams({
            "title": title,
            "message": msg,
             "messageTemplate": '{0} - ' + component.get("v.saveSuccessMessage"),
             "messageTemplateData": [ {
                url: window.location.protocol+'//'+window.location.host + '/lightning/r/'+response[2]+'/'+response[1]+'/view' ,
                label: response[0], },
              ],
            "type": "success",
            "duration":5000
        });
        toastEvent.fire();
    },
    handleErrors : function(component, errors) {
        // Configure error toast
        console.error('Errors:');
        console.error(errors);
        let toastParams = {
            title: "Error",
            message: component.get("v.errorDescription"), // Default error message
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
        $A.get('e.force:refreshView').fire();
    },
    clearErrors : function(component) {
        component.set("v.errors", []);
    }
})