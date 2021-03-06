require 'redmine/access_control'
require 'redmine/menu_manager'
require 'redmine/activity'
require 'redmine/mime_type'
require 'redmine/core_ext'
require 'redmine/themes'
require 'redmine/plugin'
require 'redmine/wiki_formatting'
require 'float' #todo: there's a more appropriate place for this
require 'string'
require 'mention'

begin
  require_library_or_gem 'RMagick' unless Object.const_defined?(:Magick)
rescue LoadError
  # RMagick is not available
end

if RUBY_VERSION < '1.9'
  require 'faster_csv'
else
  require 'csv'
  FCSV = CSV
end

REDMINE_SUPPORTED_SCM = %w( Subversion Darcs Mercurial Cvs Bazaar Git Filesystem )



# Permissions
Redmine::AccessControl.map do |map|
  map.permission :view_project, {:projects => [:overview, :activity, :team, :shares, :map, :activity, :mypris, :community_members, :hourly_types, :all_tags]}, :public => true
  map.permission :search_project, {:search => :index}, :public => true
  map.permission :add_project, {:projects => [:add, :new, :copy]}, :require => :loggedin
  map.permission :add_subprojects, {:projects => [:add, :new]}, :require => :loggedin
  map.permission :edit_project, {:projects => [:settings, :edit, :copy, :archive, :unarchive, :destroy, :update_scale]}, :require => :member
  map.permission :move_project, {:projects => [:move]}, :require => :member
  map.permission :select_project_modules, {:projects => :modules}, :require => :member
  map.permission :manage_members, {:projects => :settings, :members => [:new, :edit, :destroy, :autocomplete_for_member]}, :require => :member
  map.permission :credits, {:credits => [:add, :edit, :update]}, :require => :admin
  map.permission :send_invitations, {:invitations => [:new, :create, :resend, :index], :projects => [:reset_invitation_token]}, :require => :loggedin
  map.permission :manage_invitations, {:invitations => [:index, :show, :edit, :destroy, :resend, :update]}, :require => :loggedin
  map.permission :transfer_credits, {:credit_transfers => [:index, :create]}, :require => :loggedin
  map.permission :join_from_generic_invitation, {:projects => :join}, :require => :loggedin
  map.project_module :issue_tracking do |map|
    # Issues
    map.permission :view_issues, {:projects => :roadmap,
                                  :issues => [:index, :changes, :show, :context_menu, :datadump],
                                  :queries => :index,
                                  :reports => :issue_report,
                                  :comments => :index,
                                  :todos => :index,
                                  :retros => [:index, :index_json, :dashdata, :show],
                                  :projects => [:dashboard,:community_members, :dashdata, :new_dashdata]
                                  }

    map.permission :add_issues, {:issues => [:new, :update_form]}
    map.permission :edit_issues, {:issues => [:edit, :reply, :bulk_edit, :update_form, :cancel, :restart, :prioritize, :agree, :disagree, :estimate, :join, :leave, :add_team_member, :remove_team_member, :update_tags]}
    map.permission :manage_issue_relations, {:issue_relations => [:new, :destroy]}
    map.permission :add_issue_notes, {:issues => [:reply], :comments => :create, :todos => [:create,:update,:destroy]}
    map.permission :edit_issue_notes, {:journals => :edit}, :require => :loggedin
    map.permission :edit_own_issue_notes, {:journals => :edit}, :require => :loggedin
    map.permission :move_issues, {:issues => :move}, :require => :loggedin
    map.permission :delete_issues, {:issues => :destroy}, :require => :member
    map.permission :push_commitment, {:issues => [:assign]} #Can send request for someone to comitt to a task
    map.permission :pull_commitment, {:issues => [:assign]} #Can pull request. i.e. ask to be the person that the task is commited to.
    map.permission :view_commit_requests, {:commit_requests => [:edit, :show]} #Can view ownereship requests
    map.permission :view_member_roles, {:member_roles => [:show]} #Can view member roles
    map.permission :estimate_issues, {:issues => :estimate}, :public => true #Can estimate issue
    map.permission :accept_issues, {:issues => [:accept, :reject]}, :public => true #can accept or reject issues
    map.permission :start_issues, {:issues => [:start,:finish,:release], :retro_ratings => :create} #can start issues
    # Queries
    map.permission :manage_public_queries, {:queries => [:new, :edit, :destroy]}, :require => :member
    map.permission :save_queries, {:queries => [:new, :edit, :destroy]}, :require => :loggedin
    # Gantt & calendar
    map.permission :view_gantt, :issues => :gantt
    map.permission :view_calendar, :issues => :calendar
    # Watchers
    map.permission :view_issue_watchers, {}
    map.permission :add_issue_watchers, {:watchers => :new}
    map.permission :delete_issue_watchers, {:watchers => :destroy}
  end

  map.project_module :documents do |map|
    map.permission :manage_documents, {:documents => [:new, :edit, :destroy, :add_attachment]}, :require => :loggedin
    map.permission :view_documents, :documents => [:index, :show, :download]
    map.permission :manage_files, {:projects => :add_file}, :require => :loggedin
    map.permission :view_files, :projects => :list_files
  end

  map.project_module :wiki do |map|
    map.permission :manage_wiki, {:wikis => [:edit, :destroy]}, :require => :member
    map.permission :rename_wiki_pages, {:wiki => :rename}, :require => :member
    map.permission :delete_wiki_pages, {:wiki => :destroy}, :require => :member
    map.permission :view_wiki_pages, :wiki => [:index, :special]
    map.permission :view_wiki_edits, :wiki => [:history, :diff, :annotate]
    map.permission :edit_wiki_pages, :wiki => [:edit, :preview, :add_attachment]
    map.permission :delete_wiki_pages_attachments, {}
    map.permission :protect_wiki_pages, {:wiki => :protect}, :require => :member
  end

  map.project_module :boards do |map|
    map.permission :manage_boards, {:boards => [:new, :edit, :destroy]}, :require => :member
    map.permission :view_messages, {:boards => [:index, :show], :messages => [:show]}, :public => true
    map.permission :add_messages, {:messages => [:new, :reply, :quote]}
    map.permission :edit_messages, {:messages => :edit}, :require => :member
    map.permission :edit_own_messages, {:messages => :edit}, :require => :loggedin
    map.permission :delete_messages, {:messages => :destroy}, :require => :member
    map.permission :delete_own_messages, {:messages => :destroy}, :require => :loggedin
  end

  map.project_module :motions do |map|
    map.permission :manage_motion, {:motions => [:edit, :destroy]}, :require => :admin
    map.permission :browse_motion, {:motions => [:index, :view, :show]}, :require => :loggedin
    map.permission :create_motion, {:motions => [:create, :new, :eligible_users]}, :require => :loggedin
    map.permission :vote_motion, {:motions => :reply, :motion_vote => :create}, :require => :loggedin
  end

  map.project_module :news do |map|
    map.permission :manage_news, {:news => [:new, :edit, :destroy, :destroy_comment]}, :require => :member
    map.permission :view_news, {:news => [:index, :show]}, :public => true
    map.permission :comment_news, {:news => :add_comment}
  end

  map.project_module :credits do |map|
    map.permission :view_credits, {:projects => :credits, :credits => [:index,:show]}, :require => :loggedin
    map.permission :enable_disable_credits, {:credits => [:enable, :disable]}, :require => :loggedin
    map.permission :add_credits, {:credits => [:new, :create]}, :require => :loggedin
    map.permission :manage_credits, {:credits => [:destroy, :edit, :update]}, :require => :loggedin
  end

