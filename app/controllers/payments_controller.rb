require 'stripe'

class PaymentsController < ApplicationController
    skip_before_action :authenticate_request
    Stripe.api_key = "sk_test_51GqNn2Kj8jVe4aIuNY5sxkfGCrpv5HAPSmMQdzkpJkvnTNYk2LCMQ0TD9jRpG9G8HmwmrUZRiizGcc2sFHaxgeEo00RsFY5nMT"
    state = "5868fb4435bde2653f0621f92e5fdcfb"

    def state
        render json: { state: state }
    end
    
    def secret
        # puts params[:amount]
        # puts params[:amount].gsub(/[,.]/,'').to_i
        puts params[:amount]
        amount = params[:amount].delete(',').to_i
        puts amount
        intent = Stripe::PaymentIntent.create({
            amount: amount,
            currency: 'usd',
            # Verify your integration in this guide by including this parameter
            metadata: {integration_check: 'accept_a_payment'},
          })
        render json: { client_secret: intent.client_secret }
    end

    private
    
    def payment_params

    end
end
