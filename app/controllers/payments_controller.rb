require 'stripe'

class PaymentsController < ApplicationController
    skip_before_action :authenticate_request, except: :connect
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
            render json: {error: 'Invalid authorization code: ' + code}, status: 400
        rescue Stripe::StripeError
            render json: {error: 'An unknown error occurred.'}, status: 500
        end

        connected_account_id = response.stripe_user_id
        save_account_id(connected_account_id)

        # Render some HTML or redirect to a different page.
        render json: { success: true }, status: 200
    end

    def save_account_id(connect_id)
        current_user.connect_account_id = connect_id
        current_user.save
    end
    
    def secret
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
