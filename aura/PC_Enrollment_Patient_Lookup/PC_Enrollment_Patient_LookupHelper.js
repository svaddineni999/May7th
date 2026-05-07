({
	hidePopupHelper: function(component, componentId, className) {
        var modal = component.find(componentId);
        $A.util.addClass(modal, className+'hide');
        $A.util.removeClass(modal, className+'open');
    },

    showPopupHelper: function(component, componentId, className) {
        var modal = component.find(componentId);
        $A.util.removeClass(modal, className+'hide');
        $A.util.addClass(modal, className+'open');
    },

    setSearchFSMapToSend : function(component, event, helper, idValue) {
        var searchFSMap         = new Map();
        searchFSMap             = component.get("v.searchFSMap");
        var searchFSMapToSend   = searchFSMap[idValue];
        component.set("v.searchFSMapToSend",searchFSMapToSend);
        component.set("v.newApplicantFSfield",searchFSMapToSend);
    },

    showToast : function(mode, message, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            mode: mode,
            message: message,
            type: type,
        });
        toastEvent.fire();
    },
    docDetailsHelper: function(component, helper, docId) {
        var action = component.get("c.getDocDetails");
        action.setParams({
            "docId": docId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                    var engagementProgList = returnValue.lstEngagementProgram;
                    //Sort engagementProgList
                    engagementProgList.sort(function(a, b){
                        let x = a.manuProgramName.toLowerCase();
                        let y = b.manuProgramName.toLowerCase();
                        if (x < y) {return -1;}
                        if (x > y) {return 1;}
                        return 0;
                    });
                    if ($A.util.isEmpty(component.get("v.engagementProgramList"))) {
                    component.set("v.engagementProgramList", engagementProgList);
                    component.set("v.docDetails", returnValue);
                    component.set("v.searchPatient.fsFields",returnValue.fsFields);
                    component.set("v.searchPatient.masterPatient",returnValue.masterPatient);

                    var isOnlineForm = component.get("v.docDetails.isOnlineForm");
                    component.set("v.isOnlineForm",isOnlineForm );

                    var appID = component.get("v.docDetails.onlineApplicantId");
                    component.set("v.onlineFormApplicantId",appID );
                    var engagementProgramName;
                    var engagementProgramId;
                    var engagementProgramCode;
                    if (!$A.util.isUndefinedOrNull(returnValue.engagementProgramId)) {
                        engagementProgramName = component.get("v.docDetails.engagementProgramName");
                        engagementProgramId = component.get("v.docDetails.engagementProgramId");
                        engagementProgramCode      = component.get("v.docDetails.engagementProgramCode");
                        component.set("v.docEngagementProgram",true);
                    }else {
                        engagementProgramName = component.get("v.engagementProgramList[0].programName");
                        engagementProgramId = component.get("v.engagementProgramList[0].programId");
                        engagementProgramCode      = component.get("v.engagementProgramList[0].engagementProgramCode");
                        component.set("v.docEngagementProgram",false);
                        component.find("engagementProgram").focus()
                    }
                    component.set("v.searchPatient.engagementProgram", engagementProgramName);
                    component.set("v.searchPatient.engagementProgramId", engagementProgramId);
                    component.set("v.searchPatient.engagementProgramCode", engagementProgramCode);

                    //Engagement Program should be readonly, when populated on the document [PC-1364]
                    //Looks like when the code was restructured this code was removed. Had to add back as manufacturer info
                    //was not getting set correctly.
                    for (var i=0 ; i<engagementProgList.length ; i++) {
                        if (engagementProgList[i].programId == engagementProgramId) {
                            var manufacturerId = engagementProgList[i].manufacturerId;
                            var manuProgramName = engagementProgList[i].manuProgramName;
                            component.set("v.searchPatient.manufacturerId", manufacturerId);
                            component.set("v.searchPatient.manuProgramName", manuProgramName);
                        }
                    }
                        helper.setFieldSetObject(component, event, helper);
                    }else{
                        component.set("v.searchPatient.fsFields",returnValue.fsFields);
                        helper.setFieldSetObject(component, event, helper);
                    }
            }else {
              var error = component.get("v.lightingErrorMessage");
              var errors = response.getError();

                if(!$A.util.isEmpty(errors) && errors.length > 0 && !$A.util.isEmpty(errors[0]['message'])) {
                     error = errors[0]['message'];

                }
                component.set("v.errors", [error]);
            console.log("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);
    },

    getfsFieldsForEngagementProgram : function(component, event, helper) {
        var action = component.get("c.getfsFieldsForEngagementProgram");

        var searchDetails = component.get("v.searchPatient");
        var engagementProgrmaList = component.get("v.engagementProgramList");
        for (var i=0 ; i<engagementProgrmaList.length ; i++) {
            if (engagementProgrmaList[i].engagementProgramCode == searchDetails.engagementProgramCode) {
                var engagementProgramId = engagementProgrmaList[i].programId;
                var manufacturerId = engagementProgrmaList[i].manufacturerId;
                var manuProgramName = engagementProgrmaList[i].manuProgramName;
                var engagementProgramCode = engagementProgrmaList[i].engagementProgramCode;
                component.set("v.searchPatient.engagementProgramId", engagementProgramId);
                component.set("v.searchPatient.manufacturerId", manufacturerId);
                component.set("v.searchPatient.manuProgramName", manuProgramName);
                component.set("v.searchPatient.engagementProgramCode", engagementProgramCode);
            }
        }
        var engagementProgramCode = component.get("v.searchPatient.engagementProgramCode");
        action.setParams({
            "engagementProgramCode": engagementProgramCode
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                var oldMap = component.get("v.searchPatient.fsFields");
                var newMap = returnValue.fsFields;
                for(const key in newMap){
                    if($A.util.isEmpty(newMap[key])){
                        if(!$A.util.isEmpty(oldMap[key])){
                            newMap[key] =  oldMap[key];
                        }
                    }
                }
                component.set("v.searchPatient.fsFields",newMap);
                helper.setFieldSetObject(component, event, helper);
            }else {
                var error = component.get("v.lightingErrorMessage");
                var errors = response.getError();
                    if(!$A.util.isEmpty(errors) && errors.length > 0 && !$A.util.isEmpty(errors[0]['message'])) {
                        error = errors[0]['message'];
                    }
                component.set("v.errors", [error]);
                console.log("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);
    },

    getSearchResultHelper : function(component, event, Helper) {
        var searchDetails = component.get("v.searchPatient");
        var engagementProgrmaList = component.get("v.engagementProgramList");
        component.set("v.isSelected",false);
        component.set("v.showSearchResult",false);
        component.set("v.noMatchFound",false);
        component.set("v.newEnrollmentSelected",false);
        component.set("v.isNewApplicant", false);
        component.set("v.isExistingAccount", false);
        component.set("v.isEnrollingInOtherProgram", false);
        component.set("v.reqCaseId", "");

        for (var i=0 ; i<engagementProgrmaList.length ; i++) {
            if (engagementProgrmaList[i].engagementProgramCode == searchDetails.engagementProgramCode) {
                var engagementProgramId = engagementProgrmaList[i].programId;
                var manufacturerId = engagementProgrmaList[i].manufacturerId;
                var manuProgramName = engagementProgrmaList[i].manuProgramName;
                var engagementProgramCode = engagementProgrmaList[i].engagementProgramCode;
                component.set("v.searchPatient.engagementProgramId", engagementProgramId);
                component.set("v.searchPatient.manufacturerId", manufacturerId);
                component.set("v.searchPatient.manuProgramName", manuProgramName);
                component.set("v.searchPatient.engagementProgramCode", engagementProgramCode);
            }
        }

        searchDetails = component.get("v.searchPatient");
        var searchFields = JSON.stringify(searchDetails);
        var action = component.get("c.getPatients");
        action.setParams({
            "searchDetails": searchFields
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                var returnedResult=returnValue;
                var testMap=returnedResult.childAccAppDetailsMap;
                var accountAppDetailsMap=returnedResult.mapOfPatientsWrapper;
                if (!$A.util.isEmpty(testMap) && !$A.util.isEmpty(accountAppDetailsMap)){
                    var accountAppDetailsArray=[];
                     var accountAppWrapperArray=[];

                    for(var key in testMap){
                        accountAppDetailsArray.push({key:key, value:testMap[key]});
                    }

                    for(var id in accountAppDetailsMap){
                        accountAppWrapperArray.push({key:id, value:accountAppDetailsMap[id]});
                     }

                    component.set("v.columnLabelList",returnedResult.colLabelsList);
                    component.set("v.accountAppDetailsArray",accountAppDetailsArray);
                    component.set("v.accountAppWrapperArray",accountAppWrapperArray);
                    component.set("v.searchFSMap",returnedResult.fsFieldsMap);
                    component.set("v.noMatchFound",false);
                    component.set("v.showSearchResult",true);
                    component.find("resultForm").getElement().scrollIntoView();
                    component.find("searchResultButton").getElement().focus();
                }else {
                    component.set("v.noMatchFound",true);
                    component.set("v.showSearchResult",false);
                }
            }else {
                console.error(response.getError());
                console.log("Failed with state: " + state);
                var error = component.get("v.lightingErrorMessage");
                var errors = response.getError();

                if(!$A.util.isEmpty(errors) && errors.length > 0 && !$A.util.isEmpty(errors[0]['message'])) {
                     error = errors[0]['message'];

                }
                component.set("v.errors", [error]);
            }
        });
        $A.enqueueAction(action);
    },

    setFieldSetObject : function(cmp, event, helper) {

            if (cmp.get("v.fieldSetName") != null) {
                var action = cmp.get("c.getFieldSetFields");
                action.setParams({
                    typeName: cmp.get('v.typeName'),
                    engagementProgramCode : cmp.get("v.searchPatient.engagementProgramCode")
                });
                action.setCallback(this,
                                   function(response) {
                                       var state=response.getState();
                                       if(state=='SUCCESS'){
                                           var returnValue=response.getReturnValue();

                                           cmp.set('v.fieldSetName', returnValue.fieldSetName);
                                           var fields = returnValue.listFieldSetMembers;

                                           var renamedFields = {};
                                           var obj = {};
                                           if(fields != null && fields.length > 0){

                                               helper.setDefaultValueForFieldSetFields(cmp, event, helper, fields);

                                               for (var key in fields) {
                                                   if (fields.hasOwnProperty(key)) {
                                                       obj[fields[key].fieldPath.replace('.','___')] = '';
                                                   }
                                               }
                                               helper.createFieldSetCmp(cmp, event, helper, fields);
                                           }
                                           else {
                                               console.log('No fields found from fieldset');
                                           }

                                       }
                                       else{
                                           console.log('State is failed');
                                       }
                                   }
                                  );
                $A.enqueueAction(action);
            }
        },

    createFieldSetCmp : function(cmp, event, helper, fields) {
            var autofocusFirstField = false;
            if(cmp.get("v.docEngagementProgram") == true || cmp.get("v.docEngagementProgram") == "true") {
                autofocusFirstField = true;
            }
            $A.createComponent(
                cmp.get("v.namespace") + ":PC_FieldSetForm",
                {
                    "fsName": cmp.get("v.fieldSetName"),
                    "typeName": cmp.get("v.typeName"),
                    "record": cmp.getReference("v.searchPatient.fsFields"),
                    "isValid" : cmp.getReference("v.isFieldSetFormValid"),
                    "autofocusFirstField" : autofocusFirstField
                },
                function(newCmp, status, errorMessage){
                    //Add the new button to the body array
                    if (status === "SUCCESS") {
                        //var body = cmp.get("v.fieldSetFormBody");
                        //body.push(newCmp);
                        cmp.set("v.fieldSetFormBody", newCmp);
                        cmp.set("v.fieldSetFields", fields);
                    }
                    else if (status === "INCOMPLETE") {
                        console.log("No response from server or client is offline.")
                    }
                        else if (status === "ERROR") {
                            console.log("Error: " + errorMessage);
                        }
                }
            );
        },



    validateFieldSetForm :function(component) {
        component.set("v.isFieldSetFormValid",true);
        if (component.get("v.fieldSetFormBody") != null) {
            var fieldSetCmp = component.get("v.fieldSetFormBody")[0];
            fieldSetCmp.validate(); // this sets v.isFieldSetFormValid.
        }
        return component.get("v.isFieldSetFormValid");
    },

    setDefaultValueForFieldSetFields : function(cmp, event, helper, fsFields) {


            var persistentAccount = cmp.get("v.searchPatient");
            var currentAccFsFields = persistentAccount.fsFields;

            if($A.util.isEmpty(fsFields) || $A.util.isUndefined(fsFields)) {
                // do nothing
            }
            else {
                var HpField = '';
                for(var i=0; i<fsFields.length; i++) {
                    HpField = fsFields[i].fieldPath;

                    if($A.util.isEmpty(currentAccFsFields[HpField])) {
                       currentAccFsFields[HpField] = '';
                    }
                }
                persistentAccount.fsFields = JSON.parse(JSON.stringify(currentAccFsFields));

                cmp.set("v.searchPatient",persistentAccount);
            }

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

    getFieldSetName : function(component,event,helper) {
        var action = component.get("c.getFieldSetName");

        action.setCallback(this,
           function(response) {
              var state = response.getState();

              if(state=='SUCCESS'){

                    component.set('v.fieldSetName',response.getReturnValue());
              }else{
                  console.log('Error in getting fieldSetName');
              }
           }
          );
        $A.enqueueAction(action);
        },
})