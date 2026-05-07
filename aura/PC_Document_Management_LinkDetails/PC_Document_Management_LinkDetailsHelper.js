/**
 * Created by havalakki on 2/8/2018.
 */
({

    getAccountDetailsAndApexFields : function(component, event, patient) {
            var action = component.get("c.getAccountDetails"); //call this method to fetch account details
            action.setParams({
                accountId : patient
            });
            action.setCallback(this, function(a) {
                var state = a.getState();
                if (state === "SUCCESS") {
                    if(component.isValid()) {
                        var patAcc =  a.getReturnValue();
                        var name = patAcc.AccFirstName + ' ' + patAcc.AccLastName;

                        if(undefined!=patAcc.AccFirstName&&undefined!=patAcc.AccLastName)
                        {
                            component.set("v.patientName", name);
                        }else{
                            component.set("v.patientName", '');
                        }
                        component.set("v.accntRecTypeDevName",patAcc.recordTypeDevName);
                        this.getDynamicFieldSet(component, event);
                    }
                }else if (state ==="ERROR"){
                    var errors = a.getError();
                    console.log(JSON.stringify(errors));
                    var errText = component.get("v.ErrorText");
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log(errText);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                }
            });
            $A.enqueueAction(action);
        },

    closeWindow : function(component) {
        var appEventns = 'e.' + component.get("v.namespace") + ':PC_RefreshChildCmp';
        var appEvent = $A.get(appEventns);
        appEvent.fire();
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

    getDynamicFieldSet: function(component,event){
        debugger;
            var action = component.get('c.getApexFields');
            action.setParams({
                recordId: component.get('v.patientId'),
                docEngagementProgId: component.get('v.docEngagementProgId'),
                accountRecordType: component.get("v.accntRecTypeDevName"),
                docId: component.get('v.docId')
            });
            action.setCallback(this,function(response) {
                   var objectAndRecordIdsMapsList=[];
                   var objectFieldsWrapper = JSON.parse(response.getReturnValue());
                   component.set('v.objectFieldsWrapper',objectFieldsWrapper);

                   if(!$A.util.isUndefinedOrNull(objectFieldsWrapper)&&objectFieldsWrapper.length!=0){

                       for(var i=0;i<objectFieldsWrapper.length;i++){
                           if(objectFieldsWrapper[i].isError){
                            component.set('v.isError',objectFieldsWrapper[i].isError);
                            component.set('v.errorMessage',objectFieldsWrapper[i].errorMessage);
                            component.set('v.showDiv',false);
                            break;
                          }
                          else{
                              component.set('v.isError',objectFieldsWrapper[i].isError);
                              component.set('v.showDiv',true);
                          }
                      }
                  }
                  else{
                      component.set('v.isError',true);
                      component.set('v.showDiv',false);
                  }

            });
            $A.enqueueAction(action);
        },

    saveUpdateDocLogs: function(component,event,helper){
        var action=component.get("c.saveUpdateDocLogsServer");
        debugger;
        action.setParams({
            documentId: component.get('v.docId'),
            stringOfListOfAllObjectRecordsFieldsets: JSON.stringify(component.get('v.objectFieldsWrapper'))

            });
        debugger;
        action.setCallback(this,function(response){
                var state=response.getState();
                var errors=[];
                var resultString=response.getReturnValue();

                if(state == "ERROR"){
                    resultString = 'ERROR';
                    errors = response.getError();
                }
                var closeModalBoxEvent=component.getEvent('closeParentModalBox');
                closeModalBoxEvent.setParam('resultString',resultString);
                closeModalBoxEvent.setParam('errors',errors);
                closeModalBoxEvent.fire();
        });
         $A.enqueueAction(action);
    }

})