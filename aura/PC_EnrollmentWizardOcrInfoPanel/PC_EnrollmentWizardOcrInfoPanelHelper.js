/**
 * Created by sathekumar on 6/25/2021.
 */
({
    checkApplicantCreatedUsingOCR: function(component) {
        var action = component.get('c.getApplicantOcrDetails');
        action.setParams({
           enrollmentCaseId : component.get("v.enrollmentCaseId")
        });
        action.setCallback(this, function(response) {
           var state = response.getState();
           if (state === 'SUCCESS'){
               var returnValue = response.getReturnValue();
               var warningMessages = [];
               if(returnValue.isOcrEnabled && returnValue.isCreatedUsingOCR && returnValue.isReviewed){
                   component.set('v.messageState', 'info');
                   warningMessages.push(component.get('v.ocrApplicantReviewed'));
               } else if(returnValue.isOcrEnabled && returnValue.isCreatedUsingOCR && !returnValue.isReviewed){
                   component.set('v.messageState', 'warning');
                   warningMessages.push(component.get('v.ocrApplicantNotReviewed'));
               }
               component.set('v.warningMessages', warningMessages);
           }
        });
        $A.enqueueAction(action);
    },
})