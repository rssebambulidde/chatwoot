release: POSTGRES_STATEMENT_TIMEOUT=600s bundle exec rails db:chatwoot_prepare && bundle exec rails branding:apply && echo $SOURCE_VERSION > .git_sha
web: POSTGRES_STATEMENT_TIMEOUT=600s bundle exec rails db:chatwoot_prepare && bundle exec rails branding:apply && bundle exec rails ip_lookup:setup && bin/rails server -p $PORT -e $RAILS_ENV
worker: bundle exec rails ip_lookup:setup && bundle exec sidekiq -C config/sidekiq.yml
