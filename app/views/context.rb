# auto_register: false
# frozen_string_literal: true

require "foxtail-runtime"
require "rack/icu4x/locale"
require "rack/protection"

module PastaAtlas
  module Views
    class Context < Hanami::View::Context
      include Deps["repos.user_preference_repo", "repos.user_profile_repo", "repos.user_repo", "routes", "settings"]

      def initialize(i18n: nil, **args)
        super(**args)
        @i18n = i18n
      end

      attr_reader :i18n

      def flash_notice = request.flash[:notice]
      def flash_error = request.flash[:error]

      def path(...) = routes.path(...)
      def url(...) = routes.url(...)

      def locale_tag = locale.to_s

      def locale_name(locale_code)
        target = ICU4X::DisplayNames.new(ICU4X::Locale.parse(locale_code.to_s), type: :locale).of(locale_code.to_s)
        current = ICU4X::DisplayNames.new(locale, type: :locale).of(locale_code.to_s)
        target == current ? target : "#{target} (#{current})"
      end

      def localize_datetime(time)
        viewer_relative_timestamps ? localize_relative_datetime(time) : localize_absolute_datetime(time)
      end

      def localize_absolute_datetime(time)
        Foxtail::Function::DateTime[time.utc, {timeZone: viewer_timezone, dateStyle: :medium, timeStyle: :short}]
      end

      def localize_relative_datetime(time)
        formatter = ICU4X::RelativeTimeFormat.new(locale, style: :long, numeric: :auto)
        diff = Integer(Time.now.utc - time.utc)
        abs = diff.abs
        unit =
          if abs < 60 then :second
          elsif abs < 3600 then :minute
          elsif abs < 86_400 then :hour
          elsif abs < 7 * 86_400 then :day
          elsif abs < 30 * 86_400 then :week
          elsif abs < 365 * 86_400 then :month
          else :year
          end
        divisor = {second: 1, minute: 60, hour: 3600, day: 86_400, week: 7 * 86_400, month: 30 * 86_400, year: 365 * 86_400}[unit]
        formatter.format(-(diff / divisor), unit)
      end

      def t(key, **args)
        return key.to_s unless i18n

        id, attr = key.to_s.split(".", 2)
        attr ? i18n.format_attribute(id, attr, **args) : i18n.format(id, **args)
      end

      def current_user_name
        user_id = session[:user_id]
        return nil unless user_id

        user_repo.find_by_id(user_id).name
      rescue ROM::TupleCountMismatchError
        nil
      end

      def current_user_display_name
        user_id = session[:user_id]
        return nil unless user_id

        profile = user_profile_repo.find_by_user_id(user_id)
        profile.display_name || user_repo.find_by_id(user_id).name
      rescue ROM::TupleCountMismatchError
        nil
      end

      def current_avatar_url
        user_id = session[:user_id]
        return nil unless user_id

        profile = user_profile_repo.find_by_user_id(user_id)
        return nil unless profile.avatar_s3_key

        "#{settings.cloudfront_base_url}/#{profile.avatar_s3_key}"
      rescue ROM::TupleCountMismatchError
        nil
      end

      def omniauth_authenticity_token
        Rack::Protection::AuthenticityToken.token(session)
      end

      def viewer_relative_timestamps = viewer_preference&.relative_timestamps || false

      private def locale = request.env[Rack::ICU4X::Locale::ENV_KEY].first

      private def viewer_preference
        @viewer_preference ||= begin
          user_id = session[:user_id] || user_repo.find_by_name("guest").id
          user_preference_repo.find_by_user_id(user_id)
        rescue ROM::TupleCountMismatchError
          nil
        end
      end

      private def viewer_timezone = viewer_preference&.timezone || "UTC"
    end
  end
end
