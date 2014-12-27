if (Meteor.isClient) {
  Template.products.helpers({
    products: function () {
      return Products.find();
    }
  });

  Template.product.helpers({
    totalDwellRounded: function () {
      return Math.round(this.totalDwell);
    }
  })
}

if (Meteor.isServer) {
  var observeFirebase = function (url, callback) {
    var firebase = new Firebase(url);
    firebase.on('child_added', Meteor.bindEnvironment(callback));
  };

  Meteor.startup(function () {
    observeFirebase(Meteor.settings.firebase,
                    function (snapshot) {
                      var newEvent = snapshot.val();
                      processBeaconEventsFromFirebase(newEvent);
                      // Remove processed beacon event
                    });
    Product.startup();
  });
}
