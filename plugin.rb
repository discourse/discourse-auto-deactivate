# name: discourse-auto-deactivate
# about: Automatically deactivates inactive users so that they need to recomfirm their email in order to login in again
# version: 0.0.1
# authors: David Taylor, Blake Erickson
# url: https://github.com/discourse/discourse-auto-deactivate

enabled_site_setting :auto_deactivate_enabled

PLUGIN_NAME ||= 'discourse_auto_deactivate'.freeze

after_initialize do
  module ::DiscourseAutoDeactivate
    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace DiscourseAutoDeactivate
    end
  end

  module ::Jobs
    class AutoDeactivateUsers < Jobs::Scheduled
      every 1.day

      def self.to_deactivate
        auto_deactivate_days = SiteSetting.auto_deactivate_after_days.days.ago
        to_deactivate = User.where("(last_seen_at IS NULL OR last_seen_at < ?) AND created_at < ?", auto_deactivate_days, auto_deactivate_days)
          .where('active = ?', true)
          .real
      end

      def self.exclude_users_in_safe_groups(deactivate_list)
        safe_groups = SiteSetting.auto_deactivate_safe_groups
        safe_to_deactivate = []
        for user in deactivate_list do
          safe_to_deactivate << user if !(user.groups.any? { |g| safe_groups.include? g.name })
        end
        safe_to_deactivate
      end

      def execute(args)
        return if !SiteSetting.auto_deactivate_enabled?

        deactivate_list = self.class.to_deactivate
        safe_to_deactivate = self.class.exclude_users_in_safe_groups(deactivate_list)

        for user in safe_to_deactivate do
          user.active = false
          deactivate_reason = I18n.t("discourse_auto_deactivate.deactivate_reason", count: SiteSetting.auto_deactivate_after_days)

          if user.save
            StaffActionLogger.new(Discourse.system_user).log_user_deactivate(user, deactivate_reason)
          end
        end
      end

    end
  end

end
