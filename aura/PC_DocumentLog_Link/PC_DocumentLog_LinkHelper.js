({
	getExcludedObjectsList : function(component, event ) {
        /*
         * [PC-1610]This method retrieves a list of objects to be excluded from linking  
         */
        var action = component.get("c.getExcludedRelatedObjects"); 
        action.setParams({
            accountRecordType : component.get("v.accountRecordType")
        });
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === "SUCCESS") {
                if(component.isValid()) {
                    var objList =  a.getReturnValue();
                    if(objList!=null) //PC-1610
                    {
                        if (objList.length > 0) {
                            for(var i=0; i<objList.length; i++){
                                if (objList[i]=='Account'){
                                    component.set("v.includeAccount", false);
                                } else if (objList[i]=='Case'){
                                    component.set("v.includeCases", false);
                                } else if (objList[i]==component.get('v.adverseEventObjectName')){
                                    component.set("v.includeAdverseEvents", false);
                                } else if (objList[i]=='PC_Interaction__c'){
                                    component.set("v.includeInteractions", false);
                                }else if (objList[i]==component.get('v.adverseEvent2ObjectName')){
                                    component.set("v.includeAdverseEvents2", false);
                                }
                            }                            
                        }
                    }
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
    
    getProgramList : function(component, event, patient) {
        var action = component.get("c.getProgramRecords");
        action.setParams({
            patientId : patient,
            docEngagementProgId: component.get("v.docEngagementProgId")
        });
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === "SUCCESS") {
                if(component.isValid()) {
           			component.set("v.programList", a.getReturnValue());
                    var results = a.getReturnValue();
                    var ids = [];
                    if (results && results.length > 0) {
                        component.set("v.showCaseTable", true);
                        for (var i = 0; i < results.length; i++){
            				ids.push(results[i].Id);
        				}
                        this.getCoverageList(component, event, ids);
                    } 
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
    
    getAccountDetails : function(component, event, patient) {
        var action = component.get("c.getAccountDetails"); //call this method to fetch account details 
        action.setParams({
            accountId : patient
        });
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === "SUCCESS") {
                if(component.isValid()) {
                    var patAcc =  a.getReturnValue();                    
                    component.set("v.account", a.getReturnValue());
                    var name = patAcc.AccFirstName + ' ' + patAcc.AccLastName;
                    component.set("v.patientName", name);
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
    
    getCoverageList : function(component, event, ids) {        
        var action = component.get("c.fetchTrainingRecords");
        action.setParams({
            programId : ids
        });
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === "SUCCESS") {
                if(component.isValid()) {
                    var results = a.getReturnValue();
           			component.set("v.programCoverageMap", results);
                    if (results && results.length > 0) {
                        for (var index = 0; index < results.length; index++) {
                            if (results[index].coverageList && results[index].coverageList.length > 0) {
                                component.set("v.showCoverageTable", true);
                            }
                        }
                    } 
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
    
    removeArrayItem: function(array, itemToRemove) {
        var removeCounter = 0;
        for (var index = 0; index < array.length; index++) {
            if (array[index] === itemToRemove) {
                array.splice(index, 1);
                removeCounter++;
                index--;
            }
        }
    },
    
    getAdverseEventsList : function(component, event, patient) {
        var action = component.get("c.getAdversEventsRecords");
        action.setParams({
            patientId : patient,
            docEngagementProgId: component.get("v.docEngagementProgId")
        });
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === "SUCCESS") {
                if(component.isValid()) {
                    if(component.get('v.adverseEventObjectInUse')==component.get('v.adverseEventObjectName')){
                        component.set("v.adverseEventList", a.getReturnValue());
                    }
                    else{
                        component.set("v.adverseEvent2List", a.getReturnValue());
                    }

                    if (a.getReturnValue() && a.getReturnValue().length > 0) {
                        component.set("v.showAdverseEventTable", true);
                    }
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
    
    getInteractionList : function(component, event, patient) {
        var action = component.get("c.getInteractionRecords");
        action.setParams({
            patientId : patient,
            docEngagementProgId: component.get("v.docEngagementProgId")
        });
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === "SUCCESS") {
                if(component.isValid()) {
           			component.set("v.interactionList", a.getReturnValue());
                    if (a.getReturnValue() && a.getReturnValue().length > 0) {
                        component.set("v.showInteractionTable", true);
                    }
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
    
    
    linkToSelectedAdverseEvents : function(component, event, helper) {
    	var elem = event.getSource().get("v.name");
        var ael = component.get("v.selectedAdverseEventList");
        if (event.getSource().get("v.value")) {
            ael.push(elem);
        } else {
            this.removeArrayItem(ael, elem);
        }
        component.set("v.selectedAdverseEventList", ael);
    },

    linkToSelectedAdverseEvents2 : function(component, event, helper) {
        var elem = event.getSource().get("v.name");
        var ael = component.get("v.selectedAdverseEvent2List");
        if (event.getSource().get("v.value")) {
            ael.push(elem);
        } else {
            this.removeArrayItem(ael, elem);
        }
        component.set("v.selectedAdverseEvent2List", ael);
    },

    linkToSelectedInteractions : function(component, event, helper) {
    	var elem = event.getSource().get("v.name");
        var interactions = component.get("v.selectedInteractionList");
        if (event.getSource().get("v.value")) {
            interactions.push(elem);
        } else {
            this.removeArrayItem(interactions, elem);
        }
        component.set("v.selectedInteractionList", interactions);
    },
    
    linkProgram : function(component, event, helper) {
        var elem = event.getSource().get("v.name");
        var programs = component.get("v.programIds");
        if (event.getSource().get("v.value")) {
            programs.push(elem);
        } else {
            this.removeArrayItem(programs, elem);
        }
        component.set("v.programIds", programs);
    },
   
    linkAccount : function(component, event, helper) {
        var elem = event.getSource().get("v.name");
        if (event.getSource().get("v.value")) {
            component.set("v.accountSelected", elem);
        } else {
            component.set("v.accountSelected", "");
        }        
    },
    
    saveLogs : function(component) {
	    var selectOneRecord = component.get("v.selectOne");

        if ((component.get("v.programIds") === undefined || component.get("v.programIds") == null || component.get("v.programIds").length == 0)
            && 
            (component.get("v.selectedAdverseEventList") === undefined || component.get("v.selectedAdverseEventList") === null || component.get("v.selectedAdverseEventList").length === 0)
            &&
            (component.get("v.selectedAdverseEvent2List") === undefined || component.get("v.selectedAdverseEvent2List") === null || component.get("v.selectedAdverseEvent2List").length === 0)
            && 
            (component.get("v.selectedInteractionList") === undefined || component.get("v.selectedInteractionList") === null || component.get("v.selectedInteractionList").length === 0 )
            &&
            (component.get("v.accountSelected") === undefined || component.get("v.accountSelected") == null ||component.get("v.accountSelected").length == 0)
           ) {
            var toastEvent=$A.get("e.force:showToast");
                toastEvent.setParams({
                    "title":    'Warning',
                    "message":  selectOneRecord,
                    "type":     'warning'
                });
                toastEvent.fire();
            return;
        }
        var coverageMap = component.get("v.programCoverageMap");
        var action = component.get("c.save");
        action.setParams({
            patientId : component.get("v.patientId"),
            documentId : component.get("v.docId"),
            programs : component.get("v.programIds"),
            coverage :  JSON.stringify(coverageMap),
            adverseEvents : component.get("v.selectedAdverseEventList"),
            adverseEvents2 : component.get("v.selectedAdverseEvent2List"),
            interactions : component.get("v.selectedInteractionList"),
            accountSelected : component.get("v.accountSelected")
        });
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === "SUCCESS") {
                if(component.isValid()) {
                    component.set("v.showMessage", true);
                }
            }
            else if (state ==="ERROR"){
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

    getAdverseEventObjectInUse : function(component,event,helper){
        var action = component.get("c.getAdverseEventObjectInUse");
                action.setParams({});
                action.setCallback(this, function(a) {
                    var state = a.getState();
                    if (state === "SUCCESS") {
                        if(component.isValid()) {
                            component.set("v.adverseEventObjectInUse",a.getReturnValue());
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

    }
})