require 'json'
require 'rest-client'

class PuppetdbInterface
  attr_accessor :app_name, :rails_env, :git_repo, :host

  def initialize(app_name, rails_env, git_repo, host)
    @app_name = app_name
    @rails_env = rails_env.to_s
    @git_repo = git_repo
    @brand = brand
    @host = host
  end

  # TODO: We need a better query constructor instead of a hardcoded string
  def construct_request
    query_params = 'query=["and", ["=", ["parameter", "rails_env"], "'+ @rails_env +'"], ["=", ["parameter", "git_repo"], "'+ @git_repo +'"]]'
    @host + URI::encode(query_params)
  end

  def get_response request_string
    response = RestClient.get(request_string,
      {:accept => :json} ){ |response, request, result, &block|
      case response.code
      when 200
        response
      when 400
        raise "BAD REQUEST"
      else
        response.return!(request, result, &block)
      end
    }
    return response
  end  

  # Given a Rails environment, and a Git repository string, this method queries the puppetdb server to get a list of servers.
  # The list of servers can then be set in Capistrano as the nodes to deploy to 
  def get_servers
    request_string = construct_request
    response = get_response request_string
    json  = JSON.parse response.body
    servers = json.collect{|piece| piece["certname"]}.uniq.sort
    if servers.empty?
      raise "\n****************************\nTHERE IS NO SERVER TO DEPLOY TO, CHECK YOUR PUPPET SITE.PP\n**************************"
    end
    return servers
  end
end
