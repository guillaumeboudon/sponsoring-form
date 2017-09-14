'use strict';

require('./index.html');

var Elm = require('./StripeSubscription.elm');
var app = Elm.StripeSubscription.embed(document.getElementById('main'));

Stripe.setPublishableKey('pk_test_5PnH5aLwZzbYlDjsGijmGhGz')
app.ports.askForToken.subscribe((creditCardModel) => {
  Stripe.card.createToken({
    number: creditCardModel.ccNumber,
    cvc: creditCardModel.cvc,
    exp: creditCardModel.expiration
  }, stripeResponseHandler)
})

function stripeResponseHandler(status, response){
  console.log("got stripe data back!")
  console.log("status", status)
  console.log("response", response)
  app.ports.receiveStripeToken.send(response.id)
}
