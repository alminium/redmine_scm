class ScmHook  < Redmine::Hook::ViewListener

    render_on :view_projects_form, :partial => 'scm/project'

end
