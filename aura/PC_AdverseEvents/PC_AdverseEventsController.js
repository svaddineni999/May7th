/**
 * Created by peharitha on 11/13/2018.
 */
({
    doInit: function(component, event, helper){
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
        var api = namespace +':PC_AdverseEventMenu';
        var aeList = component.get("v.AEList");
        var adverseEventCaption ;
        var submissionStatus ='' ;
        if(aeId == undefined || aeId == null) {
          //versionNumber = component.get("v.newAdverseEventVersionLabel");
          adverseEventCaption ='';
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
        var modalBody;
        $A.createComponent(api,{"caseId": component.get("v.recordId"),
         "aeId": aeId, "adverseEventMenuCmpAttributes": component.get("v.adverseEventMenuCmpAttributes"),
         "dateFormat": component.get("v.adverseEventMenuCmpAttributes.dateFormat"),
         "dateFormatErrorMessage": component.get("v.dateFormatErrorMessage"),"submissionStatus": submissionStatus,
         "versionNumber":adverseEventCaption},
                           function(content, status, errorMessage) {
                               if (status === "SUCCESS") {
                                   modalBody = content;
                                   component.find('overlayLib').showCustomModal({
                                       header: component.get("v.AEpoupLabel") +' ' +adverseEventCaption ,
                                       body: modalBody,
                                       showCloseButton: true,
                                       cssClass: "mymodal slds-modal_large pcOverlayModal",
                                       closeCallback: function() {
                                           helper.clearErrorMessages(component, event, helper);
                                           helper.clearAEListAttributes(component,event, helper);
                                           helper.fetchAEList(component, event, helper);

                                       }
                                   })
                               }else if (status === "ERROR") {
                                   // Show error message
                                   component.set("v.errors",errorMessage);
                               }
                           }
                          );

        var cmpTarget = component.find('overlayLib');
        $A.util.removeClass(cmpTarget, 'slds-p-around_medium');
    },

   downloadPDF: function(component,event,helper){
          var adverseEventRecId = event.getSource().get("v.value");
          var url = '/apex/'+component.get('v.vfPageName')+'?adverseEventId='+adverseEventRecId;
          window.open(url);
       }
})