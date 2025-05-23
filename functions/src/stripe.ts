import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import Stripe from 'stripe';

// Initialize Firebase Admin SDK if not already initialized
if (admin.apps.length === 0) {
  admin.initializeApp();
}

// TODO: Replace XXXAPIKEY with your Stripe secret key stored in Firebase environment variables.
// Example: functions.config().stripe.secret_key
// For security reasons, do not deploy with a hardcoded key.
const stripe = new Stripe('XXXAPIKEY', {
  apiVersion: '2024-06-20', // Specify a Stripe API version
});

export const createPaymentIntent = functions.https.onCall(async (data, context) => {
  // Log the received amount for debugging
  console.log('Received amount:', data.amount);
  console.log('Received currency:', data.currency);

  // Ensure the user is authenticated, if necessary for your use case
  // if (!context.auth) {
  //   throw new functions.https.HttpsError(
  //     'unauthenticated',
  //     'The function must be called while authenticated.'
  //   );
  // }

  const { amount, currency } = data;

  // Validate data
  if (!amount || typeof amount !== 'number' || amount <= 0) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'The function must be called with a valid "amount" (positive number).'
    );
  }

  if (currency !== 'jpy') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'The function currently only supports "jpy" currency.'
    );
  }

  try {
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount,
      currency: 'jpy', // Ensure currency is 'jpy'
      payment_method_types: ['card'],
    });

    console.log('PaymentIntent created:', paymentIntent.id);

    return {
      clientSecret: paymentIntent.client_secret,
    };
  } catch (error) {
    console.error('Error creating PaymentIntent:', error);
    let errorMessage = 'An unknown error occurred.';
    if (error instanceof Error) {
        errorMessage = error.message;
    }
    throw new functions.https.HttpsError(
        'internal',
        `Failed to create PaymentIntent: ${errorMessage}`
    );
  }
});
