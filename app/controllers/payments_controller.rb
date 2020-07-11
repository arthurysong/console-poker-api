require 'stripe'

class PaymentsController < ApplicationController
    skip_before_action :authenticate_request, except: [:connect, :transfer_secret]
    Stripe.api_key = ENV['STRIPE_KEY']

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
        user = current_user
        save_account_id(connected_account_id, user)

        # Render some HTML or redirect to a different page.
        render json: { success: true, user: user }, status: 200
    end

    def save_account_id(connect_id, user)
        user.connect_account_id = connect_id
        user.save
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

    def transfer_secret
        amount = params[:amount].delete(',').to_i
        user = current_user
        # puts amount
        # puts user.username

        chips = amount * 100

        if user.chips < chips
            render json: { error: "User does not have enough chips" }, status: 400
        else 
            user.chips -= chips
            user.save
            transfer = Stripe::Transfer.create({
                amount: amount,
                currency: "usd",
                destination: user.connect_account_id
            })

            render json: { success: true, message: "#{chips} chips exchanged! USD amount will be transferred to debit/bank.", user: user }
        end
    end

    private
    
    def payment_params

    end
end
