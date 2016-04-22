Rails.application.routes.draw do

  match :fb_webhook, to: 'conversations#inbound_message', via: [:get, :post]

end
