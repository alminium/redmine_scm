class ScmHook  < Redmine::Hook::ViewListener

    def view_projects_form(context = {})
        if context[:project].new_record? && ScmConfig['auto_create']
            count = %w(svn git mercurial bazaar).inject(0) do |sum, scm|
                sum += 1 if ScmConfig[scm]
                sum
            end
            if (count > 1) || (ScmConfig['auto_create'] != 'force')
                row = ''
                row << label_tag('project[scm]', l(:field_scm) + (ScmConfig['auto_create'] == 'force' ? ' ' + content_tag(:span, '*', :class => 'required') : ''))
                row << select_tag('project[scm]', project_scm_options_for_select(context[:request].params[:project] ? context[:request].params[:project][:scm] : nil))
                row << '<br />' + content_tag(:em, l(:text_cannot_be_changed_later)) if ScmConfig['auto_create'] == 'force'
                content_tag(:p, row)
            else
                if ScmConfig['svn']
                    hidden_field_tag('project[scm]', 'Subversion')
                elsif ScmConfig['git']
                    hidden_field_tag('project[scm]', 'Git')
                elsif ScmConfig['mercurial']
                    hidden_field_tag('project[scm]', 'Mercurial')
                elsif ScmConfig['bazaar']
                    hidden_field_tag('project[scm]', 'Bazaar')
                end
            end
        end
    end

    def controller_project_aliases_rename_after(context = {})
        if context[:project].repository && context[:project].repository.created_with_scm
            begin
                interface = Object.const_get("#{context[:project].repository.type}Creator")

                name = interface.repository_name(context[:project].repository.url)
                if name && interface.repository_name_equal?(name, context[:old_identifier])
                    old_path = interface.path(name)
                    if File.directory?(old_path)
                        new_path = interface.default_path(context[:new_identifier])
                        File.rename(old_path, new_path)

                        url = interface.command_line_path(new_path)
                        context[:project].repository.update_attributes(:root_url => url, :url => url)
                    end
                end
            rescue NameError
            end
        end
    end

private

    def project_scm_options_for_select(selected = nil)
        options = []
        options << [ '' ]           if ScmConfig['auto_create'] != 'force'
        options << [ 'Subversion' ] if ScmConfig['svn']
        options << [ 'Mercurial' ]  if ScmConfig['mercurial']
        options << [ 'Bazaar' ]     if ScmConfig['bazaar']
        options << [ 'Git' ]        if ScmConfig['git']
        options_for_select(options, selected)
    end

end
