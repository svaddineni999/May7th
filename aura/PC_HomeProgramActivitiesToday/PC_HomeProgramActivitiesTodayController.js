({
	doInit : function(component, event, helper) {
        var action = component.get("c.getTodaysActivities");
        action.setCallback(this, function(a) {
            var state = a.getState();

            if (component.isValid() && state === "SUCCESS") {
                try {
                    component.set("v.totalCount", a.getReturnValue());
                    var bar = new ProgressBar.Line(lineActivities, {
                        strokeWidth: 8,
                        easing: 'easeInOut',
                        duration: 1400,
                        color: '#FFEA82',
                        trailColor: '#eee',
                        trailWidth: 4,
                        svgStyle: {width: '100%', height: '100%'},
                        from: {color: '#FFEA82'},
                        to: {color: '#01A1DF'},
                        step: (state, bar) => {
                            bar.path.setAttribute('stroke', state.color);
                        }
					});
                    bar.animate(a.getReturnValue().completedPercentage);
				} catch(err) {
                	console.log('Error Today Activities: ' + err.message);
                    console.log(err);
                }
            } else if (component.isValid() && state === "INCOMPLETE") {
				console.log("State Incomplete");
            } else if (component.isValid() && state === "ERROR") {
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
                //helper.throwErrorHelper(component);
            }
        });
        $A.enqueueAction(action);
    }
})