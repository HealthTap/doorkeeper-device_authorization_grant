require 'net/http'
require 'uri'
require 'json'

class GitBackMerge
  def initialize(source_branch, target_branch, primary_token, secondary_token, slack_webhook_url)
    @source_branch = source_branch
    @target_branch = target_branch
    @primary_token = primary_token
    @secondary_token = secondary_token
    @slack_webhook_url = slack_webhook_url
  end

  def merge_branch
    puts '$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$'
    puts "Source branch => #{@source_branch}"
    puts "Target branch => #{@target_branch}"
    pr_number, pr_link = create_pull_request
    if pr_number.nil?
      pr_number, pr_link = find_pull_request
      existing_pull_request = true
    end
    return if pr_number.nil?
    approve_pull_request(pr_number)
    return if merge_pull_request(pr_number, pr_link)
    return if existing_pull_request
    send_slack_message(pr_link)
  end

  private

  def create_pull_request
    pr  = github_http_call('POST', 'pulls', @primary_token, {
      base:  @target_branch,
      head:  @source_branch,
      title: pull_request_title
    })
    return pr['number'], pr['html_url']
  end

  def find_pull_request
    response  = github_http_call('GET', "pulls?head=HealthTap:#{@source_branch}&base=#{@target_branch}", @primary_token)
    return if response.nil?
    pr = response[0]
    return if pr.nil?
    return pr['number'], pr['html_url']
  end

  def approve_pull_request(pr_number)
    response = github_http_call('GET', "pulls/#{pr_number}/reviews", @primary_token)
    return unless response.nil? || response.size == 0

    github_http_call('POST', "pulls/#{pr_number}/reviews", @secondary_token, {
      event: 'APPROVE',
      body:  'Approved from github  workflow'
    })
  end

  def merge_pull_request(pr_number, pr_link)
    response = github_http_call('PUT', "pulls/#{pr_number}/merge", @secondary_token)
    return response['message'] != 'Pull Request is not mergeable'
  end

  def send_slack_message(pr_link)
    http_call('POST',
      @slack_webhook_url,
      body: {
        text: "Conflict found in pull request from #{@source_branch} to #{@target_branch}: \n#{pr_link}"
      }
    )
  end

  def request_klass(api_type)
    return Net::HTTP::Post if api_type == 'POST'
    return Net::HTTP::Get if api_type == 'GET'
    return Net::HTTP::Put if api_type == 'PUT'
  end

  def http_call(api_type, api_url, body: {}, headers: {})
    uri = URI.parse(api_url)
    request = request_klass(api_type).new(uri)
    headers.each do |k,v|
      request[k] = v
    end
    request.body = JSON.dump(body)
    req_options = {
      use_ssl: uri.scheme == 'https',
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
    raw_response = response.body
    puts '******************************'
    args = {
      api_type: api_type,
      api_url: api_url,
      body: body,
      headers: headers
    }
    puts args
    puts raw_response
    return raw_response
  end

  def github_http_call(api_type, api_path, token, body = {})
    base_url = 'https://api.github.com/repos/HealthTap/doorkeeper-device_authorization_grant'
    headers = {
      'Authorization': "token #{token}",
      'Accept': 'application/vnd.github.v3+json'
    }
    raw_response = http_call(api_type, "#{base_url}/#{api_path}", body: body, headers: headers)
    JSON.parse(raw_response)
  end

  def pull_request_title
    "Automated PR from #{@source_branch} to #{@target_branch}"
  end

end

PRIMARY_TOKEN = ARGV[0]
SECONDARY_TOKEN = ARGV[1]
SLACK_WEBHOOK_URL = ARGV[2]

auto_merge_mappings = {
  master: ['dependabot-fixes']
}
auto_merge_mappings.each do |source_branch, target_branches|
  target_branches.each do |target_branch|
    GitBackMerge.new(
      source_branch, target_branch, PRIMARY_TOKEN,
      SECONDARY_TOKEN, SLACK_WEBHOOK_URL
    ).merge_branch
  end
end
