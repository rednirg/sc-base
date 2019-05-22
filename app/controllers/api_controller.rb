class ApiController < ApplicationController
	before_action :authentication_check

	private

	def authentication_check
		if !(ENV["AUTH"].to_s == "" || ENV["AUTH"].to_s.downcase == "false")
			if ENV["AUTH"].to_s.downcase == "billing" && (controller_name == "stores" || controller_name == "payments")
				case action_name
				when "payments"
					doorkeeper_authorize! :admin
				when "buy", "paid"
					puts "===SPECIAL HANDLING FOR COMMERCIAL DATA==="
				when "index", "plain", "full", "provision"
					if !doorkeeper_token.nil? && doorkeeper_token.application_id.to_s != ""
						@oauth = Doorkeeper::Application.find(doorkeeper_token.application_id)
						if !@oauth.nil?
							if @oauth.name != "master"
								@bil = Billing.find_by_uid(@oauth.name)
								if !@bil.nil?
									if request.query_string.downcase != @bil.request.downcase
										render json: {"error": "invalid request"},
											   status: 403
									end
								else
									render json: {"error": "unauthorized request (invalid uid)"},
										   status: 403
								end
							end
						else
							render json: {"error": "unauthorized request (invalid token)"},
								   status: 403
						end
					end
				else
					if action_name != "active" && action_name != "init"
						if action_name == "write"
							doorkeeper_authorize! :write, :admin
						else
							doorkeeper_authorize! :read, :write, :admin
						end
					end
				end
			else
				if action_name != "active" && action_name != "init"
					if action_name == "write"
						doorkeeper_authorize! :write, :admin
					else
						doorkeeper_authorize! :read, :write, :admin
					end
				end
			end
		end
	end
end