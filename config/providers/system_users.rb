# frozen_string_literal: true

Hanami.app.register_provider(:system_users, namespace: true) do
  start do
    names = %w[guest api admin compilatron].freeze
    register "names", names

    repo = target["repos.user_repo"]
    names.each do |name|
      user = repo.find_by_name(name)
      register name, user if user
    end
  end
end
