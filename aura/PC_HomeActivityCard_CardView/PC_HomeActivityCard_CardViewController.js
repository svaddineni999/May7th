/**
 * Created by vkashikar on 9/11/2017.
 */
({
    doInit : function(component, event, helper) {
       // helper.getStarredActivities(component);
       // helper.getOverDueActivities(component);
       // helper.getTodayDueActivities(component);
       // helper.getTomorrowDueActivities(component);
        //helper.getFormContent(component, candidatePatientId);

        var today = new Date();
        var monthDigit = today.getMonth() + 1;
        if (monthDigit <= 9) {
            monthDigit = '0' + monthDigit;
        }
            console.log('1-----'+today.getFullYear());
        console.log('2-----'+monthDigit);
        console.log('3-----'+today.getDate());

        component.set('v.today', monthDigit + "/" + today.getDate() + "/" + today.getFullYear());
        /*
        var mainDiv = component.find('main-div-body');
        $A.util.removeClass(mainDiv, 'wrapper-body');
        $A.util.addClass(mainDiv, 'hide-wrapper-body');
        */
        var task = component.get("v.objTask");
        if(task.svgIconName == 'fax') {
            task.svgIconName = 'task';
        }
    },
	starActivity : function (component, event, helper) {
		console.log('In Controller');
        helper.starActivity(component);
    },
    navigateToRecord : function(component, event, helper) {
    	var context = component.get("v.usersContext");
        var objTask  = component.get("v.objTask");
        var rid = objTask.relatedToRecordID;
        if(context != undefined) {
        	if(context == 'Theme4t' || context == 'Theme4d') {
                sforce.one.navigateToSObject(rid);
            } else {
            	console.log('VF in Classic');
                //window.location.assign('/'+rid);
                window.open('/' + rid);
			}
		} else {
			var navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
            	"recordId": rid,
                "slideDevName": "related"
            });
            navEvt.fire();
    	}
    },
    navigateToAccountRecord: function(component, event, helper) {
        //AccountId

            var context = component.get("v.usersContext");
            var objTask  = component.get("v.objTask");
               var rid = objTask.patientID;
               console.log('=====Case Id===='+objTask.relatedToRecordID);
                 console.log('=====Task Id===='+objTask.taskID);
                   console.log('=====Account Id===='+objTask.patientID);

               if(context != undefined) {
                if(context == 'Theme4t' || context == 'Theme4d') {
                       sforce.one.navigateToSObject(rid);
                   } else {
                    console.log('VF in Classic');
                       //window.location.assign('/'+rid);
                       window.open('/' + rid);
                }
            } else {
                var navEvt = $A.get("e.force:navigateToSObject");
                   navEvt.setParams({
                    "recordId": rid,
                       "slideDevName": "related"
                   });
                   navEvt.fire();
            }
   },
   navigateToTask: function(component, event, helper) {
           //AccountId
           debugger;
               var context = component.get("v.usersContext");
               var objTask  = component.get("v.objTask");
                  var rid = objTask.taskID;
                    console.log('=====Task Id===='+objTask.taskID);

                  if(context != undefined) {
                   if(context == 'Theme4t' || context == 'Theme4d') {
                          sforce.one.navigateToSObject(rid);
                      } else {
                       console.log('VF in Classic');
                          //window.location.assign('/'+rid);
                          window.open('/' + rid);
                   }
               } else {
                   var navEvt = $A.get("e.force:navigateToSObject");
                      navEvt.setParams({
                       "recordId": rid,
                          "slideDevName": "related"
                      });
                      navEvt.fire();
               }
      },

    handleClick: function(component, event, helper) {

           var mainDiv = component.find('main-div');
           $A.util.addClass(mainDiv, 'slds-is-open');
         },

     handleMouseLeave: function(component, event, helper) {
       component.set("v.dropdownOver",false);
       var mainDiv = component.find('main-div');
       $A.util.removeClass(mainDiv, 'slds-is-open');
     },

     handleMouseEnter: function(component, event, helper) {
       component.set("v.dropdownOver",true);
     },

     handleMouseOutButton: function(component, event, helper) {
       window.setTimeout(
         $A.getCallback(function() {
           if (component.isValid()) {
             //if dropdown over, user has hovered over the dropdown, so don't close.
             if (component.get("v.dropdownOver")) {
               return;
             }
             var mainDiv = component.find('main-div');
             $A.util.removeClass(mainDiv, 'slds-is-open');
           }
         }), 200
       );
     },
     showDueDateList: function(component, event, helper){
         console.log('==========Show Due Date List');
     },
     markCompleteAction: function(component, event, helper){
         debugger;
           component.set("v.dropdownOver",false);
           var mainDiv = component.find('main-div');
           $A.util.removeClass(mainDiv, 'slds-is-open');

           $A.util.addClass(mainDiv, 'hideDivPartial');
           helper.markCompleteActivity(component, helper);
      },

     markHighPriorityAction: function(component, event, helper){
           component.set("v.dropdownOver",false);
           var mainDiv = component.find('main-div');
           $A.util.removeClass(mainDiv, 'slds-is-open');

            debugger;
           helper.markHighPriorityActivity(component, helper);

      },
      markDismissAction: function(component, event, helper){
          debugger;
          component.set("v.dropdownOver",false);
         var mainDiv = component.find('main-div');
         $A.util.removeClass(mainDiv, 'slds-is-open');

         $A.util.addClass(mainDiv, 'hideDivPartial');
         helper.markDismissActivity(component, helper);
      },

      navigateToOwner : function(component, event, helper) {
          debugger;
        var context = component.get("v.usersContext");
         var objTask  = component.get("v.objTask");
         var rid = objTask.taskOwnerId;
         if(context != undefined) {
            if(context == 'Theme4t' || context == 'Theme4d') {
                 sforce.one.navigateToSObject(rid);
             } else {
                console.log('VF in Classic');
                 //window.location.assign('/'+rid);
                 window.open('/' + rid);
            }
        } else {
            var navEvt = $A.get("e.force:navigateToSObject");
             navEvt.setParams({
                "recordId": rid,
                 "slideDevName": "related"
             });
             navEvt.fire();
        }
     }
})