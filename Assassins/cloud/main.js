
// Use Parse.Cloud.define to define as many cloud functions as you want.
// For example:
var _ = require('underscore');
var SendGrid = require("sendgrid");  
SendGrid.initialize("Hikari", "KanyeSendgrid");

Parse.Cloud.afterSave('AppKilled', function(request) { 
    var email = request.object.get("email");
    var name = request.object.get("name");

    SendGrid.sendEmail({
        to: email,
        from: "hsenju@gmail.com",
        subject: "Don't kill the app!",
        text: "Yo,\n Since the Assassins mobile game needs to use your bluetooth to work, if your kill the app your target won't be able to find you! If we find that you are killing the app too often, you will be disqualified from this game.\n \n The Assassins Game"
    }, {
        success: function(httpResponse) {
            console.log(httpResponse);
            response.success("Email sent!");
        },
        error: function(httpResponse) {
            console.error(httpResponse);
            response.error("Uh oh, something went wrong");
        }
    });

});

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