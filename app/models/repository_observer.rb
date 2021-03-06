class RepositoryObserver < ActiveRecord::Observer

    def before_destroy(repository)
        if repository.created_with_scm
            project = repository.project

            type = repository.class.name.demodulize

            begin
                interface = Object.const_get("#{type}Creator")

                name = interface.repository_name(repository.root_url)
                if name
                    path = interface.default_path(name) # FIXME: Removing should not depend on current settings.
                                                        #        If the repo was created with different path and git_ext it should still delete.

                    interface.execute(ScmConfig['pre_delete'], path, project) if ScmConfig['pre_delete']

                    # See: http://www.ruby-doc.org/stdlib-1.9.3/libdoc/fileutils/rdoc/FileUtils.html#method-c-remove_entry_secure
                    FileUtils.remove_entry_secure(path, true)

                    interface.execute(ScmConfig['post_delete'], path, project) if ScmConfig['post_delete']

                end
            rescue NameError
            end

        end
    end

end
