if (Meteor.isClient) {
  Template.products.helpers({
    products: function () {
      return Products.find();
    }
  });

  Template.product.helpers({
    totalDwellRounded: function () {
      if (this.totalDwell) {
        return Math.round(this.totalDwell);
      }
    }
  });

  Template.reset.events({
    'click button': function () {
      Meteor.call('resetDatabase');
    }
  });

  Template.beaconEvents.helpers({
    beaconEvents: function (n) {
      return BeaconEvents.find({},{sort: {createdAt:-1}, limit:n});
    }
  })
}

if (Meteor.isServer) {
  var observeFirebase = function (url, callback) {
    var firebase = new Firebase(url);
    firebase.on('child_added', Meteor.bindEnvironment(callback));
  };

  var removeFromFirebase = function (ref) {
    var firebase = new Firebase(ref);
    firebase.remove();
  }

  Meteor.startup(function () {
    observeFirebase(Meteor.settings.firebase,
                    function (snapshot) {
                      var newEvent = snapshot.val();
                      processBeaconEventsFromFirebase(newEvent);
                      removeFromFirebase(snapshot.ref().toString());
                    });
    Product.startup();
  });

  Meteor.methods({
    resetDatabase: function () {
      this.unblock();
      BeaconEvents.remove({});
      Products.remove({});
      console.info('Reseted database');
    }
  });
}
