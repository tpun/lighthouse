BeaconEvents = new Mongo.Collection('beacon_events');

processBeaconEventsFromFirebase = function (json) {
  BeaconEvents.insert(json);
}

BeaconEvents.findMatchingEnterEvent = function (event) {
  return BeaconEvents.findOne(
    { name: event.name,
      type: 'didEnterRegion',
      visitorUUID: event.visitorUUID,
      createdAt: {$lt: event.createdAt}},
    { sort: {createdAt: -1}});
};
