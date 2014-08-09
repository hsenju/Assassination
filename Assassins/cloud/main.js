
// Use Parse.Cloud.define to define as many cloud functions as you want.
// For example:
var _ = require('underscore');

Parse.Cloud.afterSave('Games', function(request) { 
	var emails = request.object.get("members");
	for (var j = 0; j < emails.length-1; ++j) {
		if (j == emails.length -2){
    		var assassin = emails[j];
    		var target = emails[0];
    	}else{
        	var assassin = emails[j];
        	var target = emails[j+1];
		}

        var NewTarget = Parse.Object.extend("Targets");
        var newtarget = new NewTarget();
        newtarget.set("assassin", assassin);
        newtarget.set("target", target);
                
        newtarget.save({
        },{

            success: function() {
                console.log('Successful post.');
            },
            error: function() {
            }
        });  
	}
});