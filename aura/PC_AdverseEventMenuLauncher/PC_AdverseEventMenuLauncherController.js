/**
 * Created by havalakki on 10/17/2019.
 */
({
    doInit : function (component, event, helper) {
        helper.setNamespace(component);
        if(component.get("v.isUsedInSearchContext")){
            helper.initializeAttributes(component, event, helper);
        }else{
            helper.setProperties(component, event, helper);
        }


    }, 
    handleSearchParams : function(component) {
       if(component.get("v.isUsedInSearchContext")) {
            component.set("v.selectedRecordId", null);
       }
    },
    populateSelectedRecDetails : function(component, event, helper) {
         if(component.get("v.isUsedInSearchContext")) {
             var selectedRecId= event.getParam("selectedRecordId");
             component.set('v.selectedRecordId',selectedRecId);
             if(selectedRecId != null && selectedRecId != undefined){
                  var openAEPopUpCmp = component.find("openAEPopUpButtonId");
                  openAEPopUpCmp.set("v.disabled",true);
             }
         }
    },

    openAEPopup : function(component, event, helper){
        var namespace = component.get("v.namespace");
        var api = namespace +':PC_AdverseEventMenu2';
        var modalBody;
        var accountId = component.get("v.selectedRecordId");
        if($A.util.isUndefinedOrNull(accountId)){
            accountId = 'NULL';
        }
        var caseId = component.get("v.caseId");
        var recordId = component.get("v.caseId");
        var componentAPIName =  namespace+'__'+'PC_AdverseEventMenu2';
        var workspaceAPI = component.find("adverseEventMenuLauncherWorkspace");
        var caseId = CH_PC_Util.getQualifiedQueryParam(component,'caseId',namespace);
        var qualifiedAeId = CH_PC_Util.getQualifiedQueryParam(component,'aeId',namespace);
        var qualifiedPatId = CH_PC_Util.getQualifiedQueryParam(component,'patId',namespace);
        var qualifiedHideAdditionalInfoTab = CH_PC_Util.getQualifiedQueryParam(component,'hideAdditionalInfoTab',namespace);
        var qualifiedAdditionalInfoTabFieldSet = CH_PC_Util.getQualifiedQueryParam(component,'additionalInfoTabFieldSet',namespace);
        var qualifiedUsePrescriptionForSuspectProducts = CH_PC_Util.getQualifiedQueryParam(component,'usePrescriptionForSuspectProducts',namespace);
        var qualifiedUseRxForMI = CH_PC_Util.getQualifiedQueryParam(component,'useRxForMI',namespace);
        var qualifiedHideCoding = CH_PC_Util.getQualifiedQueryParam(component,'hideCoding',namespace);
        var qualifiedHideMfr = CH_PC_Util.getQualifiedQueryParam(component,'hideMfr',namespace);
        var qualifiedHideNotes = CH_PC_Util.getQualifiedQueryParam(component,'hideNotes',namespace);
        var qualifiedDateFormat = CH_PC_Util.getQualifiedQueryParam(component,'dateFormat',namespace);
        var qualifiedDateFormatErrorMessage = CH_PC_Util.getQualifiedQueryParam(component,'dateFormatErrorMessage',namespace);
        var qualifiedSubmissionStatus = CH_PC_Util.getQualifiedQueryParam(component,'submissionStatus',namespace);
        var qualifiedVersionNumber = CH_PC_Util.getQualifiedQueryParam(component,'versionNumber',namespace);
        var dateFormat =  component.get("v.adverseEventMenuCmpAttributes.dateFormat");
        var hideAdditionalInfoTab =  component.get("v.adverseEventMenuCmpAttributes.hideAdditionalInfoTab");
        var additionalInfoTabFieldSet =  component.get("v.adverseEventMenuCmpAttributes.additionalInfoTabFieldSet");
        var usePrescriptionForSuspectProducts =  component.get("v.adverseEventMenuCmpAttributes.usePrescriptionForSuspectProducts");
        var useRxForMI =  component.get("v.adverseEventMenuCmpAttributes.useRxForMI");
        var hideCoding =  component.get("v.adverseEventMenuCmpAttributes.hideCoding");
        var hideMfr =  component.get("v.adverseEventMenuCmpAttributes.hideMfr");
        var hideNotes =  component.get("v.adverseEventMenuCmpAttributes.hideNotes");
        var dateFormatErrorMessage =  component.get("v.dateFormatErrorMessage");
        var tabParamsObject = new Object();
        tabParamsObject.uid = 'AE-'+recordId;
        tabParamsObject[caseId] = recordId;
        tabParamsObject[qualifiedAeId] = null;
        tabParamsObject[qualifiedPatId] = accountId;
        tabParamsObject[qualifiedHideAdditionalInfoTab] = hideAdditionalInfoTab;
        tabParamsObject[qualifiedAdditionalInfoTabFieldSet] = additionalInfoTabFieldSet;
        tabParamsObject[qualifiedUsePrescriptionForSuspectProducts] = usePrescriptionForSuspectProducts;
        tabParamsObject[qualifiedUseRxForMI] = useRxForMI;
        tabParamsObject[qualifiedHideCoding] = hideCoding;
        tabParamsObject[qualifiedHideMfr] = hideMfr;
        tabParamsObject[qualifiedHideNotes] = hideNotes;
        tabParamsObject[qualifiedDateFormat] = dateFormat;
        tabParamsObject[qualifiedDateFormatErrorMessage] = dateFormatErrorMessage;

        var urlParams = '?'+caseId+'='+recordId+'&'+qualifiedAeId+'='+'NULL'+'&'+qualifiedHideAdditionalInfoTab+'='+hideAdditionalInfoTab
        +'&'+qualifiedAdditionalInfoTabFieldSet+'='+additionalInfoTabFieldSet+'&'+qualifiedDateFormat+'='+dateFormat+'&'+
        qualifiedDateFormatErrorMessage+'='+dateFormatErrorMessage +'&'+qualifiedSubmissionStatus+'='+'NULL'+'&'+qualifiedVersionNumber+'='+'NULL'
        +'&'+qualifiedUsePrescriptionForSuspectProducts+'='+usePrescriptionForSuspectProducts
        +'&'+qualifiedUseRxForMI+'='+useRxForMI
        +'&'+qualifiedHideCoding+'='+hideCoding
        +'&'+qualifiedHideMfr+'='+hideMfr
        +'&'+qualifiedHideNotes+'='+hideNotes+'&'+qualifiedPatId+'='+accountId;

        workspaceAPI.isConsoleNavigation().then(function(isConsole) {
            if (isConsole) {
                // this block of code helps to open the component in new console tab if it is console app
                CH_PC_Util.openLightningComponentInNewTab(workspaceAPI,componentAPIName,'',tabParamsObject,
                        component.get("v.adverseEventTabName"),'action:new_note',true,urlParams);
            } else {
                // this block of code helps to open the component in new tab if it is lightning app
                var url = '/lightning/cmp/' + componentAPIName + urlParams;
                window.open(url,"_blank");
            }
        })
        .catch(function(error) {
            console.log(error);
        });
        var cmpTarget = component.find('overlayLib');
        $A.util.removeClass(cmpTarget, 'slds-p-around_medium');
    }
})