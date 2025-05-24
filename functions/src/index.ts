// if (
// 	!process.env.FUNCTION_TARGET ||
// 	process.env.FUNCTION_TARGET === FUNCTIONS.scheduleMidnight
// ) {
// 	exports.scheduleMidnight = handler.scheduleMidnight;
// }

import { createPaymentIntent } from './stripe';

// Export the function to make it available to Firebase
// The name you give here (e.g., "createPaymentIntent") is how it will be identified in Firebase Functions.
exports.createPaymentIntent = createPaymentIntent;
