module RedmineGitHosting
  module Config
    module Base
      extend self

      ###############################
      ##                           ##
      ##  CONFIGURATION ACCESSORS  ##
      ##                           ##
      ###############################


      def logger
        RedmineGitHosting.logger
      end


      def get_setting(setting, bool = false)
        if bool
          return_bool do_get_setting(setting)
        else
          return do_get_setting(setting)
        end
      end


      def reload_from_file!
        ## Get default config from init.rb
        default_hash = Redmine::Plugin.find('redmine_git_hosting').settings[:default]
        do_reload_config(default_hash)
      end


      private


        def return_bool(value)
          value == 'true' ? true : false
        end


        def do_get_setting(setting)
          setting = setting.to_sym

          ## Wrap this in a begin/rescue statement because Setting table
          ## may not exist on first migration
          begin
            value = Setting.plugin_redmine_git_hosting[setting]
          rescue => e
            value = Redmine::Plugin.find('redmine_git_hosting').settings[:default][setting]
          else
            ## The Setting table exist but does not contain the value yet, fallback to default
            value = Redmine::Plugin.find('redmine_git_hosting').settings[:default][setting] if value.nil?
          end

          value
        end


        def do_reload_config(default_hash)
          ## Refresh Settings cache
          Setting.check_cache

          ## Get actual values
          valuehash = (Setting.plugin_redmine_git_hosting).clone

          ## Update!
          changes = 0

          default_hash.each do |key, value|
            if valuehash[key] != value
              logger.info("Changing '#{key}' : #{valuehash[key]} => #{value}")
              valuehash[key] = value
              changes += 1
            end
          end

          if changes == 0
            logger.info('No changes necessary.')
          else
            commit_changes(valuehash)
          end
        end


        def commit_changes(valuehash)
          logger.info('Committing changes ... ')
          begin
            ## Update Settings
            Setting.plugin_redmine_git_hosting = valuehash
            ## Refresh Settings cache
            Setting.check_cache
            logger.info('Success!')
          rescue => e
            logger.error('Failure.')
            logger.error(e.message)
          end
        end


        def logger
          RedmineGitHosting::ConsoleLogger
        end

    end
  end
end
