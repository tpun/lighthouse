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
}
