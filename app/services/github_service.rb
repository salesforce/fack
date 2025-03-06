require 'net/http'
require 'json'

class GithubService
  BASE_URL = 'https://api.github.com'

  def initialize(user)
    @token = user.github_authorization.token
  end

  def last_commits(owner, repo, limit = 10)
    uri = URI("#{BASE_URL}/repos/#{owner}/#{repo}/commits?per_page=#{limit}")
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "token #{@token}"
    request['User-Agent'] = 'RailsApp'

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    JSON.parse(response.body)
  end

  def user_repos
    uri = URI("#{BASE_URL}/user/repos")
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "token #{@token}"
    request['User-Agent'] = 'RailsApp'

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    JSON.parse(response.body)
  end
end
