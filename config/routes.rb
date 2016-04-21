Rails.application.routes.draw do

  post :fb_webhook, to: 'conversations_controller#inbound_message'

end
