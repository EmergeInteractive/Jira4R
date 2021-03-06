require 'rubygems'
require 'soap/wsdlDriver'
require 'xmlrpc/client'
require 'utils'
require 'facets'

module Jira4R
  class JiraTool
    def initialize(host=nil,path=nil,port=nil, default_remote_object = "jira1", wsdl_url=nil)
      @service = XMLRPC::Client.new(host, path, port)
      wsdl_url ||= "http://development.empirestaging.com:9000/rpc/soap/jirasoapservice-v2?wsdl"
      silently(){@soap_service = SOAP::WSDLDriverFactory.new(wsdl_url).create_rpc_driver}
      @default_remote_object = default_remote_object
    end

    def get_fields_for_action(issue_key, action_id)
      soap_service(issue_key, action_id).collect{|row| [row.name, row.id]}.to_h_flat
    end
  
    def get_available_actions(issue_key)
      result = {}
      soap_service(issue_key).each do |row|
        result.store(row.name,row.id)
      end
      result
    end

    def progress_workflow_action(issue_key, action_id, action_params)
      soap_service(issue_key, action_id, action_params)
    end
  
    #string	login(string username, string password) 
    #Logs the user into JIRA.
    def login(username, password)
      @token = call_xmlrpc_remote(username, password)
    end
    
    #boolean	addComment(string token, string issueKey, string comment) 
    #Adds a comment to an issue
    def add_comment(issue_key, comment)
      call_xmlrpc_remote(issue_key, comment)      
    end
  
    #hash	createIssue(string token, hash rIssueStruct) 
    #Creates an issue in JIRA from a Hashtable object.
    def create_issue(issue_hash)
      call_xmlrpc_remote(issue_hash)
    end
    
    #hash	updateIssue(string token, string issueKey, hash fieldValues) 
    #Updates an issue in JIRA from a Hashtable object.
    #This is really a useless method. 
    def update_issue(issue_key, issue_hash = {})
      struct = XMLRPC::Convert.struct(issue_hash)
      pp struct
      call_xmlrpc_remote(issue_key, struct) 
    end
 
    #array	getIssuesFromTextSearchWithProject(string token, array projectKeys, string searchTerms, int maxNumResults) 
    #Find issues using a free text search, limited to certain projects
    def get_issues_from_text_search_with_project(issue_key, project_keys, search_terms, max_num_results)
      call_xmlrpc_remote(issue_key, project_keys, search_terms, max_num_results)
    end

    %w[get_comments get_components get_issues_from_filter get_user get_issue_types_for_project get_sub_task_issue_types_for_project get_issues_from_text_search get_versions get_issue].each do |method|
      self.class_eval %{def #{method}(argument);call_xmlrpc_remote argument; end}
    end
  
    %w[get_favourite_filters get_issue_types get_priorities get_projects_no_schemes get_resolutions get_server_info get_statuses get_subtask_issue_types logout].each do |method|
      self.class_eval %{def #{method}; call_xmlrpc_remote; end}
    end
    
    private
      def soap_service(*args)
        args.insert(0, @token) if @token
        @soap_service.send(Utils.camelized_caller_method, *args)
      end
    
      def call_xmlrpc_remote(*args)
        args.insert(0, @token) if @token
        @service.call("#{@default_remote_object}.#{Utils.camelized_caller_method}", *args)
      end
  end
end

#These are method signatures to use in any future documentation
  #array	getComments(string token, string issueKey) 
  #Returns all comments associated with the issue

  #array	getComponents(string token, string projectKey) 
  #Returns all components available in the specified project

  #array	getIssuesFromFilter(string token, string filterId) 
  #Executes a saved filter

  #hash	getUser(string token, string username) 
  #Returns a user's information given a username

  #array	getIssueTypesForProject(string token, string projectId) 
  #Returns all visible (non-sub task) issue types for the specified project id

  #array	getSubTaskIssueTypesForProject(string token, string projectId) 
  #Returns all visible sub task issue types for the specified project id.

  #array	getIssuesFromTextSearch(string token, string searchTerms) 
  #Find issues using a free text search

  #array	getVersions(string token, string projectKey) 
  #Returns all versions available in the specified project

  #hash	getIssue(string token, string issueKey) 
  #Gets an issue from a given issue key.

  #array	getFavouriteFilters(string token) 
  #Gets all favourite filters available for the currently logged in user

  #array	getIssueTypes(string token) 
  #Returns all visible issue types in the system

  #array	getPriorities(string token) 
  #Returns all priorities in the system

  #array	getProjectsNoSchemes(string token) 
  #Returns a list of projects available to the user

  #array	getResolutions(string token) 
  #Returns all resolutions in the system

  #hash	getServerInfo(string token) 
  #Returns the Server information such as baseUrl, version, edition, buildDate, buildNumber.

  #array	getStatuses(string token) 
  #Returns all statuses in the system

  #array	getSubTaskIssueTypes(string token) 
  #Returns all visible subtask issue types in the system

  #boolean	logout(string token) 
  #Logs the user out of JIRA