end

Redmine::MenuManager.map :application_menu do |menu|
  # Empty
end

Redmine::MenuManager.map :admin_menu do |menu|
  # Empty
end

Redmine::MenuManager.map :project_menu do |menu|
  menu.push :overview, { :controller => 'projects', :action => 'overview' }
  menu.push :dashboard, { :controller => 'projects', :action => 'dashboard' }, :caption => :label_dashboard
  menu.push :team, { :controller => 'projects', :action => 'team' },
      :if => Proc.new { |p| p.root? }
  menu.push :credits, { :controller => 'projects', :action => 'credits' },
      :if => Proc.new { |p| p.credits_enabled? }
  menu.push :boards, { :controller => 'boards', :action => 'index', :id => nil }, :param => :project_id, :caption => :label_boards
  menu.push :wiki, { :controller => 'wiki', :action => 'index', :page => nil }
  menu.push :documents, { :controller => 'documents', :action => 'index' }, :param => :project_id, :caption => :label_document_plural
  menu.push :news, { :controller => 'news', :action => 'index' }, :param => :project_id, :caption => :label_news_plural
  menu.push :settings, { :controller => 'projects', :action => 'settings' }, :last => true
end

Redmine::Activity.map do |activity|
  activity.register :issues, :class_name => %w(Issue Journal)
  activity.register :news
  activity.register :documents, :class_name => %w(Document Attachment)
  activity.register :wiki_edits, :class_name => 'WikiContent::Version', :default => true
  activity.register :messages, :default => true
end

Redmine::WikiFormatting.map do |format|
  format.register :textile, Redmine::WikiFormatting::Textile::Formatter, Redmine::WikiFormatting::Textile::Helper
end
