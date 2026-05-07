({
    getPatient: function(component) {
        var action = component.get("c.getPatientInfo");
        action.setParams({
          "caseId": component.get("v.recordId")
        });
        var patient = null;
        action.setCallback(this, function(a) {
            if(a.getState() ==="SUCCESS") {
                var patient =  a.getReturnValue();
                if(a.getReturnValue() == null){
                    component.set("v.patient", a.getReturnValue());
                    component.set("v.message", component.get('v.errorPatientNotFound'));
                    component.set("v.patientHasAddress", false);
                    var toggleText = component.find("msgResult");
                    $A.util.toggleClass(toggleText, "toggleDisplay");
                    var inputsel = component.find("inputSelectClinics");
                    $A.util.toggleClass(inputsel, "toggleDisplay");
                    return;
                } else if($A.util.isEmpty(patient.BillingLatitude) || $A.util.isEmpty(patient.BillingLongitude)){
                    component.set("v.patient", a.getReturnValue());
                    var mapNotFound = patient.Name + component.get('v.errorMapNotFound');
                    component.set("v.message", mapNotFound);
                    component.set("v.patientHasAddress", false);
                    var msgResult = component.find("msgResult");
                    $A.util.toggleClass(msgResult, "toggleDisplay");
                    var inputSelectClinics = component.find("inputSelectClinics");
                    $A.util.toggleClass(inputSelectClinics, "toggleDisplay");
                    return;
                }
                component.set("v.patient", a.getReturnValue());
            } else if (a.getState() ==="ERROR"){
                var errors = a.getError();
                console.log(JSON.stringify(errors));
                var errText = component.get("v.errorText");
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
    getAvailableClinics: function(component, helper) {
        var patient = component.get("v.patient");
        if(patient != null && component.get("v.patientHasAddress") == true) {
            var action = component.get("c.getMapClinics");
            var inputsel = component.find("inputSelectClinics");
            //$A.util.toggleClass(inputsel, "toggleDisplay");
            var opts=[];
            action.setParams({
                "patient": patient,
                "genericMap": component.get("v.genericMap")});
            action.setCallback(this, function(a) {
                if(a.getState() ==="SUCCESS") {
                    console.log('PC no. of available clinics = ' + a.getReturnValue().length)
                    for(var i=0;i< a.getReturnValue().length;i++){
                        var currentVal = a.getReturnValue()[i];
                        opts.push({"class": "optionClass", label: currentVal.name, value: currentVal.value});
                    }
                    inputsel.set("v.options", opts);
                    this.getAvailableClinicImages(component);
                } else if (a.getState() ==="ERROR"){
                    var errors = a.getError();
                    console.log(JSON.stringify(errors));
                    var errText = component.get("v.errorText");
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
     },
    getDistanceUnit: function(component) {
     var patient = component.get("v.patient");
     if(patient != null && component.get("v.patientHasAddress") == true) {
        var action = component.get("c.isDistanceInKM");
        action.setCallback(this, function(a) {
            if(a.getState() ==="SUCCESS") {
                console.log('PC v.distanceInKm = ' + a.getReturnValue());
                component.set("v.distanceInKm", a.getReturnValue());
            } else if (a.getState() ==="ERROR"){
                var errors = a.getError();
                console.log(JSON.stringify(errors));
                var errText = component.get("v.errorText");
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
    },
    getAvailableClinicImages: function(component) {
        var patient = component.get("v.patient");
        if(patient != null && component.get("v.patientHasAddress") == true) {
            var action = component.get("c.getClinicImagesL");
            action.setParams({
            "patient": patient,
            "radius" : Math.ceil(component.get("v.radius")),
            "genericMap": component.get("v.genericMap"),
            "recordId": component.get("v.recordId"),
            "clincType": component.find("inputSelectClinics").get("v.value"),
            });
            action.setCallback(this, function(a) {
                if(a.getState() ==="SUCCESS") {
                    console.log('v.clinicImages a.getReturnValue() = ' + a.getReturnValue());
                    component.set("v.clinicImages", a.getReturnValue());

                } else if (a.getState() ==="ERROR"){
                    var errors = a.getError();

                    console.log("**************************************");
                    console.log(JSON.stringify(errors));
                    var errText = component.get("v.errorText");
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
    },
    drawMap: function(component) {
        var patient = component.get("v.patient");
        var randomNo = Math.random().toString(); //new Date().toString();
        if(patient != null && component.get("v.patientHasAddress") == true) {

            //var geolocation_lat_field = BillingLatitude;
            var lat = patient.BillingLatitude;

            //var geolocation_lng_field = BillingLongitude;
            var lng = patient.BillingLongitude;
            console.log('PC lat = ' + lat);
            console.log('PC lng = ' + lng);

             if(lat != null && lat != '' && lng != null && lng != '') {
                 var mapAreaElement = component.find("mapArea").getElement();
                 mapAreaElement.innerHTML = "<div id='map" + component.get("v.recordId") + randomNo +"' style='height: 100%; width:100%; margin-top: 0px; margin-bottom:0px'></div>";
                 console.log('innerHTML = '+ mapAreaElement.innerHTML);
                 if (L == 'undefined') { console.log('L undefined !'); }

                var map = new L.map('map' + component.get("v.recordId") + randomNo);
                component.set("v.map", map);
                var zoomMap = component.get("v.zoom");
                map.setView([lat, lng], zoomMap);
            L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
            {
                attribution: 'Patient Connect'
            }).addTo(map);
            var mapBoundNorthEast = map.getBounds().getNorthEast();
            var mapDistance = mapBoundNorthEast.distanceTo(map.getCenter());
            component.set("v.radius", mapDistance/1000);

            map.addEventListener("zoomend", $A.getCallback(function(event) {
                var zoomedMap = map.getZoom();
                component.set("v.zoom",  zoomedMap ) ;
            }));

            var currentAccountIcon = L.icon({
                iconUrl: '/resource/' + component.get('v.namespacePrefix') + 'PC_Resources/PC_Resources/Images/MapImages/arrow.png',
                iconSize: [39,34],
                iconAnchor: [12,34]
            });
            // Add marker
            console.log('Before adding marker lat, lng -> ' + lat + ',' + lng)
            //L.marker([lat, lng], {icon: currentAccountIcon}).addTo(map).bindPopup(patient.Name);
            L.marker([lat, lng], {icon: currentAccountIcon}).addTo(map).bindPopup(this.buildPopupInfoPat(component,patient,patient.Id));
            console.log('PC patient object -> ' + JSON.stringify(patient));
            var action = component.get("c.getNearbyClinics");
                action.setParams({
                    "clincType": component.find("inputSelectClinics").get("v.value"),
                    "patient": patient,
                    "genericMap": component.get("v.genericMap"),
                    "recordId": component.get("v.recordId"),
                    "radius": Math.ceil(mapDistance/1000)
                });
            action.setCallback(this, function(a) {
                if(a.getState() ==="SUCCESS") {
                    var result = a.getReturnValue();
                    console.log('PC Nearbyclinics -> ' + JSON.stringify(result));
                    if(result != null) {

                        var patient_lat;
                        var patient_lng;

                        var result_lat;
                        var result_lng;
                        var geolocation_lat_field = 'BillingLatitude';
                        var geolocation_lng_field = 'BillingLongitude';
                        var mapImage_field = component.get('v.namespacePrefix') + 'PC_Map_Image__c';
                        var interaction_custom_obj = component.get('v.namespacePrefix') + 'PC_Interaction__c';


                        for(var i=0;i< result.length;i++){
                            var distance;
                            var distanceUnit;
                            //console.log('xyz ' + i + result[i]);
                            patient_lat = patient[geolocation_lat_field];
                            patient_lng = patient[geolocation_lng_field];

                            result_lat = result[i][geolocation_lat_field];
                            result_lng = result[i][geolocation_lng_field];
                            console.log(patient_lat + '-' +  '-' +patient_lng +'-' + result_lat +'-' + result_lng);
                            //var distanceInMeters = L.latLng([patient.PCBeta__PC_Geolocation__Latitude__s, patient.PCBeta__PC_Geolocation__Longitude__s]).distanceTo([result[i].PCBeta__PC_Geolocation__Latitude__s, result[i].PCBeta__PC_Geolocation__Longitude__s]);
                            var distanceInMeters = L.latLng([patient_lat, patient_lng]).distanceTo([result_lat, result_lng]);

                            if(component.get("v.distanceInKm")) {
                                distance = ( distanceInMeters / 1000 ).toFixed(2);
                                distanceUnit = component.get("v.distanceUnitInKm");
                            }
                            else {
                                distance = ( distanceInMeters * 0.00062137 ).toFixed(2);
                                distanceUnit = component.get("v.distanceUnitInMiles");
                            }
                            var icon = L.icon({
                                iconUrl: '/resource/' + component.get('v.namespacePrefix') + 'PC_Resources/PC_Resources/Images/MapImages/'+ result[i][mapImage_field],
                                iconSize: [32,32],
                                iconAnchor: [16,32]
                            });
                            var marker = L.marker([result[i][geolocation_lat_field], result[i][geolocation_lng_field]], {icon: icon});
                            marker.Id = result[i].Id;
                            marker.addTo(map).bindPopup(this.buildPopupInfo(component,result[i], distanceUnit, distance, marker.Id));
                        }
                        map.on('popupopen', function(e) {
                            var markerInPopup = e.popup._source;
                            var button = e.popup._source.getPopup()._contentNode.querySelector(".LMapPopUpContentButton");
                            if(button != null) {
                            button.addEventListener("click", function(){
                                var createRecordEvent = $A.get("e.force:createRecord");
                                if(component.get("v.genericMap") == false){
                                    /*
                                    Logic to populate the Pharmacy triage workflow map
                                    */
                                    var params = {
                                        "entityApiName": component.get("v.namespacePrefix") + "PC_Pharmacy_Referral__c",
                                        "defaultFieldValues" : {
                                        }
                                    }

                                    var pharmacy = component.get("v.namespacePrefix") + "PC_Target_Pharmacy__c" ;
                                    var program = component.get("v.namespacePrefix") + "PC_Program__c" ;
                                    var account = component.get("v.namespacePrefix") + "PC_Patient__c" ;
                                    params["defaultFieldValues"][pharmacy] = markerInPopup.Id;
                                    params["defaultFieldValues"][program] = component.get("v.recordId");
                                    params["defaultFieldValues"][account] = component.get("v.patient").Id;
                                    createRecordEvent.setParams(params);
                                    createRecordEvent.fire();

                                }
                                else{
                                    var recordId = component.get("v.recordId");
                                    var namespace = component.get("v.namespace");
                                    var componentAPIName =  namespace+'__'+component.get("v.interactionParticipantCmpName");
                                    var workspaceAPI = component.find("mapWorkspace");
                                    var caseId = CH_PC_Util.getQualifiedQueryParam(component,'caseId',namespace);
                                    var selectedLocation = CH_PC_Util.getQualifiedQueryParam(component,'selectedLocation',namespace);
                                    var tabUID = 'PatientMap-' + markerInPopup.Id;
                                    var tabParamsObject = new Object();
                                    tabParamsObject.uid = tabUID;
                                    tabParamsObject[caseId] = recordId;
                                    tabParamsObject[selectedLocation] = markerInPopup.Id;
                                    var urlParams = '?'+caseId+'='+recordId+'&'+selectedLocation+'='+markerInPopup.Id;
                                    workspaceAPI.isConsoleNavigation().then(function(isConsole) {
                                        if (isConsole) {
                                            // this block of code helps to open the component in new console tab if it is console app
                                            CH_PC_Util.openLightningComponentInNewTab(workspaceAPI,componentAPIName,'',tabParamsObject,
                                                    component.get("v.bookAppointmentTabLabel"),'utility:adduser',true,urlParams);
                                        } else {
                                            // this block of code helps to open the component in new tab if it is lightning app
                                            var url = '/lightning/cmp/' + componentAPIName + urlParams;
                                            window.open(url,"_blank");
                                        }
                                    })
                                    .catch(function(error) {
                                        console.log(error);
                                    });
                                }
                            }, false);
                            }
                        });
                    }
                } else if (a.getState() ==="ERROR"){
                    var errors = a.getError();
                    console.log(JSON.stringify(errors));
                    var errText = component.get("v.errorText");
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
       }
    },
    buildEvent : function() {
        var createRecordEvent = $A.get("e.force:createRecord");
        var interaction_custom_obj = component.get('v.namespacePrefix') + 'PC_Interaction__c';
            createRecordEvent.setParams({
             "entityApiName": interaction_custom_obj
            });
        createRecordEvent.fire();
    },
    buildPopupInfo : function(component, acc, distanceUnit, distance, markerId) {
        var primary_address_rel = component.get('v.namespacePrefix') + 'PC_Primary_Address__r';
        var complete_address_field = component.get('v.namespacePrefix') + 'PC_Complete_Address__c';
        //var phone_field = component.get('v.namespacePrefix') + 'Phone';
        var hours_field = component.get('v.namespacePrefix') + 'PC_Hours__c';
        var features_field = component.get('v.namespacePrefix') + 'PC_Features__c';
        var popupLabel;
        //Display different button titles based on where the map is being launched from //PC-2014
        if(component.get("v.genericMap")){
            popupLabel = component.get('v.labelBookAppt');
        }else{
            popupLabel = component.get('v.labelSelect');
        }

        console.log('PC in buildpopupinfo acc = ' + JSON.stringify(acc));
        //console.log(acc[primary_address_rel][complete_address_field] +
        //            '--' + acc[primary_address_rel][phone_field]
        //            + '--' + acc[phone_field])
        var address = acc[primary_address_rel][complete_address_field] == undefined ? '' :  acc[primary_address_rel][complete_address_field];
        var phone =  acc.Phone == undefined ? '' : acc.Phone;
        var hours = acc[hours_field] == undefined ? '' : acc[hours_field];
        var features = acc[features_field] == undefined ? '' : acc[features_field];
        var popupFields = component.get('v.popupFields');
        var popupUI = '<div  style="line-height: 1.35; overflow: hidden;"/>' +
                      '<h3>' + acc.Name +'</h3>' +
                      '<table border="0" cellpadding="0" cellspacing="0" >' +
                      '<tr>' + '<th scope="row">' + popupFields.address + ':'+ '</th>' +
                      '<td>' + '&nbsp;' +address+'</td>' +
                      '</tr>' +
                      '<tr>' + '<th scope="row">' + popupFields.phone + ':' + '</th>' +
                      '<td>' + '&nbsp;' + phone + '</td>' +
                      '</tr>' +
                      '<tr>' + '<th scope="row">'+popupFields.openhours+':'+'</th>' +
                      '<td>' + '&nbsp;' + hours + '</td>' +
                      '</tr>' +
                      '<tr>' +
                      '<th scope="row">'+popupFields.feature+':'+' </th>' +
                      '<td>' + '&nbsp;' + features + '</td>' +
                      '</tr>' +
                      '<tr>' + '<th scope="row">'+popupFields.distance+ '(' + distanceUnit + '): </th>' +
                      '<td>' + '&nbsp;' + distance + '</td>' +
                      '</tr>' +
                      '</table>' +
                      '<div >' +
                      '<input type="button" value="'+popupLabel+'" id="btn'+markerId+'" ' +
                      'class="LMapPopUpContentButton"></input>' +
                      '</div>'
        return popupUI;
    },
    buildPopupInfoPat : function(component, acc, markerId) {
        var primary_address_rel = component.get('v.namespacePrefix') + 'PC_Primary_Address__r';
        var complete_address_field = component.get('v.namespacePrefix') + 'PC_Complete_Address__c';
        var popupFields = component.get('v.popupFields');
        var address = acc[primary_address_rel][complete_address_field] == undefined ? '' :  acc[primary_address_rel][complete_address_field];
        var popupLabel = component.get('v.labelHomeAppt');
        var popupUI;

        console.log('PC in buildpopupinfo acc = ' + JSON.stringify(acc));
        if(component.get("v.genericMap")){
        popupUI = '<div  style="line-height: 1.35; overflow: hidden;"/>' +
                      '<h3>' + acc.Name +'</h3>' +
                      '<table border="0" cellpadding="0" cellspacing="0" >' +
                      '</table>' +
            		  '<tr>' + '<th scope="row">' + popupFields.address + ':'+ '</th>' +
                      '<td>' + '&nbsp;' +address+'</td>' +
                      '</tr>' +
                      '<div >' +
                      '<input type="button" value="'+popupLabel+'" id="btn'+markerId+'" ' +
                      'class="LMapPopUpContentButton"></input>' +
                      '</div>'
        } else {
           popupUI =  '<div  style="line-height: 1.35; overflow: hidden;"/>' +
                      '<h3>' + acc.Name +'</h3>'
        }
        return popupUI;
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
    getFieldLabels : function(component){
        var action = component.get("c.getFieldLabels");
        action.setCallback(this, function(a) {
            if(a.getState() ==="SUCCESS") {
                var fieldLabels =  a.getReturnValue();
                component.set("v.popupFields", fieldLabels);
            } else if (a.getState() ==="ERROR"){
                var errors = a.getError();
                console.log(JSON.stringify(errors));
                var errText = component.get("v.errorText");
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
    /*getQualifiedAPIName : function(objectName) {
           return component.get("v.namespacePrefix") + objectName;
    }*/

})