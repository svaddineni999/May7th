/**
 * Created by peharitha on 11/13/2018.
 */
({
    doInit: function(component, event, helper){
        debugger;
        helper.setNamespace(component);
        helper.fetchAEList(component, event, helper);
        helper.fetchDownloadPDFPageName(component, event, helper);
    },
    navigateToRecord : function(component , event, helper){
        var recId = event.getSource().get("v.value");
        window.open('/one/one.app#/sObject/' + recId );
    },
    navigateToRecordDetail : function(component , event, helper){
        var recId = event.currentTarget.id;
        window.open('/one/one.app#/sObject/' + recId );
    },
    editAE : function(component, event, helper){
        var editRecordEvent = $A.get("e.force:editRecord");
        var id = event.getSource().get("v.value");
        editRecordEvent.setParams({
            "recordId": id
        });
        editRecordEvent.fire();
    },
    openAEPopup : function(component, event, helper){
        var aeId = event.getSource().get("v.value");
        var namespace = component.get("v.namespace");
        var api = namespace +':PC_AdverseEventMenu2';
        var aeList = component.get("v.AEList");
        var adverseEventCaption ;
        var submissionStatus ='' ;
        var tabUID = 'AE-';
        if(aeId == undefined || aeId == null) {
          //versionNumber = component.get("v.newAdverseEventVersionLabel");
          adverseEventCaption ='';
        }else{
            tabUID = tabUID + aeId;
        }
        if(!$A.util.isEmpty(aeList)){
            for(var j=0; j < aeList.length; j++) {

                 if(aeList[j].aeId == aeId){
                     if(!$A.util.isEmpty(aeList[j].adverseEventCaption)){
                     adverseEventCaption = aeList[j].adverseEventCaption;
                     submissionStatus = aeList[j].submissionStatus;
                     }
                 /*if((!$A.util.isEmpty(aeList[j].currentAdverseEventId))){
                     aeId =aeList[j].currentAdverseEventId;
                 }*/
                 break;
                 }
            }
        }
        var recordId = component.get("v.recordId");
        if(tabUID == 'AE-'){
            if(component.get("v.isActionCenterComponent")){
                tabUID = 'ACAE-' + recordId;
            }else{
                tabUID = 'LCAE-' + recordId;
            }
        }
        var componentAPIName =  namespace+'__'+'PC_AdverseEventMenu2';
        var workspaceAPI = component.find("adverseEvents2Workspace");
        var caseId = CH_PC_Util.getQualifiedQueryParam(component,'caseId',namespace);
        var qualifiedAeId = CH_PC_Util.getQualifiedQueryParam(component,'aeId',namespace);
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
        var hideNotes = component.get("v.adverseEventMenuCmpAttributes.hideNotes");
        var dateFormatErrorMessage =  component.get("v.dateFormatErrorMessage");
        var tabParamsObject = new Object();
        tabParamsObject.uid = tabUID;
        tabParamsObject[caseId] = recordId;
        tabParamsObject[qualifiedAeId] = aeId;
        tabParamsObject[qualifiedHideAdditionalInfoTab] = hideAdditionalInfoTab;
        tabParamsObject[qualifiedAdditionalInfoTabFieldSet] = additionalInfoTabFieldSet;
        tabParamsObject[qualifiedUsePrescriptionForSuspectProducts] = usePrescriptionForSuspectProducts;
        tabParamsObject[qualifiedUseRxForMI] = useRxForMI;
        tabParamsObject[qualifiedHideCoding] = hideCoding;
        tabParamsObject[qualifiedHideMfr] = hideMfr;
        tabParamsObject[qualifiedHideNotes] = hideNotes;
        tabParamsObject[qualifiedDateFormat] = dateFormat;
        tabParamsObject[qualifiedDateFormatErrorMessage] = dateFormatErrorMessage;
        tabParamsObject[qualifiedSubmissionStatus] = submissionStatus;
        tabParamsObject[qualifiedVersionNumber] = adverseEventCaption;

        var urlParams = '?'+caseId+'='+recordId+'&'+qualifiedAeId+'='+aeId+'&'+qualifiedHideAdditionalInfoTab+'='+hideAdditionalInfoTab+
        '&'+qualifiedAdditionalInfoTabFieldSet+'='+additionalInfoTabFieldSet+'&'+qualifiedDateFormat+'='+dateFormat+'&'+
        qualifiedDateFormatErrorMessage+'='+dateFormatErrorMessage+'&'+qualifiedSubmissionStatus+'='+submissionStatus+'&'+
        qualifiedVersionNumber+'='+adverseEventCaption
        +'&'+qualifiedUsePrescriptionForSuspectProducts+'='+usePrescriptionForSuspectProducts
        +'&'+qualifiedUseRxForMI+'='+useRxForMI
        +'&'+qualifiedHideCoding+'='+ hideCoding
        +'&'+qualifiedHideMfr+'='+hideMfr
        +'&'+qualifiedHideNotes+'='+hideNotes;

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
    },

   downloadPDF: function(component,event,helper){
          var adverseEventRecId = event.getSource().get("v.value");
          var url = '/apex/'+component.get('v.vfPageName')+'?adverseEventId='+adverseEventRecId;
          window.open(url);
       }
})