# frozen_string_literal: true

require "net/http"
require "ulid"

module PastaAtlas
  module Operations
    module Registrations
      class ImportAvatar < PastaAtlas::Operation
        include Deps["settings", s3_client: "s3.client"]

        CONTENT_TYPE_TO_EXT = {
          "image/jpeg" => "jpg",
          "image/png" => "png",
          "image/webp" => "webp"
        }.freeze
        private_constant :CONTENT_TYPE_TO_EXT

        MAX_REDIRECTS = 5
        private_constant :MAX_REDIRECTS

        MAX_RESPONSE_SIZE = 5 * 1024 * 1024
        private_constant :MAX_RESPONSE_SIZE

        ALLOWED_HOSTS = %w[
          avatars.githubusercontent.com
          cdn.discordapp.com
          media.discordapp.net
          avatars.steamstatic.com
          avatars.akamai.steamstatic.com
        ].freeze
        private_constant :ALLOWED_HOSTS

        def call(user:, avatar_url:)
          step check_url(avatar_url)
          body, content_type = step download(avatar_url)
          ext = step resolve_ext(content_type)
          key = "#{user.name}/avatar/#{ULID.generate}.#{ext}"
          step upload(key:, body:, content_type:)
          key
        end

        private def check_url(url)
          return Failure(:no_url) if url.nil? || url.empty?

          uri = URI(url)
          return Failure(:fetch_failed) unless uri.scheme == "https"
          return Failure(:fetch_failed) unless ALLOWED_HOSTS.include?(uri.host)

          Success()
        end

        private def download(url)
          body, content_type = fetch(url)
          body ? Success([body, content_type]) : Failure(:fetch_failed)
        rescue
          Failure(:fetch_failed)
        end

        private def resolve_ext(content_type)
          ext = CONTENT_TYPE_TO_EXT[content_type]
          ext ? Success(ext) : Failure(:unsupported_type)
        end

        private def upload(key:, body:, content_type:)
          s3_client.put_object(bucket: settings.s3_bucket, key:, body:, content_type:)
          Success()
        rescue Aws::S3::Errors::ServiceError
          Failure(:upload_failed)
        end

        private def fetch(url, redirect_count=0)
          return nil if redirect_count > MAX_REDIRECTS

          uri = URI(url)
          return nil unless uri.scheme == "https"
          return nil unless ALLOWED_HOSTS.include?(uri.host)

          response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 10) {|http|
            http.get(uri.request_uri)
          }

          return fetch(response["Location"], redirect_count + 1) if response.is_a?(Net::HTTPRedirection)
          return nil unless response.is_a?(Net::HTTPSuccess)

          content_length = Integer(response["Content-Length"], 10) if response["Content-Length"]
          return nil if content_length && content_length > MAX_RESPONSE_SIZE

          body = response.body
          return nil if body.bytesize > MAX_RESPONSE_SIZE

          raw = response["Content-Type"]&.split(";")&.first
          content_type = raw&.strip
          [body, content_type]
        end
      end
    end
  end
end
