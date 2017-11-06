const functions = require('firebase-functions');

const admin = require('firebase-admin');

admin.initializeApp(functions.config().firebase);
const CUT_OFF_TIME = 3 * 60 * 1000; // approximatelly 21 min

exports.clearUpCheckedOutUsers = functions.https.onRequest((req, res) => {

  	  const updates = {};
	  const refPossiblytable = admin.database().ref('/PossiblyCheckedOut');
      const now = Date.now();
      const cutoff = now - CUT_OFF_TIME;
      const oldItemsQuery = refPossiblytable.orderByChild('timestamp').endAt(cutoff);
      oldItemsQuery.once('value').then(snapshot => {
        // create a map with all children that need to be removed
        snapshot.forEach(child => {
          updates[child.key] = null;
        });
        // execute all updates in one go and return the result to end the function
         refPossiblytable.update(updates);
      });


  	  const refPCheckedIn = admin.database().ref('/CheckedInVenue');
      	return refPCheckedIn.once('value').then(snapshot => {
        return refPCheckedIn.update(updates);
      });
});

exports.sendNotificationsToCheckOutUsers = functions.database.ref('/CheckedInVenue/{pushId}')
    .onDelete(event => {

      const token = event.data.previous.child('pushId').val();
      const venueName = event.data.previous.child('venueName').val();

      sendPushNotifications(token, venueName);

      const newRef = admin.database().ref('/DeletedCheckedusers/'+event.params.pushId);
      var postData = {
    	'timestamp': timestamp,
    	'readableTimeStamp': readableTimeStamp,
    	'timeDeleted': Date.now()
  		};
      return newRef.update(postData);
    });


function sendPushNotifications(token, venueName) {

		// Notification details.
    const payload = {
      notification: {
        title: venueName,
        body: 'Hope to see you soon!',
      }
    };

    const tokens = [token];

    // Send notifications to all tokens.
    return admin.messaging().sendToDevice(tokens, payload).then(response => {
      // For each message check if there was an error.
      const tokensToRemove = [];
      response.results.forEach((result, index) => {
        const error = result.error;
        if (error) {
          console.error('Failure sending notification to', tokens[index], error);
          // Cleanup the tokens who are not registered anymore.
          if (error.code === 'messaging/invalid-registration-token' ||
              error.code === 'messaging/registration-token-not-registered') {
            tokensToRemove.push(tokensSnapshot.ref.child(tokens[index]).remove());
          }
        }
      });
      return Promise.all(tokensToRemove);
    });

};
