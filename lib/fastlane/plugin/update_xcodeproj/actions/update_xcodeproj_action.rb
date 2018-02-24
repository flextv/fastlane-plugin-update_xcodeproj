# frozen_string_literal: true

module Fastlane
  module Actions
    class UpdateXcodeprojAction < Action
      def self.run(params)
        require 'xcodeproj'

        options = params[:options]
        project_path = params[:xcodeproj]
        project = Xcodeproj::Project.open(project_path)
        target_filter = params[:target_filter]

        project.targets.each do |target|
          if !target_filter || target.name.match(target_filter) || (target.respond_to?(:product_type) && target.product_type.match(target_filter))
            UI.success("Updating target #{target.name}...")
          else
            UI.important("Skipping target #{target.name} as it doesn't match the filter '#{target_filter}'")
            next
          end

          options.each do |key, value|
            configs = target.build_configuration_list.build_configurations.select { |obj| !obj.build_settings[key.to_s].nil? }
            UI.important("Skipping target #{target} as it does not use #{key}") if configs.count.zero?

            configs.each do |c|
              c.build_settings[key.to_s] = value
            end
          end
        end

        project.save

        UI.success("Updated #{params[:xcodeproj]} 💾.")
      end

      def self.description
        "Update Xcode projects"
      end

      def self.authors
        ["Fumiya Nakamura"]
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :xcodeproj,
                                       env_name: "UPDATE_XCODEPROJ_XCODEPROJ",
                                       description: "Path to your Xcode project",
                                       optional: true,
                                       default_value: Dir['*.xcodeproj'].first,
                                       type: String,
                                       verify_block: proc do |value|
                                         UI.user_error!("Please pass the path to the project, not the workspace") unless value.end_with?(".xcodeproj")
                                         UI.user_error!("Could not find Xcode project") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :target_filter,
                                       env_name: "UPDATE_XCODEPROJ_TARGET_FILTER",
                                       description: "A filter for the target name. Use a standard regex",
                                       optional: true,
                                       is_string: false,
                                       verify_block: proc do |value|
                                         UI.user_error!("target_filter should be Regexp or String") unless [Regexp, String].any? { |type| value.kind_of?(type) }
                                       end),
          FastlaneCore::ConfigItem.new(key: :options,
                                       env_name: "UPDATE_XCODEPROJ_OPTIONS",
                                       description: "Key & Value pair that you will update xcode project",
                                       optional: false,
                                       type: Hash)
        ]
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end
    end
  end
end
