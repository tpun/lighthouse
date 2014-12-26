if (Meteor.isClient) {
  // counter starts at 0
  Session.setDefault("counter", 0);

  Template.hello.helpers({
    counter: function () {
      return Session.get("counter");
    }
  });

  Template.hello.events({
    'click button': function () {
      // increment the counter when button is clicked
      Session.set("counter", Session.get("counter") + 1);
    }
  });
}

if (Meteor.isServer) {
  var observeFirebase = function (url, callback) {
    var firebase = new Firebase(url);
    firebase.on('child_added', Meteor.bindEnvironment(callback));
  };

  Meteor.startup(function () {
    observeFirebase(Meteor.settings.firebase,
                    function (snapshot) {
                      var newDoc = snapshot.val();
                      console.info(newDoc);
                      // Remove processed beacon event
                    });
  });
}
