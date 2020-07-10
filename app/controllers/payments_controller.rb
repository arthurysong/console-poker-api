require 'stripe'

class PaymentsController < ApplicationController
    skip_before_action :authenticate_request
    Stripe.api_key = "sk_test_51GqNn2Kj8jVe4aIuNY5sxkfGCrpv5HAPSmMQdzkpJkvnTNYk2LCMQ0TD9jRpG9G8HmwmrUZRiizGcc2sFHaxgeEo00RsFY5nMT"
    

    def state
        render json: { state: ENV['STATE'] }
    end

    def connect
        state = params[:state]
        if state != ENV['STATE']
            render json: { error: 'Invalid state parameter: ' + state }, status: 403
        end

        code = params[:code]
        begin
            response = Stripe::OAuth.token({
            grant_type: 'authorization_code',
            code: code,
            })
        rescue Stripe::OAuth::InvalidGrantError
            status 400
            return {error: 'Invalid authorization code: ' + code}.to_json
        rescue Stripe::StripeError
            status 500
            return {error: 'An unknown error occurred.'}.to_json
        end

        connected_account_id = response.stripe_user_id
        save_account_id(connected_account_id)

        # Render some HTML or redirect to a different page.
        status 200
        {success: true}.to_json
    end

    def save_account_id(id)
        current_user.connect_account_id = id
        current_user.save
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
