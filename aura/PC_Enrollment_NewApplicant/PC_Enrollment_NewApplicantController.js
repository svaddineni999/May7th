({	
    doInit : function(component, event, helper) {
        component.set('v.isNewEnrollmentBtnClicked',false);
    	helper.setNamespace(component);
        var patientId = component.get("v.newApplicant.patientId");
        if(patientId) {
            // use isExisting applicant for PC-1184
            // changes are reverted. story needs more elaborated thought
            component.set("v.isExistingApplicant", true);
        }

        var searchPatient= {
               fsFields:""
        };
        component.set("v.fieldSetName", '');
        component.set("v.searchPatient", searchPatient);
        helper.setFieldSetObject(component, event, helper);
    },
    
    hideModalBox : function(component, event, helper) {
        helper.hideModal(component, event, helper);
    },
    
    enrollPatient : function(component, event, helper) {
        helper.showPopupHelper(component, 'modaldialog', 'slds-fade-in-');
        helper.showPopupHelper(component,'backdrop','slds-backdrop--');
    },
    
    createApplicant : function(component, event, helper) {
        component.set("v.isNewEnrollmentBtnClicked",true);
        var errors ;
        component.set("v.errors", errors);
        var validFieldSet = helper.validateFieldSetForm(component, event, helper);
        var workspaceAPI = component.find("enrollNewApplicantWorkspace");
        var isCustomApp = component.get("v.isCustomApp");
        var error = true;
        if(validFieldSet){
            error = false;
        }
        if(!error) {
            var fsFields=component.get("v.fsFieldValues");
            var programId = component.get("v.newApplicant.engagementProgramId");
            var patientId = component.get("v.newApplicant.patientId");
            var docId = component.get("v.docId");
            var onlineApplicantId = component.get("v.onlineFormApplicantId");
            var action = component.get("c.createApplicants");
            action.setParams({
                "fsFieldsMap"  : fsFields,
                "programId"	:	programId,
                "documentId":	docId,
                "onlineApplicantId" : onlineApplicantId,
                "patientId"	: 	patientId
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var returnValue = response.getReturnValue();
                    var caseEnrollId = returnValue.Id;
                    var caseNumber = returnValue.CaseNumber;
                    if (caseEnrollId !== '') {
                        component.set("v.caseId", caseEnrollId);
                        helper.fireToastMessage(component, event, helper);
                        helper.hideModal(component, event, helper);
                        if(caseEnrollId && docId) {
                            helper.linkDocumentToCase(component, event, helper);
                        }
                        /*[PC-4340] - Enrollment launch logic Change Start*/
                        var namespace = component.get("v.namespace");
                        var componentAPIName =  namespace+'__'+component.get("v.enrollmentWizardComponentName");
                        var pageAPIName = component.get("v.namespacePrefix") +component.get("v.enrollmentWizardPageName");
                        var qualifiedIdName = CH_PC_Util.getQualifiedQueryParam(component,'Id',namespace);
                        var tabParamsObject = new Object();
                        tabParamsObject.uid = 'ENA-'+caseEnrollId;
                        tabParamsObject[qualifiedIdName] = caseEnrollId;
                        var urlParams = '?'+qualifiedIdName+'='+caseEnrollId;
                        var device = $A.get("$Browser.formFactor");
                        if(device != 'DESKTOP'){
                            var navService = component.find("navService");
                            // Uses the pageReference definition in the init handler
                            var pageReference = {
                                "type": "standard__component",
                                "attributes": {
                                    "componentName": componentAPIName
                                },
                                "state": tabParamsObject
                            };
                            event.preventDefault();
                            navService.navigate(pageReference);
                        }else{
                            if(isCustomApp){
                                var url = '/lightning/n/' + pageAPIName + urlParams;
                                window.open(url,"_self");
                            }else{
                                CH_PC_Util.openLightningComponentInNewTab(workspaceAPI,componentAPIName,pageAPIName,tabParamsObject,
                                                           component.get("v.enrollmentWizardTabLabel")+' : '+caseNumber,component.get("v.enrollmentWizardTabIcon"),true,urlParams);
                            }
                        }
                    }
                } else if (action.getState() ==="ERROR") {
                    console.log("Failed with state: " + state);
                    var lightingErrorMessage = component.get("v.lightingErrorMessage");
                    var responseErrors = response.getError();
                    console.error(responseErrors);
                    if(!$A.util.isEmpty(responseErrors) && responseErrors.length > 0) {
                         if(!$A.util.isEmpty(responseErrors[0]['message'])) {
                            lightingErrorMessage = responseErrors[0]['message'];
                         }
                         else if(!$A.util.isEmpty(responseErrors[0]['pageErrors'][0]['message'])) {
                             lightingErrorMessage = responseErrors[0]['pageErrors'][0]['message'];
                         }

                    }
                    component.set("v.errors", [lightingErrorMessage]);
                	component.set("v.isNewEnrollmentBtnClicked",false);
                } else{
                    console.log('Failed with State>> '+action.getState());
                    component.set("v.isNewEnrollmentBtnClicked",false);
                }
            });
            $A.enqueueAction(action);
        }else{
            component.set("v.isNewEnrollmentBtnClicked",false);
        }
        event.preventDefault();
        return false;
    }
})